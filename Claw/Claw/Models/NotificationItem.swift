import Foundation

struct NotificationItem: Identifiable, Codable, Equatable {
    let id: String
    let title: String
    let body: String
    let timestamp: Date
    var isRead: Bool

    enum CodingKeys: String, CodingKey {
        case id, title, body, timestamp
        case isRead = "is_read"
    }
}

struct NotificationsResponse: Decodable {
    let ok: Bool
    let data: [NotificationItem]?
    let error: String?
}
