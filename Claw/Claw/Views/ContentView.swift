import SwiftUI

enum AppTab: Int {
    case chat, notifications, status, dev
}

struct ContentView: View {
    @EnvironmentObject var notificationsViewModel: NotificationsViewModel
    @State private var selectedTab: AppTab = .chat

    var body: some View {
        TabView(selection: $selectedTab) {
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }
                .tag(AppTab.chat)

            NotificationsListView()
                .tabItem {
                    Label("Notifications", systemImage: "bell.fill")
                }
                .badge(notificationsViewModel.unreadCount)
                .tag(AppTab.notifications)

            StatusView()
                .tabItem {
                    Label("Status", systemImage: "antenna.radiowaves.left.and.right")
                }
                .tag(AppTab.status)

            DevView()
                .tabItem {
                    Label("Dev", systemImage: "terminal")
                }
                .tag(AppTab.dev)
        }
        .tint(ClawTheme.accent)
        .preferredColorScheme(.dark)
        .onReceive(NotificationCenter.default.publisher(for: .didReceiveClawNotification)) { notification in
            let userInfo = notification.userInfo ?? [:]
            let type = userInfo["type"] as? String
            if type == "notification" {
                selectedTab = .notifications
                if let notifId = userInfo["notificationId"] as? String {
                    notificationsViewModel.pendingDeepLink = notifId
                }
            }
            Task { await notificationsViewModel.fetchNotifications() }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationManager())
        .environmentObject(ChatViewModel())
        .environmentObject(NotificationsViewModel())
}
