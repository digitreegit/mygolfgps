import Foundation
import CoreLocation

public struct DistanceEngine: Sendable {
    public init() {}

    private static let metersToYards = 1.09361

    public func distanceYards(from: GpsPoint, to: GpsPoint) -> Int {
        let meters = CLLocation(latitude: from.lat, longitude: from.lon)
            .distance(from: CLLocation(latitude: to.lat, longitude: to.lon))
        return Int((meters * Self.metersToYards).rounded())
    }

    public func distanceYards(from: GpsPoint, to hole: HoleData) -> Int? {
        guard let green = hole.greenCenter else { return nil }
        return distanceYards(from: from, to: green)
    }
}
