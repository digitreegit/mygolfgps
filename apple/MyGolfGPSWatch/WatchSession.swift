import Foundation
import CoreLocation
import HealthKit
import WatchConnectivity
import MyGolfGPSCore

@MainActor
final class WatchSession: NSObject, ObservableObject {
    @Published var course: CourseData?
    @Published var currentHole = 1
    @Published var yardsToGreen: Int?
    @Published var isRoundActive = false
    @Published var locationStatus = "Waiting for GPS"

    private let locationManager = CLLocationManager()
    private let distanceEngine = DistanceEngine()
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.activityType = .fitness
        locationManager.distanceFilter = 1
        activateWatchConnectivity()
    }

    var currentHoleData: HoleData? {
        course?.holes.first { $0.number == currentHole }
    }

    func startRound() {
        isRoundActive = true
        startWorkoutSession()
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        updateDistance()
    }

    func nextHole() {
        guard currentHole < 18 else { return }
        currentHole += 1
        updateDistance()
    }

    func previousHole() {
        guard currentHole > 1 else { return }
        currentHole -= 1
        updateDistance()
    }

    private func updateDistance() {
        guard let player = lastLocation, let hole = currentHoleData else {
            yardsToGreen = nil
            return
        }
        yardsToGreen = distanceEngine.distanceYards(from: player, to: hole)
    }

    private var lastLocation: GpsPoint?

    private func startWorkoutSession() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let config = HKWorkoutConfiguration()
        config.activityType = .golf
        config.locationType = .outdoor

        do {
            let session = try HKWorkoutSession(healthStore: HKHealthStore(), configuration: config)
            let builder = session.associatedWorkoutBuilder()
            builder.dataSource = HKLiveWorkoutDataSource(
                healthStore: HKHealthStore(),
                workoutConfiguration: config
            )
            workoutSession = session
            workoutBuilder = builder
            session.startActivity(with: Date())
            builder.beginCollection(withStart: Date()) { _, _ in }
        } catch {
            locationStatus = "Workout session failed"
        }
    }

    private func activateWatchConnectivity() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }
}

extension WatchSession: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            self.lastLocation = GpsPoint(lat: loc.coordinate.latitude, lon: loc.coordinate.longitude)
            self.locationStatus = "GPS active"
            self.updateDistance()
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.locationStatus = error.localizedDescription
        }
    }
}

extension WatchSession: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}

    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        guard let data = userInfo["course"] as? Data,
              let course = try? JSONDecoder().decode(CourseData.self, from: data) else { return }
        Task { @MainActor in
            self.course = course
            self.currentHole = 1
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if message["action"] as? String == "startRound" {
            Task { @MainActor in self.startRound() }
        }
    }
}
