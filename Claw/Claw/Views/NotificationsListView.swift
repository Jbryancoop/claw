import SwiftUI

struct NotificationsListView: View {
    @EnvironmentObject var viewModel: NotificationsViewModel
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if viewModel.notifications.isEmpty {
                    ContentUnavailableView(
                        "No Notifications",
                        systemImage: "bell.slash",
                        description: Text("Notifications from the server will appear here.")
                            .foregroundStyle(ClawTheme.textSecondary)
                    )
                    .foregroundStyle(ClawTheme.textSecondary)
                    .background(ClawTheme.background)
                } else {
                    List {
                        ForEach(viewModel.notifications) { item in
                            NavigationLink(value: item.id) {
                                NotificationRowView(item: item)
                            }
                            .listRowBackground(ClawTheme.surface)
                            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    viewModel.delete(item.id)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(ClawTheme.destructive)
                            }
                            .swipeActions(edge: .trailing) {
                                Button {
                                    if item.isRead {
                                        viewModel.markUnread(item.id)
                                    } else {
                                        viewModel.markRead(item.id)
                                    }
                                } label: {
                                    Label(
                                        item.isRead ? "Unread" : "Read",
                                        systemImage: item.isRead ? "envelope.badge" : "envelope.open"
                                    )
                                }
                                .tint(ClawTheme.accent)
                            }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .background(ClawTheme.background)
                    .navigationDestination(for: String.self) { id in
                        if let item = viewModel.notifications.first(where: { $0.id == id }) {
                            NotificationDetailView(item: item)
                        }
                    }
                }
            }
            .navigationTitle("Notifications")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !viewModel.notifications.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("Mark All Read") {
                                viewModel.markAllRead()
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .refreshable {
                await viewModel.fetchNotifications()
            }
            .onChange(of: viewModel.pendingDeepLink) { _, newValue in
                if let id = newValue {
                    navigationPath.append(id)
                    viewModel.pendingDeepLink = nil
                }
            }
        }
    }
}

// MARK: - Row

private struct NotificationRowView: View {
    let item: NotificationItem

    var body: some View {
        HStack(spacing: 10) {
            Circle()
                .fill(item.isRead ? .clear : ClawTheme.unread)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .fontWeight(item.isRead ? .regular : .semibold)
                    .foregroundStyle(ClawTheme.textPrimary)
                    .lineLimit(1)

                Text(markdownPlainText(item.body))
                    .font(.subheadline)
                    .foregroundStyle(ClawTheme.textSecondary)
                    .lineLimit(2)

                Text(item.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundStyle(ClawTheme.textTertiary)
            }
        }
        .padding(.vertical, 2)
    }
}
