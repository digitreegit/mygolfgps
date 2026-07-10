import Foundation

public enum CourseAPIError: Error, LocalizedError {
    case invalidURL
    case httpError(Int)
    case serverError(String)
    case decodingFailed

    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .httpError(let code): return "HTTP \(code)"
        case .serverError(let msg): return msg
        case .decodingFailed: return "Failed to decode response"
        }
    }
}

public struct CourseAPIClient: Sendable {
    public let baseURL: URL
    private let session: URLSession

    public init(baseURL: URL, session: URLSession? = nil) {
        self.baseURL = baseURL
        if let session {
            self.session = session
        } else {
            let config = URLSessionConfiguration.default
            config.timeoutIntervalForRequest = 90
            config.timeoutIntervalForResource = 120
            self.session = URLSession(configuration: config)
        }
    }

    public func searchCourses(
        query: String?,
        lat: Double,
        lon: Double,
        radiusKm: Int = 15
    ) async throws -> [CourseSearchResult] {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("api/courses/search"),
            resolvingAgainstBaseURL: false
        )!
        var items = [
            URLQueryItem(name: "lat", value: String(lat)),
            URLQueryItem(name: "lon", value: String(lon)),
            URLQueryItem(name: "radiusKm", value: String(radiusKm)),
        ]
        if let query, !query.isEmpty {
            items.append(URLQueryItem(name: "q", value: query))
        }
        components.queryItems = items

        guard let url = components.url else { throw CourseAPIError.invalidURL }
        let (data, response) = try await session.data(from: url)
        try validate(response: response, data: data)

        guard let decoded = try? JSONDecoder().decode(CourseSearchResponse.self, from: data) else {
            throw CourseAPIError.decodingFailed
        }
        return decoded.courses
    }

    public func downloadCourse(
        result: CourseSearchResult,
        playerLat: Double?,
        playerLon: Double?
    ) async throws -> CourseData {
        var components = URLComponents(
            url: baseURL
                .appendingPathComponent("api/courses")
                .appendingPathComponent(result.osmType)
                .appendingPathComponent(String(result.osmId)),
            resolvingAgainstBaseURL: false
        )!
        var items = [URLQueryItem(name: "name", value: result.name)]
        if let playerLat, let playerLon {
            items.append(URLQueryItem(name: "lat", value: String(playerLat)))
            items.append(URLQueryItem(name: "lon", value: String(playerLon)))
        }
        components.queryItems = items

        guard let url = components.url else { throw CourseAPIError.invalidURL }
        let (data, response) = try await session.data(from: url)
        try validate(response: response, data: data)

        guard let course = try? JSONDecoder().decode(CourseData.self, from: data) else {
            throw CourseAPIError.decodingFailed
        }
        return course
    }

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else {
            throw CourseAPIError.serverError("Invalid response")
        }
        guard (200...299).contains(http.statusCode) else {
            if let err = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw CourseAPIError.serverError(err.error)
            }
            throw CourseAPIError.httpError(http.statusCode)
        }
    }
}
