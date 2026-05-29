//
//  VisionBoardManager.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
@Observable
class VisionBoardManager {
    var visionBoards: [VisionBoard] = []
    var isGenerating = false
    var generationProgress: Double = 0.0
    var errorMessage: String?
    var currentGeneratingBoard: VisionBoard?
    
    private let userDefaults = UserDefaults.standard
    private let visionBoardsKey = "savedVisionBoards"
    
    init() {
        loadVisionBoards()
    }
    
    // MARK: - Vision Board Creation
    
    func createVisionBoard(
        title: String,
        description: String,
        userImage: UIImage,
        layout: VisionBoardLayout,
        style: VisionBoardStyle,
        manifestationGoals: [String]
    ) async -> VisionBoard? {

        isGenerating = true
        generationProgress = 0.0
        errorMessage = nil

        do {
            let filename = try ImageStore.save(userImage)

            var visionBoard = VisionBoard(
                title: title,
                description: description,
                userImageFilename: filename,
                layout: layout,
                style: style
            )
            visionBoard.manifestationGoals = manifestationGoals.map { ManifestationGoal(title: $0) }
            currentGeneratingBoard = visionBoard

            generationProgress = 0.2
            visionBoard.affirmations = try await generateAffirmations(
                description: description,
                goals: manifestationGoals,
                style: style
            )

            generationProgress = 0.4
            visionBoard.images = try await generatePersonalizedImages(for: visionBoard, userImage: userImage)

            generationProgress = 1.0
            visionBoards.append(visionBoard)
            saveVisionBoards()

            isGenerating = false
            currentGeneratingBoard = nil
            return visionBoard

        } catch {
            errorMessage = "Failed to create vision board: \(error.localizedDescription)"
            isGenerating = false
            currentGeneratingBoard = nil
            return nil
        }
    }
    
    // MARK: - AI Generation
    
    private func generateAffirmations(
        description: String,
        goals: [String],
        style: VisionBoardStyle
    ) async throws -> [String] {
        do {
            return try await ClaudeAPIService.generateAffirmations(
                description: description,
                goals: goals,
                style: style.displayName
            )
        } catch ClaudeAPIError.missingAPIKey {
            // Fall through to template affirmations when no key configured
        } catch {
            // Log but fall through to templates on any API error
            print("Claude API error: \(error)")
        }
        return templateAffirmations(goals: goals, style: style)
    }

    private func templateAffirmations(goals: [String], style: VisionBoardStyle) -> [String] {
        var affirmations: [String] = []
        for goal in goals.prefix(3) {
            affirmations.append("I am successfully achieving my goal of \(goal.lowercased())")
        }
        switch style {
        case .luxurious:
            affirmations.append("I live in luxury and abundance flows to me effortlessly")
        case .natural:
            affirmations.append("I am in harmony with nature and my authentic self")
        case .futuristic:
            affirmations.append("I embrace innovation and create my future with technology")
        case .artistic:
            affirmations.append("My creativity flows freely and inspires others")
        case .minimalist:
            affirmations.append("I find peace and clarity in simplicity and focus")
        case .cinematic:
            affirmations.append("My life unfolds like an inspiring movie with perfect timing")
        }
        let base = [
            "I am living my dream life with confidence and joy",
            "Every day brings me closer to my manifestation goals",
            "I attract abundance and success in all areas of my life",
            "My vision is becoming my reality through focused intention",
            "I am worthy of all the success and happiness I desire"
        ]
        return Array((affirmations + base).prefix(5))
    }
    
    private func generatePersonalizedImages(for visionBoard: VisionBoard, userImage: UIImage) async throws -> [VisionBoardImage] {
        var images: [VisionBoardImage] = []
        let imageCount = visionBoard.layout.imageCount
        // Resize selfie to 512px max — keeps base64 payload small
        let referenceData = userImage.resized(maxDimension: 512).jpegData(compressionQuality: 0.75)

        let prompts = generateImagePrompts(
            description: visionBoard.description,
            goals: visionBoard.manifestationGoals.map(\.title),
            style: visionBoard.style,
            count: imageCount
        )

        for (index, prompt) in prompts.enumerated() {
            generationProgress = 0.4 + (0.55 * Double(index) / Double(imageCount))

            var image = VisionBoardImage(prompt: prompt, position: index, isPersonalized: referenceData != nil)

            do {
                let url = try await FalAIService.generateImage(
                    prompt: prompt,
                    referenceImageData: referenceData,
                    imageSize: .forLayout(visionBoard.layout)
                )
                image.imageURL = url

                // Download and cache locally
                if let imageURL = URL(string: url),
                   let (imgData, _) = try? await URLSession.shared.data(from: imageURL),
                   UIImage(data: imgData) != nil {
                    image.imageData = imgData
                }
            } catch FalAIError.missingAPIKey {
                // No API key — use placeholder (dev/demo mode)
                image.imageURL = "https://picsum.photos/1024/1024?random=\(index + Int.random(in: 0..<9999))"
                if let url = URL(string: image.imageURL!),
                   let (imgData, _) = try? await URLSession.shared.data(from: url) {
                    image.imageData = imgData
                }
            }

            images.append(image)
        }
        return images
    }

    private func generateImagePrompts(
        description: String,
        goals: [String],
        style: VisionBoardStyle,
        count: Int
    ) -> [String] {
        let styleMeta = styleMeta(for: style)

        // Rich, aspirational prompts for each goal
        var prompts: [String] = goals.prefix(max(1, count / 2)).map { goal in
            "\(styleMeta.prefix) \(goal), ultra-detailed, photorealistic, 8k, \(styleMeta.suffix)"
        }

        // Fill remaining slots with lifestyle scenes keyed to the description
        let topic = description.isEmpty ? "living their dream life" : description.lowercased()
        let fillers: [String] = [
            "\(styleMeta.prefix) successful person \(topic), \(styleMeta.suffix)",
            "\(styleMeta.prefix) abundance and luxury lifestyle, \(styleMeta.suffix)",
            "\(styleMeta.prefix) person radiating confidence and joy, \(styleMeta.suffix)",
            "\(styleMeta.prefix) dream home interior with beautiful design, \(styleMeta.suffix)",
            "\(styleMeta.prefix) person celebrating achievement, crowd cheering, \(styleMeta.suffix)",
            "\(styleMeta.prefix) dream travel destination at golden hour, \(styleMeta.suffix)",
            "\(styleMeta.prefix) successful entrepreneur working from paradise, \(styleMeta.suffix)",
            "\(styleMeta.prefix) person surrounded by abundance and prosperity, \(styleMeta.suffix)",
            "\(styleMeta.prefix) peak fitness and health, vibrant energy, \(styleMeta.suffix)"
        ]

        prompts.append(contentsOf: fillers.prefix(count - prompts.count))
        return Array(prompts.prefix(count))
    }

    private struct StyleMeta {
        let prefix: String
        let suffix: String
    }

    private func styleMeta(for style: VisionBoardStyle) -> StyleMeta {
        switch style {
        case .cinematic:
            return StyleMeta(
                prefix: "Cinematic film still, dramatic volumetric lighting, shallow depth of field,",
                suffix: "movie quality, professional color grading, anamorphic lens flare"
            )
        case .luxurious:
            return StyleMeta(
                prefix: "Luxury editorial photo, high-end fashion photography,",
                suffix: "Vogue magazine style, opulent surroundings, premium quality"
            )
        case .minimalist:
            return StyleMeta(
                prefix: "Clean minimalist photography, neutral tones, zen aesthetic,",
                suffix: "intentional composition, negative space, tranquil mood"
            )
        case .natural:
            return StyleMeta(
                prefix: "Natural light photography, golden hour, organic textures,",
                suffix: "earthy palette, serene nature backdrop, authentic lifestyle"
            )
        case .futuristic:
            return StyleMeta(
                prefix: "Futuristic concept art, neon-lit cyberpunk aesthetic, holographic UI,",
                suffix: "ultra-modern tech environment, dynamic composition"
            )
        case .artistic:
            return StyleMeta(
                prefix: "Fine art photography with painterly color grading, dreamy bokeh,",
                suffix: "artistic composition, surreal atmosphere, vibrant colours"
            )
        }
    }
    
    // MARK: - Vision Board Management
    
    func toggleGoalAchieved(_ goal: ManifestationGoal, in boardID: UUID) {
        guard let boardIndex = visionBoards.firstIndex(where: { $0.id == boardID }),
              let goalIndex = visionBoards[boardIndex].manifestationGoals.firstIndex(where: { $0.id == goal.id }) else {
            return
        }
        if visionBoards[boardIndex].manifestationGoals[goalIndex].isAchieved {
            visionBoards[boardIndex].manifestationGoals[goalIndex].unmarkAchieved()
        } else {
            visionBoards[boardIndex].manifestationGoals[goalIndex].markAchieved()
        }
        visionBoards[boardIndex].updatedAt = Date()
        saveVisionBoards()
    }

    func deleteVisionBoard(_ visionBoard: VisionBoard) {
        ImageStore.delete(visionBoard.userImageFilename)
        visionBoards.removeAll { $0.id == visionBoard.id }
        saveVisionBoards()
    }
    
    func toggleFavorite(_ visionBoard: VisionBoard) {
        if let index = visionBoards.firstIndex(where: { $0.id == visionBoard.id }) {
            visionBoards[index].toggleFavorite()
            saveVisionBoards()
        }
    }
    
    func incrementViewCount(_ visionBoard: VisionBoard) {
        if let index = visionBoards.firstIndex(where: { $0.id == visionBoard.id }) {
            visionBoards[index].incrementViewCount()
            saveVisionBoards()
        }
    }
    
    func updateVisionBoard(_ visionBoard: VisionBoard) {
        if let index = visionBoards.firstIndex(where: { $0.id == visionBoard.id }) {
            visionBoards[index] = visionBoard
            saveVisionBoards()
        }
    }
    
    // MARK: - Data Persistence

    private static var boardsDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("VisionBoards", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func saveVisionBoards() {
        let dir = Self.boardsDirectory
        for board in visionBoards {
            let file = dir.appendingPathComponent("\(board.id.uuidString).json")
            if let data = try? JSONEncoder().encode(board) {
                try? data.write(to: file, options: .atomic)
            }
        }
        // Remove files for deleted boards
        let existingIDs = Set(visionBoards.map { $0.id.uuidString + ".json" })
        if let files = try? FileManager.default.contentsOfDirectory(atPath: dir.path) {
            for file in files where !existingIDs.contains(file) {
                try? FileManager.default.removeItem(at: dir.appendingPathComponent(file))
            }
        }
    }

    private func loadVisionBoards() {
        let dir = Self.boardsDirectory
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else { return }
        visionBoards = files
            .filter { $0.hasSuffix(".json") }
            .compactMap { filename -> VisionBoard? in
                let file = dir.appendingPathComponent(filename)
                guard let data = try? Data(contentsOf: file) else { return nil }
                return try? JSONDecoder().decode(VisionBoard.self, from: data)
            }
            .sorted { $0.createdAt < $1.createdAt }
    }
    
    // MARK: - Computed Properties
    
    var favoriteVisionBoards: [VisionBoard] {
        visionBoards.filter { $0.isFavorite }
    }
    
    var recentVisionBoards: [VisionBoard] {
        visionBoards.sorted { $0.createdAt > $1.createdAt }.prefix(5).map { $0 }
    }
    
    var totalVisionBoards: Int {
        visionBoards.count
    }
    
    var totalViews: Int {
        visionBoards.reduce(0) { $0 + $1.viewCount }
    }
}

