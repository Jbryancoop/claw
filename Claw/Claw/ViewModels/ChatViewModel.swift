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

    func send(_ text: String, imageData: Data? = nil) async {
        // Save image to disk if present
        var imageFileName: String?
        if let imageData {
            let fileName = "\(UUID().uuidString).jpg"
            Message.saveImage(imageData, fileName: fileName)
            imageFileName = fileName
        }

        let userMessage = Message(role: .user, content: text, imageFileName: imageFileName)
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
            let jobResponse = try await APIClient.shared.sendCommand(text, location: location, imageData: imageData)

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
    
    func sendInBackground(_ text: String, imageData: Data? = nil) async {
        // Save image to disk if present
        var imageFileName: String?
        if let imageData {
            let fileName = "\(UUID().uuidString).jpg"
            Message.saveImage(imageData, fileName: fileName)
            imageFileName = fileName
        }

        let userMessage = Message(role: .user, content: text, imageFileName: imageFileName)
        messages.append(userMessage)

        let placeholderMessage = Message(
            role: .server,
            content: "Running in background... You'll receive a notification when complete."
        )
        messages.append(placeholderMessage)

        let location: DeviceLocation? = if let loc = locationManager?.lastLocation {
            DeviceLocation(from: loc)
        } else {
            nil
        }

        // Submit to background endpoint (server will handle notification)
        do {
            try await APIClient.shared.sendBackgroundCommand(text, location: location, imageData: imageData)
        } catch {
            let errorMessage = Message(role: .server, content: "Background task failed: \(error.localizedDescription)")
            messages.append(errorMessage)
        }
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
