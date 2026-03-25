import SwiftUI

struct NotificationDetailView: View {
    @EnvironmentObject var viewModel: NotificationsViewModel
    let item: NotificationItem

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(item.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(ClawTheme.textPrimary)

                HStack {
                    Text(item.timestamp, style: .date)
                    Text("at")
                    Text(item.timestamp, style: .time)
                }
                .font(.caption)
                .foregroundStyle(ClawTheme.textSecondary)

                Divider()
                    .overlay(ClawTheme.border)

                MarkdownView(item.body)
                    .foregroundStyle(ClawTheme.textPrimary)
                    .textSelection(.enabled)
            }
            .padding()
        }
        .background(ClawTheme.background)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        if item.isRead {
                            viewModel.markUnread(item.id)
                        } else {
                            viewModel.markRead(item.id)
                        }
                    } label: {
                        Label(
                            item.isRead ? "Mark Unread" : "Mark Read",
                            systemImage: item.isRead ? "envelope.badge" : "envelope.open"
                        )
                    }

                    Button(role: .destructive) {
                        viewModel.delete(item.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            viewModel.markRead(item.id)
        }
    }
}
