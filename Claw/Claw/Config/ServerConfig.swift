import Foundation

struct ServerConfig {
    // MARK: - Server URL

    private static let bundleBaseURL = Bundle.main.object(forInfoDictionaryKey: "ClawServerURL") as? String ?? ""
    private static let bundleAPIToken = Bundle.main.object(forInfoDictionaryKey: "ClawAPIToken") as? String ?? ""

    static var baseURL: URL {
        // Settings app override > xcconfig > fallback
        if let urlString = UserDefaults.standard.string(forKey: "server_url"),
           !urlString.isEmpty,
           let url = URL(string: urlString) {
            return url
        }
        if !bundleBaseURL.isEmpty, let url = URL(string: bundleBaseURL) {
            return url
        }
        return URL(string: "http://localhost:3001")!
    }

    // MARK: - API Token

    static var apiToken: String {
        // Settings app override > xcconfig > empty
        if let token = UserDefaults.standard.string(forKey: "api_token"),
           !token.isEmpty {
            return token
        }
        if !bundleAPIToken.isEmpty {
            return bundleAPIToken
        }
        return ""
    }

    // MARK: - Endpoints

    static var locationURL: URL { baseURL.appending(path: "api/location") }
    static var deviceTokenURL: URL { baseURL.appending(path: "api/device-token") }
    static var commandURL: URL { baseURL.appending(path: "api/command") }
    static var statusURL: URL { baseURL.appending(path: "api/status") }
    static var locationRequestURL: URL { baseURL.appending(path: "api/location/request") }
    static var notificationsURL: URL { baseURL.appending(path: "api/notifications") }
    static func notificationURL(id: String) -> URL { baseURL.appending(path: "api/notifications/\(id)") }
    static var ttsURL: URL { baseURL.appending(path: "api/tts") }
    static var logsURL: URL { baseURL.appending(path: "api/logs") }
    static var statsURL: URL { baseURL.appending(path: "api/stats") }
    static var chatsURL: URL { baseURL.appending(path: "api/chats") }

    /// How often (seconds) the app polls the server for location requests.
    static let locationRequestPollInterval: TimeInterval = 10.0

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
