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
}
