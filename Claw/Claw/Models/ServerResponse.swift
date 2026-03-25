import Foundation

struct ServerResponse: Decodable {
    let ok: Bool
    let data: ResponseData?
    let error: String?

    struct ResponseData: Decodable {
        let message: String?
        let status: String?
    }
}

struct CommandResponse: Decodable {
    let ok: Bool
    let response: String?
    let error: String?
    let jobId: String?
}

struct JobStatusResponse: Decodable {
    let ok: Bool
    let job: JobInfo?
    let error: String?
}

struct JobInfo: Decodable {
    let id: String
    let status: String
    let steps: [AgentStep]?
    let response: String?
    let error: String?
    let command: String?
    let startedAt: String?
    let elapsedMs: Int?
}

struct CommandPayload: Encodable {
    let command: String
    let location: DeviceLocation?
}

struct LocationRequestResponse: Decodable {
    let ok: Bool
    let pending: Bool
    let requestId: String?
}

struct LocationRequestFulfillment: Encodable {
    let requestId: String
    let location: DeviceLocation
}
