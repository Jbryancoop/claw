import Foundation
import CoreLocation

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = [] {
        didSet { saveMessages() }
    }
    @Published var isLoading: Bool = false

    weak var locationManager: LocationManager?

    private static let storageKey = "chat_history"

    init() {
        loadMessages()
    }

    func send(_ text: String) async {
        let userMessage = Message(role: .user, content: text)
        messages.append(userMessage)
        isLoading = true
        defer { isLoading = false }

        let location: DeviceLocation? = if let loc = locationManager?.lastLocation {
            DeviceLocation(from: loc)
        } else {
            nil
        }

        do {
            let response = try await ChatService.send(command: text, location: location)
            let serverMessage = Message(role: .server, content: response)
            messages.append(serverMessage)
        } catch {
            let errorMessage = Message(role: .server, content: "Error: \(error.localizedDescription)")
            messages.append(errorMessage)
        }
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
