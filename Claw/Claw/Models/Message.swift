import Foundation
import UIKit

struct Message: Identifiable, Codable, Equatable {
    let id: UUID
    let role: Role
    let content: String
    let timestamp: Date
    let imageFileName: String?

    enum Role: String, Codable {
        case user
        case server
    }

    init(id: UUID = UUID(), role: Role, content: String, timestamp: Date = Date(), imageFileName: String? = nil) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.imageFileName = imageFileName
    }

    // MARK: - Image Storage

    var imageURL: URL? {
        guard let imageFileName else { return nil }
        return Self.imageDirectory.appendingPathComponent(imageFileName)
    }

    var image: UIImage? {
        guard let url = imageURL, let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static let imageDirectory: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("ChatImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    @discardableResult
    static func saveImage(_ imageData: Data, fileName: String) -> URL? {
        let url = imageDirectory.appendingPathComponent(fileName)
        do {
            try imageData.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}
