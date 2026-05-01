import UIKit

enum ImageStore {
    private static let directory: URL = {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("VisionBoardImages", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }()

    static func save(_ image: UIImage, filename: String = UUID().uuidString) throws -> String {
        guard let data = image.jpegData(compressionQuality: 0.8) else {
            throw CocoaError(.fileWriteUnknown)
        }
        let name = filename.hasSuffix(".jpg") ? filename : "\(filename).jpg"
        try data.write(to: directory.appendingPathComponent(name))
        return name
    }

    static func load(_ filename: String) -> UIImage? {
        guard let data = try? Data(contentsOf: directory.appendingPathComponent(filename)) else { return nil }
        return UIImage(data: data)
    }

    static func delete(_ filename: String) {
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(filename))
    }
}
