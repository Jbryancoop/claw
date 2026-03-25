import Foundation
import UserNotifications

final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var isAuthorized: Bool = false
    @Published var deviceTokenHex: String?
    @Published var isTokenRegistered: Bool = false
    @Published var lastError: String?

    private init() {
        checkAuthorizationStatus()
    }

    // MARK: - Authorization

    func requestAuthorization() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .badge, .sound]
        ) { [weak self] granted, error in
            DispatchQueue.main.async {
                self?.isAuthorized = granted
                if let error = error {
                    self?.lastError = error.localizedDescription
                }
            }
        }
    }

    private func checkAuthorizationStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Token Registration

    func registerToken(_ deviceToken: Data) {
        let hex = deviceToken.map { String(format: "%02x", $0) }.joined()
        DispatchQueue.main.async {
            self.deviceTokenHex = hex
        }

        Task {
            do {
                let _: ServerResponse = try await APIClient.shared.registerDeviceToken(hex)
                await MainActor.run {
                    self.isTokenRegistered = true
                    self.lastError = nil
                }
            } catch {
                await MainActor.run {
                    self.isTokenRegistered = false
                    self.lastError = error.localizedDescription
                }
            }
        }
    }
}
