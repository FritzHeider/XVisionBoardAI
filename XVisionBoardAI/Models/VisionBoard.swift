//
//  VisionBoard.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import Foundation
import SwiftUI

struct VisionBoard: Codable, Identifiable {
    let id: UUID
    var title: String
    var description: String
    var userImageData: Data
    var layout: VisionBoardLayout
    var style: VisionBoardStyle
    var images: [VisionBoardImage]
    var affirmations: [String]
    var createdAt: Date
    var updatedAt: Date
    var isPersonalized: Bool
    var manifestationGoals: [String]
    var viewCount: Int
    var isFavorite: Bool
    
    init(
        title: String,
        description: String,
        userImageData: Data,
        layout: VisionBoardLayout = .grid3x3,
        style: VisionBoardStyle = .cinematic
    ) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.userImageData = userImageData
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
    
    var userImage: UIImage? {
        UIImage(data: userImageData)
    }
    
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: createdAt)
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

struct VisionBoardImage: Codable, Identifiable {
    let id: UUID
    var imageData: Data?
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
    
    var image: UIImage? {
        guard let data = imageData else { return nil }
        return UIImage(data: data)
    }
}

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

enum VisionBoardStyle: String, Codable, CaseIterable {
    case cinematic = "cinematic"
    case luxurious = "luxurious"
    case minimalist = "minimalist"
    case natural = "natural"
    case futuristic = "futuristic"
    case artistic = "artistic"
    
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

