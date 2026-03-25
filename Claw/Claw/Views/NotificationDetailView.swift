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

                HStack {
                    Text(item.timestamp, style: .date)
                    Text("at")
                    Text(item.timestamp, style: .time)
                }
                .font(.caption)
                .foregroundStyle(.secondary)

                Divider()

                MarkdownView(item.body)
                    .textSelection(.enabled)
            }
            .padding()
        }
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
