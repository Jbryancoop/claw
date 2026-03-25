import Foundation

struct ServerConfig {
    // MARK: - Server URL

    static var baseURL: URL {
        if let urlString = UserDefaults.standard.string(forKey: "server_url"),
           !urlString.isEmpty,
           let url = URL(string: urlString) {
            return url
        }
        // Fallback for development — change to your server's address
        return URL(string: "http://localhost:8080")!
    }

    // MARK: - API Token

    static var apiToken: String {
        if let token = UserDefaults.standard.string(forKey: "api_token"),
           !token.isEmpty {
            return token
        }
        return ""
    }

    // MARK: - Endpoints

    static var locationURL: URL { baseURL.appendingPathComponent("/api/location") }
    static var deviceTokenURL: URL { baseURL.appendingPathComponent("/api/device-token") }
    static var commandURL: URL { baseURL.appendingPathComponent("/api/command") }
    static var statusURL: URL { baseURL.appendingPathComponent("/api/status") }

    // MARK: - Location Settings

    /// Minimum distance (meters) between location updates sent to the server.
    /// Higher values save battery. 100m is a good default for personal tracking.
    static let locationDistanceFilter: Double = 100.0

    /// How often (seconds) to send location when app is foregrounded and user is moving.
    /// This throttles network calls, not GPS readings.
    static let foregroundUpdateInterval: TimeInterval = 30.0

    /// Use significant location changes only when backgrounded (major battery savings).
    /// When true, the app only wakes for cell tower / Wi-Fi transitions (~500m moves).
    static let useSignificantChangesInBackground: Bool = true
}
