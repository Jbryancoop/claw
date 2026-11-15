import Foundation

actor APIClient {
    static let shared = APIClient()

    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 120
        config.timeoutIntervalForResource = 150
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
        let response: ServerResponse = try await request(url: ServerConfig.deviceTokenURL, method: "POST", body: payload)
        return response
    }

    func sendCommand(_ command: String, location: DeviceLocation? = nil, imageData: Data? = nil) async throws -> CommandResponse {
        if let imageData {
            return try await multipartRequest(url: ServerConfig.commandURL, command: command, location: location, imageData: imageData)
        }
        let payload = CommandPayload(command: command, location: location)
        return try await request(url: ServerConfig.commandURL, method: "POST", body: payload)
    }

    func sendBackgroundCommand(_ command: String, location: DeviceLocation? = nil, imageData: Data? = nil) async throws -> ServerResponse {
        let url = ServerConfig.baseURL.appending(path: "command/background")
        if let imageData {
            return try await multipartRequest(url: url, command: command, location: location, imageData: imageData)
        }
        let payload = CommandPayload(command: command, location: location)
        return try await request(url: url, method: "POST", body: payload)
    }

    func checkStatus() async throws -> ServerResponse {
        try await request(url: ServerConfig.statusURL, method: "GET")
    }

    func pollCommandStatus(jobId: String) async throws -> JobStatusResponse {
        let url = ServerConfig.baseURL.appending(path: "command/\(jobId)")
        return try await request(url: url, method: "GET")
    }

    func checkLocationRequest() async throws -> LocationRequestResponse {
        try await request(url: ServerConfig.locationRequestURL, method: "GET")
    }

    func respondToLocationRequest(_ location: DeviceLocation, requestId: String) async throws -> ServerResponse {
        let payload = LocationRequestFulfillment(requestId: requestId, location: location)
        let response: ServerResponse = try await request(url: ServerConfig.locationRequestURL, method: "POST", body: payload)
        return response
    }

    // MARK: - Notifications

    func fetchNotifications() async throws -> NotificationsResponse {
        try await request(url: ServerConfig.notificationsURL, method: "GET")
    }

    func deleteNotification(id: String) async throws -> ServerResponse {
        try await request(url: ServerConfig.notificationURL(id: id), method: "DELETE")
    }

    func updateNotificationRead(id: String, isRead: Bool) async throws -> ServerResponse {
        let payload = ["is_read": isRead]
        let response: ServerResponse = try await request(url: ServerConfig.notificationURL(id: id), method: "PUT", body: payload)
        return response
    }

    // MARK: - Developer

    func fetchLogs(limit: Int = 100, offset: Int = 0, search: String? = nil) async throws -> LogsResponse {
        var url = ServerConfig.logsURL
        var items = [URLQueryItem(name: "limit", value: "\(limit)"), URLQueryItem(name: "offset", value: "\(offset)")]
        if let search, !search.isEmpty { items.append(URLQueryItem(name: "search", value: search)) }
        url.append(queryItems: items)
        return try await request(url: url, method: "GET")
    }

    func fetchStats() async throws -> StatsResponse {
        try await request(url: ServerConfig.statsURL, method: "GET")
    }

    func fetchChats() async throws -> ChatsResponse {
        try await request(url: ServerConfig.chatsURL, method: "GET")
    }

    // MARK: - Multipart Upload

    private func multipartRequest<T: Decodable>(
        url: URL,
        command: String,
        location: DeviceLocation?,
        imageData: Data
    ) async throws -> T {
        let boundary = "Boundary-\(UUID().uuidString)"

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")

        let token = ServerConfig.apiToken
        if !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        var body = Data()

        // Command field
        body.appendMultipart(boundary: boundary, name: "command", value: command)

        // Location fields
        if let location {
            if let locationJSON = try? encoder.encode(location) {
                body.appendMultipart(boundary: boundary, name: "location", value: String(data: locationJSON, encoding: .utf8) ?? "")
            }
        }

        // Image file
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)

        // Close
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)

        request.httpBody = body

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

    // MARK: - TTS

    func requestTTS(_ text: String) async throws -> Data {
        var req = URLRequest(url: ServerConfig.ttsURL)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let token = ServerConfig.apiToken
        if !token.isEmpty {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.httpBody = try encoder.encode(["text": text])
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.invalidResponse
        }
        return data
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

// MARK: - Multipart Helpers

private extension Data {
    mutating func appendMultipart(boundary: String, name: String, value: String) {
        append("--\(boundary)\r\n".data(using: .utf8)!)
        append("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".data(using: .utf8)!)
        append("\(value)\r\n".data(using: .utf8)!)
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
