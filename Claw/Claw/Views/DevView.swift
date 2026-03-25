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
                .tint(ClawTheme.accent)
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
            .background(ClawTheme.background)
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
                    .foregroundStyle(ClawTheme.textTertiary)
                TextField("Filter logs...", text: $viewModel.searchText)
                    .textFieldStyle(.plain)
                    .foregroundStyle(ClawTheme.textPrimary)
                    .onSubmit { Task { await viewModel.fetchLogs() } }
                if !viewModel.searchText.isEmpty {
                    Button {
                        viewModel.searchText = ""
                        Task { await viewModel.fetchLogs() }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(ClawTheme.textTertiary)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(ClawTheme.surfaceElevated)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .padding(.horizontal)
            .padding(.top, 8)

            Text("\(viewModel.totalLogs) total entries")
                .font(.caption2)
                .foregroundStyle(ClawTheme.textTertiary)
                .padding(.top, 4)

            List(viewModel.logs) { entry in
                NavigationLink {
                    LogDetailView(entry: entry)
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(entry.message)
                                .font(.system(.caption, design: .monospaced))
                                .fontWeight(.medium)
                                .foregroundStyle(ClawTheme.accent)
                                .lineLimit(1)
                            Spacer()
                            Text(formatTimestamp(entry.timestamp))
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(ClawTheme.textTertiary)
                        }
                        if let data = entry.data, !data.isEmpty {
                            Text(data)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(ClawTheme.textSecondary)
                                .lineLimit(3)
                        }
                    }
                }
                .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
                .listRowBackground(ClawTheme.surface)
            }
            .scrollContentBackground(.hidden)
            .background(ClawTheme.background)
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
                .listRowBackground(ClawTheme.surface)
                Section("Server") {
                    statRow("Uptime", value: formatUptime(s.uptime ?? 0))
                    statRow("Database Size", value: formatBytes(s.dbSizeBytes ?? 0))
                }
                .listRowBackground(ClawTheme.surface)
                Section("Activity") {
                    statRow("Last Location", value: s.lastLocationAt.map { formatTimestamp($0) } ?? "—")
                    statRow("Last Chat", value: s.lastChatAt.map { formatTimestamp($0) } ?? "—")
                }
                .listRowBackground(ClawTheme.surface)
            } else {
                Section {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(ClawTheme.background)
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
                        .foregroundStyle(chat.role == "user" ? ClawTheme.accent : ClawTheme.accentBright)
                    Spacer()
                    Text(formatTimestamp(chat.timestamp))
                        .font(.caption2)
                        .foregroundStyle(ClawTheme.textTertiary)
                }
                Text(chat.content)
                    .font(.system(.caption, design: .default))
                    .foregroundStyle(ClawTheme.textPrimary)
                    .lineLimit(6)
                if let lat = chat.locationLat, let lon = chat.locationLon {
                    HStack(spacing: 2) {
                        Image(systemName: "mappin")
                            .foregroundStyle(ClawTheme.textTertiary)
                        Text("\(String(format: "%.4f", lat)), \(String(format: "%.4f", lon))")
                            .foregroundStyle(ClawTheme.textTertiary)
                    }
                    .font(.system(.caption2, design: .monospaced))
                }
            }
            .listRowInsets(EdgeInsets(top: 6, leading: 12, bottom: 6, trailing: 12))
            .listRowBackground(ClawTheme.surface)
        }
        .scrollContentBackground(.hidden)
        .background(ClawTheme.background)
        .listStyle(.plain)
        .refreshable { await viewModel.fetchChats() }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func statRow(_ label: String, value: String, detail: String? = nil) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(ClawTheme.textPrimary)
            Spacer()
            if let detail {
                Text(detail)
                    .font(.caption)
                    .foregroundStyle(ClawTheme.textSecondary)
            }
            Text(value)
                .fontWeight(.medium)
                .monospacedDigit()
                .foregroundStyle(ClawTheme.accent)
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

// MARK: - Log Detail

struct LogDetailView: View {
    let entry: LogEntry

    private var prettyData: String {
        guard let raw = entry.data, !raw.isEmpty else { return "" }
        // Try to pretty-print JSON
        if let jsonData = raw.data(using: .utf8),
           let obj = try? JSONSerialization.jsonObject(with: jsonData),
           let pretty = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted, .sortedKeys]),
           let str = String(data: pretty, encoding: .utf8) {
            return str
        }
        return raw
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Timestamp
                HStack {
                    Image(systemName: "clock")
                        .foregroundStyle(ClawTheme.textTertiary)
                    Text(entry.timestamp)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(ClawTheme.textSecondary)
                }

                // Message
                VStack(alignment: .leading, spacing: 4) {
                    Text("Message")
                        .font(.caption)
                        .foregroundStyle(ClawTheme.textTertiary)
                    Text(entry.message)
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(ClawTheme.accent)
                        .textSelection(.enabled)
                }

                // Data payload
                if !prettyData.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Data")
                            .font(.caption)
                            .foregroundStyle(ClawTheme.textTertiary)
                        Text(prettyData)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(ClawTheme.textPrimary)
                            .textSelection(.enabled)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(ClawTheme.surfaceElevated)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                }
            }
            .padding()
        }
        .background(ClawTheme.background)
        .navigationTitle("Log Entry")
        .navigationBarTitleDisplayMode(.inline)
    }
}
