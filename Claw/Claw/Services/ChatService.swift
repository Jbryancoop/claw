import Foundation

struct ChatService {
    static func send(command: String, location: DeviceLocation? = nil) async throws -> String {
        let response = try await APIClient.shared.sendCommand(command, location: location)
        if let error = response.error, !response.ok {
            throw ChatError.serverRejected(error)
        }
        return response.response ?? "(no response)"
    }
}

enum ChatError: LocalizedError {
    case serverRejected(String)

    var errorDescription: String? {
        switch self {
        case .serverRejected(let message):
            return message
        }
    }
}
