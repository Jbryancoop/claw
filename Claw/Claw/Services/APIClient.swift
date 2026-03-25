import Foundation

actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        // Reduce battery: wait for connectivity instead of failing immediately
        config.waitsForConnectivity = true
        self.session = URLSession(configuration: config)

        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    // MARK: - Generic Request

    func request<T: Decodable>(
        url: URL,
        method: String = "GET",
        body: (any Encodable)? = nil
    ) async throws -> T {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let token = ServerConfig.apiToken
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try encoder.encode(AnyEncodable(body))
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let message = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw APIError.serverError(statusCode: httpResponse.statusCode, message: message)
        }

        return try decoder.decode(T.self, from: data)
    }

    // MARK: - Convenience Methods

    func postLocation(_ location: DeviceLocation) async throws -> ServerResponse {
        try await request(url: ServerConfig.locationURL, method: "POST", body: location)
    }

    func registerDeviceToken(_ tokenHex: String) async throws -> ServerResponse {
        let payload = ["device_token": tokenHex, "platform": "ios"]
        try await request(url: ServerConfig.deviceTokenURL, method: "POST", body: payload)
    }

    func sendCommand(_ command: String) async throws -> CommandResponse {
        let payload = ["command": command]
        return try await request(url: ServerConfig.commandURL, method: "POST", body: payload)
    }

    func checkStatus() async throws -> ServerResponse {
        try await request(url: ServerConfig.statusURL, method: "GET")
    }
}

// MARK: - Errors

enum APIError: LocalizedError {
    case invalidResponse
    case serverError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from server"
        case .serverError(let code, let message):
            return "Server error \(code): \(message)"
        }
    }
}

// MARK: - Type-erased Encodable wrapper

private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init(_ value: any Encodable) {
        self._encode = { encoder in try value.encode(to: encoder) }
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
