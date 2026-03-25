import Foundation

struct LogEntry: Identifiable, Codable {
    let id: Int?
    let message: String
    let data: String?
    let timestamp: String

    var stableId: String { "\(id ?? 0)-\(timestamp)" }
}

struct LogsResponse: Decodable {
    let ok: Bool
    let data: [LogEntry]?
    let total: Int?
    let error: String?
}

struct ServerStats: Codable {
    let notifications: Int?
    let notificationsUnread: Int?
    let chats: Int?
    let locations: Int?
    let logs: Int?
    let deviceTokens: Int?
    let uptime: Double?
    let dbSizeBytes: Int?
    let lastLocationAt: String?
    let lastChatAt: String?

    enum CodingKeys: String, CodingKey {
        case notifications, chats, locations, logs, uptime
        case notificationsUnread = "notifications_unread"
        case deviceTokens = "device_tokens"
        case dbSizeBytes = "db_size_bytes"
        case lastLocationAt = "last_location_at"
        case lastChatAt = "last_chat_at"
    }
}

struct StatsResponse: Decodable {
    let ok: Bool
    let data: ServerStats?
    let error: String?
}

struct ChatEntry: Identifiable, Codable {
    let id: String
    let role: String
    let content: String
    let timestamp: String
    let locationLat: Double?
    let locationLon: Double?

    enum CodingKeys: String, CodingKey {
        case id, role, content, timestamp
        case locationLat = "location_lat"
        case locationLon = "location_lon"
    }
}

struct ChatsResponse: Decodable {
    let ok: Bool
    let data: [ChatEntry]?
    let error: String?
}
