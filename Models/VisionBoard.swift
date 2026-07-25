//
//  VisionBoard.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - ManifestationGoal Model

struct ManifestationGoal: Codable, Identifiable, Hashable, Equatable {
    let id: UUID
    var title: String
    var isAchieved: Bool
    var achievedAt: Date?

    init(title: String) {
        self.id = UUID()
        self.title = title
        self.isAchieved = false
    }

    mutating func markAchieved() {
        isAchieved = true
        achievedAt = Date()
    }

    mutating func unmarkAchieved() {
        isAchieved = false
        achievedAt = nil
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: Self, rhs: Self) -> Bool { lhs.id == rhs.id }
}

// MARK: - VisionBoard Model

struct VisionBoard: Codable, Identifiable {
    /// Bump when the persisted shape changes; decode falls back per-field so old
    /// payloads keep loading. New fields MUST use decodeIfPresent with a default.
    static let currentSchemaVersion = 2

    let id: UUID
    var schemaVersion: Int
    var title: String
    var description: String
    var userImageFilename: String
    var layout: VisionBoardLayout
    var style: VisionBoardStyle
    var images: [VisionBoardImage]
    var affirmations: [String]
    var createdAt: Date
    var updatedAt: Date
    var isPersonalized: Bool
    var manifestationGoals: [ManifestationGoal]
    var viewCount: Int
    var isFavorite: Bool

    init(
        title: String,
        description: String,
        userImageFilename: String,
        layout: VisionBoardLayout = .grid3x3,
        style: VisionBoardStyle = .cinematic
    ) {
        self.id = UUID()
        self.schemaVersion = Self.currentSchemaVersion
        self.title = title
        self.description = description
        self.userImageFilename = userImageFilename
        self.layout = layout
        self.style = style
        self.images = []
        self.affirmations = []
        self.createdAt = Date()
        self.updatedAt = Date()
        self.isPersonalized = true
        self.manifestationGoals = []
        self.viewCount = 0
        self.isFavorite = false
    }

    // MARK: - Codable (backward-compatible decoder)

    enum CodingKeys: String, CodingKey {
        case id, schemaVersion, title, description, userImageFilename, layout, style
        case images, affirmations, createdAt, updatedAt, isPersonalized
        case manifestationGoals, viewCount, isFavorite
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // Only identity is strictly required — every other field falls back to a
        // default so a single missing/unknown value can't destroy the whole board.
        id = try container.decode(UUID.self, forKey: .id)
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        title = try container.decodeIfPresent(String.self, forKey: .title) ?? "Vision Board"
        description = try container.decodeIfPresent(String.self, forKey: .description) ?? ""
        userImageFilename = try container.decodeIfPresent(String.self, forKey: .userImageFilename) ?? ""
        layout = (try? container.decode(VisionBoardLayout.self, forKey: .layout)) ?? .grid3x3
        style = (try? container.decode(VisionBoardStyle.self, forKey: .style)) ?? .cinematic
        images = try container.decodeIfPresent([VisionBoardImage].self, forKey: .images) ?? []
        affirmations = try container.decodeIfPresent([String].self, forKey: .affirmations) ?? []
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? Date()
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()
        isPersonalized = try container.decodeIfPresent(Bool.self, forKey: .isPersonalized) ?? true
        viewCount = try container.decodeIfPresent(Int.self, forKey: .viewCount) ?? 0
        isFavorite = try container.decodeIfPresent(Bool.self, forKey: .isFavorite) ?? false

        // Backward-compatible decoding: try [ManifestationGoal] first, then fall back to [String]
        if let goals = try? container.decode([ManifestationGoal].self, forKey: .manifestationGoals) {
            manifestationGoals = goals
        } else if let strings = try? container.decode([String].self, forKey: .manifestationGoals) {
            manifestationGoals = strings.map { ManifestationGoal(title: $0) }
        } else {
            manifestationGoals = []
        }
    }

    var userImage: UIImage? {
        ImageStore.load(userImageFilename)
    }

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    var formattedCreatedDate: String {
        VisionBoard.dateFormatter.string(from: createdAt)
    }

    mutating func incrementViewCount() {
        viewCount += 1
        updatedAt = Date()
    }

    mutating func toggleFavorite() {
        isFavorite.toggle()
        updatedAt = Date()
    }
}

// MARK: - VisionBoard Preview Data

extension VisionBoard {
    static var sampleVisionBoard: VisionBoard {
        let sampleImage = VisionBoardImage(prompt: "Sunrise over mountains", position: 0)

        return VisionBoard(
            title: "Dream Life",
            description: "Visualize your ideal future with purpose and clarity.",
            userImageFilename: "",
            layout: .grid3x3,
            style: .cinematic
        ).with {
            $0.images = Array(repeating: sampleImage, count: 9)
            $0.affirmations = [
                "I am attracting the life I deserve.",
                "Every step I take is toward abundance.",
                "I am capable, confident, and creative."
            ]
            $0.manifestationGoals = [
                ManifestationGoal(title: "Launch my startup"),
                ManifestationGoal(title: "Travel the world"),
                ManifestationGoal(title: "Build passive income streams")
            ]
            $0.isFavorite = true
            $0.viewCount = 42
        }
    }

    func with(_ updates: (inout VisionBoard) -> Void) -> VisionBoard {
        var copy = self
        updates(&copy)
        return copy
    }
}

// MARK: - VisionBoardImage Model

struct VisionBoardImage: Codable, Identifiable {
    let id: UUID
    /// Legacy storage — boards saved before images moved to disk carry raw bytes
    /// here; VisionBoardManager migrates them to `imageFilename` on load.
    var imageData: Data?
    /// Image file in ImageStore; preferred over imageData.
    var imageFilename: String?
    var imageURL: String?
    var prompt: String
    var isPersonalized: Bool
    var position: Int
    var aspectRatio: Double

    init(prompt: String, position: Int, isPersonalized: Bool = true) {
        self.id = UUID()
        self.prompt = prompt
        self.position = position
        self.isPersonalized = isPersonalized
        self.aspectRatio = 1.0
    }

    enum CodingKeys: String, CodingKey {
        case id, imageData, imageFilename, imageURL, prompt, isPersonalized, position, aspectRatio
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        imageFilename = try container.decodeIfPresent(String.self, forKey: .imageFilename)
        imageURL = try container.decodeIfPresent(String.self, forKey: .imageURL)
        prompt = try container.decodeIfPresent(String.self, forKey: .prompt) ?? ""
        isPersonalized = try container.decodeIfPresent(Bool.self, forKey: .isPersonalized) ?? true
        position = try container.decodeIfPresent(Int.self, forKey: .position) ?? 0
        aspectRatio = try container.decodeIfPresent(Double.self, forKey: .aspectRatio) ?? 1.0
    }

    /// Decoded once, then served from BoardImageCache — never re-decoded per body evaluation.
    var image: UIImage? {
        let key = id.uuidString as NSString
        if let cached = BoardImageCache.shared.object(forKey: key) { return cached }
        var decoded: UIImage?
        if let filename = imageFilename {
            decoded = ImageStore.load(filename)
        }
        if decoded == nil, let data = imageData {
            decoded = UIImage(data: data)
        }
        if let decoded {
            BoardImageCache.shared.setObject(decoded, forKey: key)
        }
        return decoded
    }
}

/// In-memory cache of decoded board images; NSCache evicts under memory pressure.
enum BoardImageCache {
    static let shared: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 120
        return cache
    }()
}

// MARK: - VisionBoardLayout

enum VisionBoardLayout: String, Codable, CaseIterable {
    case grid3x3 = "3x3"
    case collage = "collage"
    case singlePoster = "poster"

    var displayName: String {
        switch self {
        case .grid3x3: return "3×3 Grid"
        case .collage: return "Collage"
        case .singlePoster: return "Single Poster"
        }
    }

    var description: String {
        switch self {
        case .grid3x3: return "9 personalized images in a classic grid"
        case .collage: return "6 images in an artistic collage layout"
        case .singlePoster: return "1 large inspirational poster"
        }
    }

    var imageCount: Int {
        switch self {
        case .grid3x3: return 9
        case .collage: return 6
        case .singlePoster: return 1
        }
    }

    var systemImage: String {
        switch self {
        case .grid3x3: return "grid"
        case .collage: return "rectangle.3.group"
        case .singlePoster: return "photo"
        }
    }
}

// MARK: - VisionBoardStyle

enum VisionBoardStyle: String, Codable, CaseIterable {
    case cinematic
    case luxurious
    case minimalist
    case natural
    case futuristic
    case artistic

    var displayName: String {
        switch self {
        case .cinematic: return "Cinematic"
        case .luxurious: return "Luxurious"
        case .minimalist: return "Minimalist"
        case .natural: return "Natural"
        case .futuristic: return "Futuristic"
        case .artistic: return "Artistic"
        }
    }

    var description: String {
        switch self {
        case .cinematic: return "Movie-like scenes with dramatic lighting"
        case .luxurious: return "High-end lifestyle with elegant aesthetics"
        case .minimalist: return "Clean, simple designs with focus"
        case .natural: return "Organic, earth-toned environments"
        case .futuristic: return "Modern, tech-inspired visuals"
        case .artistic: return "Creative, abstract interpretations"
        }
    }

    var primaryColor: Color {
        switch self {
        case .cinematic: return .blue
        case .luxurious: return .cosmicGold
        case .minimalist: return .gray
        case .natural: return .green
        case .futuristic: return .cyan
        case .artistic: return .cosmicPink
        }
    }

    var gradientColors: [Color] {
        switch self {
        case .cinematic: return [.blue, .purple]
        case .luxurious: return [.cosmicGold, .orange]
        case .minimalist: return [.gray, .white]
        case .natural: return [.green, .brown]
        case .futuristic: return [.cyan, .blue]
        case .artistic: return [.cosmicPink, .purple]
        }
    }
}