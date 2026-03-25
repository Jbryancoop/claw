import Foundation

extension Notification.Name {
    static let didReceiveClawNotification = Notification.Name("didReceiveClawNotification")
}

@MainActor
final class NotificationsViewModel: ObservableObject {
    @Published var notifications: [NotificationItem] = [] {
        didSet { saveLocal() }
    }
    @Published var isLoading: Bool = false
    @Published var pendingDeepLink: String?

    var unreadCount: Int {
        notifications.filter { !$0.isRead }.count
    }

    private static let storageKey = "notifications_cache"

    init() {
        loadLocal()
        NotificationCenter.default.addObserver(
            forName: .didReceiveClawNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                await self?.fetchNotifications()
            }
        }
    }

    func fetchNotifications() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await APIClient.shared.fetchNotifications()
            if let items = response.data {
                // Merge: keep local read states for items that exist on server
                let localReadStates = Dictionary(uniqueKeysWithValues: notifications.map { ($0.id, $0.isRead) })
                notifications = items.map { item in
                    var merged = item
                    if let localRead = localReadStates[item.id] {
                        merged.isRead = localRead || item.isRead
                    }
                    return merged
                }
            }
        } catch {
            // Keep local cache on failure
        }
    }

    func markRead(_ id: String) {
        guard let idx = notifications.firstIndex(where: { $0.id == id }) else { return }
        notifications[idx].isRead = true
        Task {
            let _ = try? await APIClient.shared.updateNotificationRead(id: id, isRead: true)
        }
    }

    func markUnread(_ id: String) {
        guard let idx = notifications.firstIndex(where: { $0.id == id }) else { return }
        notifications[idx].isRead = false
        Task {
            let _ = try? await APIClient.shared.updateNotificationRead(id: id, isRead: false)
        }
    }

    func delete(_ id: String) {
        notifications.removeAll { $0.id == id }
        Task {
            let _ = try? await APIClient.shared.deleteNotification(id: id)
        }
    }

    func markAllRead() {
        for i in notifications.indices {
            notifications[i].isRead = true
        }
        for n in notifications where !n.isRead {
            Task {
                let _ = try? await APIClient.shared.updateNotificationRead(id: n.id, isRead: true)
            }
        }
    }

    private func saveLocal() {
        guard let data = try? JSONEncoder().encode(notifications) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    private func loadLocal() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let saved = try? JSONDecoder().decode([NotificationItem].self, from: data) else { return }
        notifications = saved
    }
}
