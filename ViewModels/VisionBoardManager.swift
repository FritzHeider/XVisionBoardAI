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
            visionBoard.images = try await generatePersonalizedImages(for: visionBoard)

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
    
    private func generatePersonalizedImages(for visionBoard: VisionBoard) async throws -> [VisionBoardImage] {
        var images: [VisionBoardImage] = []
        let imageCount = visionBoard.layout.imageCount

        let prompts = generateImagePrompts(
            description: visionBoard.description,
            goals: visionBoard.manifestationGoals.map(\.title),
            style: visionBoard.style,
            count: imageCount
        )

        for (index, prompt) in prompts.enumerated() {
            generationProgress = 0.4 + (0.5 * Double(index) / Double(imageCount))
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            var image = VisionBoardImage(
                prompt: prompt,
                position: index,
                isPersonalized: true
            )
            
            // In a real app, this would call an AI image generation API
            // For now, we'll use placeholder data
            image.imageURL = "https://picsum.photos/400/400?random=\(index)"
            
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
        
        let stylePrefix = getStylePrefix(for: style)
        let basePrompts = [
            "\(stylePrefix) person achieving their dreams",
            "\(stylePrefix) successful lifestyle scene",
            "\(stylePrefix) person in their ideal environment",
            "\(stylePrefix) manifestation of abundance",
            "\(stylePrefix) person living their best life",
            "\(stylePrefix) achievement and celebration scene",
            "\(stylePrefix) person in their dream location",
            "\(stylePrefix) success and prosperity visualization",
            "\(stylePrefix) person embodying their goals"
        ]
        
        var prompts: [String] = []
        
        // Add goal-specific prompts
        for goal in goals.prefix(count / 2) {
            prompts.append("\(stylePrefix) person successfully \(goal.lowercased())")
        }
        
        // Fill remaining with base prompts
        let remaining = count - prompts.count
        prompts.append(contentsOf: basePrompts.prefix(remaining))
        
        return Array(prompts.prefix(count))
    }
    
    private func getStylePrefix(for style: VisionBoardStyle) -> String {
        switch style {
        case .cinematic:
            return "Cinematic, dramatic lighting,"
        case .luxurious:
            return "Luxurious, high-end, elegant,"
        case .minimalist:
            return "Minimalist, clean, simple,"
        case .natural:
            return "Natural, organic, earth-toned,"
        case .futuristic:
            return "Futuristic, modern, tech-inspired,"
        case .artistic:
            return "Artistic, creative, abstract,"
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
    
    private func saveVisionBoards() {
        do {
            let data = try JSONEncoder().encode(visionBoards)
            userDefaults.set(data, forKey: visionBoardsKey)
        } catch {
            print("Failed to save vision boards: \(error)")
        }
    }
    
    private func loadVisionBoards() {
        guard let data = userDefaults.data(forKey: visionBoardsKey) else { return }
        
        do {
            visionBoards = try JSONDecoder().decode([VisionBoard].self, from: data)
        } catch {
            print("Failed to load vision boards: \(error)")
        }
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

