import Foundation
import CoreLocation

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = [] {
        didSet { saveMessages() }
    }
    @Published var isLoading: Bool = false
    @Published var agentSteps: [AgentStep] = []
    @Published var elapsedSeconds: Int = 0

    weak var locationManager: LocationManager?

    private static let storageKey = "chat_history"
    private var pollTimer: Timer?
    private var elapsedTimer: Timer?

    init() {
        loadMessages()
    }

    func send(_ text: String) async {
        let userMessage = Message(role: .user, content: text)
        messages.append(userMessage)
        isLoading = true
        agentSteps = []
        elapsedSeconds = 0

        let location: DeviceLocation? = if let loc = locationManager?.lastLocation {
            DeviceLocation(from: loc)
        } else {
            nil
        }

        // Start elapsed timer
        elapsedTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in self?.elapsedSeconds += 1 }
        }

        do {
            // Submit command — server returns jobId immediately
            let jobResponse = try await APIClient.shared.sendCommand(text, location: location)

            if let jobId = jobResponse.jobId {
                // Poll for progress
                let response = try await pollForCompletion(jobId: jobId)
                let serverMessage = Message(role: .server, content: response)
                messages.append(serverMessage)
            } else if let response = jobResponse.response {
                // Legacy sync response (fallback)
                let serverMessage = Message(role: .server, content: response)
                messages.append(serverMessage)
            } else {
                let serverMessage = Message(role: .server, content: "(no response)")
                messages.append(serverMessage)
            }
        } catch {
            let errorMessage = Message(role: .server, content: "Error: \(error.localizedDescription)")
            messages.append(errorMessage)
        }

        stopTimers()
        isLoading = false
    }

    private func pollForCompletion(jobId: String) async throws -> String {
        while true {
            try await Task.sleep(for: .milliseconds(800))

            let status = try await APIClient.shared.pollCommandStatus(jobId: jobId)

            if let steps = status.job?.steps {
                self.agentSteps = steps
            }

            switch status.job?.status {
            case "complete":
                return status.job?.response ?? "(no response)"
            case "error":
                throw ChatError.serverRejected(status.job?.error ?? "Unknown error")
            default:
                continue // still running
            }
        }
    }

    private func stopTimers() {
        elapsedTimer?.invalidate()
        elapsedTimer = nil
        agentSteps = []
        elapsedSeconds = 0
    }

    func deleteMessage(_ id: UUID) {
        messages.removeAll { $0.id == id }
    }

    func clearHistory() {
        messages.removeAll()
    }

    private func saveMessages() {
        guard let data = try? JSONEncoder().encode(messages) else { return }
        UserDefaults.standard.set(data, forKey: Self.storageKey)
    }

    private func loadMessages() {
        guard let data = UserDefaults.standard.data(forKey: Self.storageKey),
              let saved = try? JSONDecoder().decode([Message].self, from: data) else { return }
        messages = saved
    }
}
