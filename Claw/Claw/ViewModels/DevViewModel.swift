import Foundation

@MainActor
final class DevViewModel: ObservableObject {
    @Published var logs: [LogEntry] = []
    @Published var stats: ServerStats?
    @Published var chats: [ChatEntry] = []
    @Published var isLoading = false
    @Published var searchText = ""
    @Published var selectedTab: DevTab = .logs
    @Published var totalLogs = 0

    enum DevTab: String, CaseIterable {
        case logs = "Logs"
        case stats = "Stats"
        case chats = "Chats"
    }

    func fetchLogs() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let response = try await APIClient.shared.fetchLogs(
                limit: 200,
                search: searchText.isEmpty ? nil : searchText
            )
            logs = response.data ?? []
            totalLogs = response.total ?? logs.count
        } catch {
            // Keep existing data on failure
        }
    }

    func fetchStats() async {
        do {
            let response = try await APIClient.shared.fetchStats()
            stats = response.data
        } catch {
            // Ignore
        }
    }

    func fetchChats() async {
        do {
            let response = try await APIClient.shared.fetchChats()
            chats = response.data ?? []
        } catch {
            // Ignore
        }
    }

    func refreshAll() async {
        isLoading = true
        defer { isLoading = false }
        async let l: () = fetchLogs()
        async let s: () = fetchStats()
        async let c: () = fetchChats()
        _ = await (l, s, c)
    }
}
