import Foundation
import CoreLocation
import WatchConnectivity
import MyGolfGPSCore

@MainActor
final class PhoneSession: NSObject, ObservableObject {
    @Published var searchResults: [CourseSearchResult] = []
    @Published var selectedCourse: CourseData?
    @Published var isSearching = false
    @Published var isDownloading = false
    @Published var errorMessage: String?
    @Published var location: GpsPoint?

    private let api: CourseAPIClient
    private let locationManager = CLLocationManager()

    override init() {
        #if DEBUG
        api = CourseAPIClient(baseURL: URL(string: "http://localhost:3000")!)
        #else
        api = CourseAPIClient(baseURL: URL(string: "https://mygolfgps.vercel.app")!)
        #endif
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        activateWatchConnectivity()
    }

    func requestLocation() {
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }

    func search(query: String) async {
        guard let location else {
            errorMessage = "Location required for search"
            return
        }
        isSearching = true
        errorMessage = nil
        defer { isSearching = false }

        do {
            searchResults = try await api.searchCourses(
                query: query.isEmpty ? nil : query,
                lat: location.lat,
                lon: location.lon
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func download(_ result: CourseSearchResult) async {
        isDownloading = true
        errorMessage = nil
        defer { isDownloading = false }

        do {
            let course = try await api.downloadCourse(
                result: result,
                playerLat: location?.lat,
                playerLon: location?.lon
            )
            selectedCourse = course
            sendCourseToWatch(course)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func startRoundOnWatch() {
        guard let course = selectedCourse else { return }
        sendCourseToWatch(course)
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(["action": "startRound"], replyHandler: nil)
        }
    }

    private func sendCourseToWatch(_ course: CourseData) {
        guard WCSession.default.activationState == .activated else { return }
        guard let data = try? JSONEncoder().encode(course) else { return }
        WCSession.default.transferUserInfo(["course": data])
    }

    private func activateWatchConnectivity() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }
}

extension PhoneSession: CLLocationManagerDelegate {
    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let loc = locations.last else { return }
        Task { @MainActor in
            self.location = GpsPoint(lat: loc.coordinate.latitude, lon: loc.coordinate.longitude)
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.errorMessage = error.localizedDescription
        }
    }
}

extension PhoneSession: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
}
