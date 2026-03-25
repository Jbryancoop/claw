import Foundation

@MainActor
final class ChatViewModel: ObservableObject {
    @Published var messages: [Message] = []
    @Published var isLoading: Bool = false

    func send(_ text: String) async {
        let userMessage = Message(role: .user, content: text)
        messages.append(userMessage)
        isLoading = true
        defer { isLoading = false }

        do {
            let response = try await ChatService.send(command: text)
            let serverMessage = Message(role: .server, content: response)
            messages.append(serverMessage)
        } catch {
            let errorMessage = Message(role: .server, content: "Error: \(error.localizedDescription)")
            messages.append(errorMessage)
        }
    }
}
