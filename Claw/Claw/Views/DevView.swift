import SwiftUI

struct DevView: View {
    @StateObject private var viewModel = DevViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab picker
                Picker("Section", selection: $viewModel.selectedTab) {
                    ForEach(DevViewModel.DevTab.allCases, id: \.self) { tab in
                        Text(tab.rawValue).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .padding(.top, 8)

                // Content
                switch viewModel.selectedTab {
                case .logs:
                    logsView
                case .stats:
                    statsView
                case .chats:
                    chatsView
                }
            }
            .navigationTitle("Developer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await viewModel.refreshAll() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .task {
                await viewModel.refreshAll()
            }
        }
    }

    // MARK: - Logs

    private var logsView: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Filter logs...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .onSubmit { Task { await viewModel.fetchLogs() } }
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                        Task { await viewModel.fetchLogs() }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
            .padding(.top, 8)

            Text("\(viewModel.totalLogs) total entries")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 4)

            List(viewModel.logs) { entry in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(entry.message)
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.medium)
                            .lineLimit(1)
                        Spacer()
                        Text(formatTimestamp(entry.timestamp))
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                    if let data = entry.data, !data.isEmpty {
                        Text(data)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(.secondary)
                            .lineLimit(3)
                    }
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
            }
            .listStyle(.plain)
            .refreshable { await viewModel.fetchLogs() }
        }
    }

    // MARK: - Stats

    private var statsView: some View {
        List {
            if let s = viewModel.stats {
                Section("Data") {
                    statRow("Notifications", value: "\(s.notifications ?? 0)", detail: "\(s.notificationsUnread ?? 0) unread")
                    statRow("Chats", value: "\(s.chats ?? 0)")
                    statRow("Locations", value: "\(s.locations ?? 0)")
                    statRow("Logs", value: "\(s.logs ?? 0)")
                    statRow("Device Tokens", value: "\(s.deviceTokens ?? 0)")
                }
                Section("Server") {
                    statRow("Uptime", value: formatUptime(s.uptime ?? 0))
                    statRow("Database Size", value: formatBytes(s.dbSizeBytes ?? 0))
                }
                Section("Activity") {
                    statRow("Last Location", value: s.lastLocationAt.map { formatTimestamp($0) } ?? "—")
                    statRow("Last Chat", value: s.lastChatAt.map { formatTimestamp($0) } ?? "—")
                }
            } else {
                Section {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .refreshable { await viewModel.fetchStats() }
    }

    // MARK: - Chats

    private var chatsView: some View {
        List(viewModel.chats) { chat in
            VStack(alignment: chat.role == "user" ? .trailing : .leading, spacing: 4) {
                HStack {
                    Text(chat.role == "user" ? "You" : "Larry")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(chat.role == "user" ? .blue : .orange)
                    Spacer()
                    Text(formatTimestamp(chat.timestamp))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Text(chat.content)
                    .font(.system(.caption, design: .default))
                    .lineLimit(6)
                if let lat = chat.locationLat, let lon = chat.locationLon {
                    Text("📍 \(String(format: "%.4f", lat)), \(String(format: "%.4f", lon))")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundStyle(.tertiary)
                }
            }
            .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
        }
        .listStyle(.plain)
        .refreshable { await viewModel.fetchChats() }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func statRow(_ label: String, value: String, detail: String? = nil) -> some View {
        HStack {
            Text(label)
            Spacer()
            if let detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(value)
                .fontWeight(.medium)
                .monospacedDigit()
        }
    }

    private func formatTimestamp(_ ts: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: ts) ?? ISO8601DateFormatter().date(from: ts) else { return ts }
        let rel = RelativeDateTimeFormatter()
        rel.unitsStyle = .abbreviated
        return rel.localizedString(for: date, relativeTo: Date())
    }

    private func formatUptime(_ seconds: Double) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        if h > 24 {
            return "\(h / 24)d \(h % 24)h"
        }
        return "\(h)h \(m)m"
    }

    private func formatBytes(_ bytes: Int) -> String {
        if bytes < 1024 { return "\(bytes) B" }
        if bytes < 1024 * 1024 { return String(format: "%.1f KB", Double(bytes) / 1024) }
        return String(format: "%.1f MB", Double(bytes) / (1024 * 1024))
    }
}
