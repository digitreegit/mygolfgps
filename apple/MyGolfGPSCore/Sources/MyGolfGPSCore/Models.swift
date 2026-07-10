import Foundation

public struct GpsPoint: Codable, Sendable, Hashable {
    public var lat: Double
    public var lon: Double

    public init(lat: Double, lon: Double) {
        self.lat = lat
        self.lon = lon
    }
}

public struct HoleData: Codable, Sendable, Identifiable {
    public var id: Int { number }
    public var number: Int
    public var greenCenter: GpsPoint?
    public var hasGreen: Bool

    public init(number: Int, greenCenter: GpsPoint?, hasGreen: Bool) {
        self.number = number
        self.greenCenter = greenCenter
        self.hasGreen = hasGreen
    }

    private enum CodingKeys: String, CodingKey {
        case number, greenCenter, hasGreen
    }
}

public struct CourseData: Codable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var location: GpsPoint
    public var holes: [HoleData]
    public var mappedHoleCount: Int
    public var totalHoles: Int
    public var downloadedAt: String

    public init(
        id: String,
        name: String,
        location: GpsPoint,
        holes: [HoleData],
        mappedHoleCount: Int,
        totalHoles: Int,
        downloadedAt: String
    ) {
        self.id = id
        self.name = name
        self.location = location
        self.holes = holes
        self.mappedHoleCount = mappedHoleCount
        self.totalHoles = totalHoles
        self.downloadedAt = downloadedAt
    }
}

public struct CourseSearchResult: Codable, Sendable, Identifiable {
    public var id: String
    public var name: String
    public var location: GpsPoint
    public var osmType: String
    public var osmId: Int
    public var distanceMeters: Double?

    public init(
        id: String,
        name: String,
        location: GpsPoint,
        osmType: String,
        osmId: Int,
        distanceMeters: Double? = nil
    ) {
        self.id = id
        self.name = name
        self.location = location
        self.osmType = osmType
        self.osmId = osmId
        self.distanceMeters = distanceMeters
    }
}

public struct CourseSearchResponse: Codable, Sendable {
    public var courses: [CourseSearchResult]
}

public struct APIErrorResponse: Codable, Sendable {
    public var error: String
}
