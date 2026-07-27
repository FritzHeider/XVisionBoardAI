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

        // isGenerating / generationProgress / currentGeneratingBoard are single
        // manager-level properties, not scoped per attempt. If a swipe-dismissed
        // generation is still running and the user starts another, both tasks write
        // the same three properties: the progress bar and preview grid flicker
        // between runs, and one task's completion can flip isGenerating to false
        // while the other is still in flight. Serialise instead.
        guard !isGenerating else {
            errorMessage = "A vision board is already being generated. Please wait for it to finish."
            return nil
        }

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

            try Task.checkCancellation()

            generationProgress = 1.0
            visionBoards.append(visionBoard)
            save(visionBoard)

            isGenerating = false
            currentGeneratingBoard = nil
            return visionBoard

        } catch is CancellationError {
            // Remove any image files written by children that finished before cancel
            for image in currentGeneratingBoard?.images ?? [] {
                if let filename = image.imageFilename { ImageStore.delete(filename) }
            }
            isGenerating = false
            currentGeneratingBoard = nil
            return nil
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
            return try await GeminiTextService.generateAffirmations(
                description: description,
                goals: goals,
                style: style.displayName
            )
        } catch GeminiImageError.missingAPIKey {
            // Fall through to template affirmations when no key configured
        } catch {
            // Log but fall through to templates on any API error
            print("Gemini affirmations error: \(error)")
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
        let imageCount = visionBoard.layout.imageCount
        let referenceData = userImage.resized(maxDimension: 512).jpegData(compressionQuality: 0.75)
        let hasSelfie = referenceData != nil

        let prompts = generateImagePrompts(
            description: visionBoard.description,
            goals: visionBoard.manifestationGoals.map(\.title),
            style: visionBoard.style,
            count: imageCount,
            hasSelfie: hasSelfie
        )

        // Seed the board with placeholder slots so the live grid appears immediately
        var images: [VisionBoardImage] = (0..<imageCount).map { i in
            VisionBoardImage(prompt: prompts[safe: i] ?? prompts[0], position: i, isPersonalized: hasSelfie)
        }
        currentGeneratingBoard?.images = images

        // Generate ALL images in parallel — total time = slowest single image, not sum
        let layout = visionBoard.layout
        let refData = referenceData

        let results: [(Int, VisionBoardImage)] = await withTaskGroup(of: (Int, VisionBoardImage).self) { group in
            for index in 0..<imageCount {
                let prompt = prompts[safe: index] ?? prompts[0]
                group.addTask {
                    var image = VisionBoardImage(prompt: prompt, position: index, isPersonalized: hasSelfie)
                    guard !Task.isCancelled else { return (index, image) }
                    let imageSize = FalImageSize.forLayout(layout)

                    // Nano Banana 2: edit endpoint when a selfie exists (falls back
                    // to text-to-image inside FalAIService on failure)
                    if let url = try? await FalAIService.generateImage(
                        prompt: prompt,
                        referenceImageData: refData,
                        imageSize: imageSize
                    ) {
                        image.imageURL = url
                        if !Task.isCancelled,
                           let imageURL = URL(string: url),
                           let (imgData, _) = try? await URLSession.shared.data(from: imageURL),
                           let uiImage = UIImage(data: imgData) {
                            // Persist to disk; JSON keeps only the filename
                            if let filename = try? ImageStore.saveData(imgData, filename: "board-\(image.id.uuidString)") {
                                image.imageFilename = filename
                                BoardImageCache.shared.setObject(uiImage, forKey: image.id.uuidString as NSString)
                            } else {
                                image.imageData = imgData  // disk write failed — keep bytes as last resort
                            }
                        }
                    }
                    return (index, image)
                }
            }

            var collected: [(Int, VisionBoardImage)] = []
            for await result in group {
                collected.append(result)
                // Update progress and live preview as each image arrives
                let done = Double(collected.count)
                await MainActor.run {
                    self.generationProgress = 0.4 + (0.55 * done / Double(imageCount))
                    images[result.0] = result.1
                    self.currentGeneratingBoard?.images = images
                }
            }
            return collected
        }

        var finalImages = images
        for (i, img) in results { finalImages[i] = img }
        return finalImages
    }

    private func generateImagePrompts(
        description: String,
        goals: [String],
        style: VisionBoardStyle,
        count: Int,
        hasSelfie: Bool = true
    ) -> [String] {
        let styleMeta = styleMeta(for: style)
        let subjectPhrase = hasSelfie
            ? "the person from the reference photo"
            : "a confident, radiant person"
        let selfieInstruction = hasSelfie
            ? "Use the attached reference photo as the subject's face and appearance. "
            : ""

        var prompts: [String] = goals.prefix(max(1, count / 2)).map { goal in
            "\(selfieInstruction)\(styleMeta.prefix) \(subjectPhrase) achieving \(goal), ultra-detailed, photorealistic, 8k, \(styleMeta.suffix)"
        }

        let topic = description.isEmpty ? "living their dream life" : description.lowercased()
        let fillers: [String] = [
            "\(selfieInstruction)\(styleMeta.prefix) \(subjectPhrase) \(topic), \(styleMeta.suffix)",
            "\(selfieInstruction)\(styleMeta.prefix) \(subjectPhrase) in an abundant luxury lifestyle, \(styleMeta.suffix)",
            "\(selfieInstruction)\(styleMeta.prefix) \(subjectPhrase) radiating confidence and joy, \(styleMeta.suffix)",
            "\(selfieInstruction)\(styleMeta.prefix) \(subjectPhrase) in a stunning dream home interior, \(styleMeta.suffix)",
            "\(selfieInstruction)\(styleMeta.prefix) \(subjectPhrase) celebrating a major achievement, \(styleMeta.suffix)",
            "\(selfieInstruction)\(styleMeta.prefix) \(subjectPhrase) at a beautiful dream travel destination at golden hour, \(styleMeta.suffix)",
            "\(selfieInstruction)\(styleMeta.prefix) \(subjectPhrase) as a successful entrepreneur working from paradise, \(styleMeta.suffix)",
            "\(selfieInstruction)\(styleMeta.prefix) \(subjectPhrase) surrounded by abundance and prosperity, \(styleMeta.suffix)",
            "\(selfieInstruction)\(styleMeta.prefix) \(subjectPhrase) at peak fitness and health, vibrant energy, \(styleMeta.suffix)"
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
    
    /// Regenerates a single failed image tile in an existing board.
    func regenerateImage(boardID: UUID, imageID: UUID) async {
        guard let boardIndex = visionBoards.firstIndex(where: { $0.id == boardID }),
              let imageIndex = visionBoards[boardIndex].images.firstIndex(where: { $0.id == imageID }) else { return }
        let board = visionBoards[boardIndex]
        var image = board.images[imageIndex]
        let refData = board.userImage?.resized(maxDimension: 512).jpegData(compressionQuality: 0.75)

        do {
            let url = try await FalAIService.generateImage(
                prompt: image.prompt,
                referenceImageData: refData,
                imageSize: FalImageSize.forLayout(board.layout)
            )
            image.imageURL = url
            if let imageURL = URL(string: url),
               let (imgData, _) = try? await URLSession.shared.data(from: imageURL),
               UIImage(data: imgData) != nil,
               let filename = try? ImageStore.saveData(imgData, filename: "board-\(image.id.uuidString)") {
                image.imageFilename = filename
                BoardImageCache.shared.removeObject(forKey: image.id.uuidString as NSString)
            }
            // Re-resolve indices — the board list may have changed during the await
            guard let idx = visionBoards.firstIndex(where: { $0.id == boardID }),
                  let imgIdx = visionBoards[idx].images.firstIndex(where: { $0.id == imageID }) else { return }
            visionBoards[idx].images[imgIdx] = image
            visionBoards[idx].updatedAt = Date()
            save(visionBoards[idx])
        } catch {
            errorMessage = "Image generation failed: \(error.localizedDescription)"
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
        save(visionBoards[boardIndex])
    }

    func deleteVisionBoard(_ visionBoard: VisionBoard) {
        ImageStore.delete(visionBoard.userImageFilename)
        for image in visionBoard.images {
            if let filename = image.imageFilename { ImageStore.delete(filename) }
        }
        let file = Self.boardsDirectory.appendingPathComponent("\(visionBoard.id.uuidString).json")
        try? FileManager.default.removeItem(at: file)
        visionBoards.removeAll { $0.id == visionBoard.id }
    }

    /// Removes every board and all of its on-disk assets.
    ///
    /// Backs the "Delete Account" promise in ProfileView: boards are stored in a
    /// single device-wide directory, not namespaced per account, so without this
    /// a deleted account's boards reappear for the next account on the device.
    func deleteAllVisionBoards() {
        for board in visionBoards {
            ImageStore.delete(board.userImageFilename)
            for image in board.images {
                if let filename = image.imageFilename { ImageStore.delete(filename) }
                BoardImageCache.shared.removeObject(forKey: image.id.uuidString as NSString)
            }
        }
        visionBoards.removeAll()
        // Remove the whole directory (including any quarantined/corrupt files)
        // rather than deleting file-by-file, so nothing survives the wipe.
        try? FileManager.default.removeItem(at: Self.boardsDirectory)
    }

    func toggleFavorite(_ visionBoard: VisionBoard) {
        if let index = visionBoards.firstIndex(where: { $0.id == visionBoard.id }) {
            visionBoards[index].toggleFavorite()
            save(visionBoards[index])
        }
    }

    func incrementViewCount(_ visionBoard: VisionBoard) {
        if let index = visionBoards.firstIndex(where: { $0.id == visionBoard.id }) {
            visionBoards[index].incrementViewCount()
            save(visionBoards[index])
        }
    }

    func updateVisionBoard(_ visionBoard: VisionBoard) {
        if let index = visionBoards.firstIndex(where: { $0.id == visionBoard.id }) {
            visionBoards[index] = visionBoard
            save(visionBoards[index])
        }
    }
    
    // MARK: - Data Persistence

    private static var boardsDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("VisionBoards", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    /// Writes a single board's JSON file, surfacing failures via errorMessage.
    private func save(_ board: VisionBoard) {
        let file = Self.boardsDirectory.appendingPathComponent("\(board.id.uuidString).json")
        do {
            let data = try JSONEncoder().encode(board)
            try data.write(to: file, options: .atomic)
        } catch {
            print("[VisionBoardManager] Failed to save board \(board.id): \(error)")
            errorMessage = "Failed to save your vision board: \(error.localizedDescription)"
        }
    }

    private func saveVisionBoards() {
        for board in visionBoards { save(board) }
    }

    private func loadVisionBoards() {
        let dir = Self.boardsDirectory
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: dir.path) else { return }
        var loaded: [VisionBoard] = []
        for filename in files where filename.hasSuffix(".json") {
            let file = dir.appendingPathComponent(filename)
            do {
                let data = try Data(contentsOf: file)
                loaded.append(try JSONDecoder().decode(VisionBoard.self, from: data))
            } catch {
                // Never silently drop a board: log and quarantine for diagnosis
                print("[VisionBoardManager] Failed to load \(filename): \(error)")
                quarantine(file)
            }
        }
        visionBoards = loaded.sorted { $0.createdAt < $1.createdAt }
        migrateLegacyImageData()
    }

    private func quarantine(_ file: URL) {
        let dir = Self.boardsDirectory.appendingPathComponent("Corrupted", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        try? FileManager.default.moveItem(at: file, to: dir.appendingPathComponent(file.lastPathComponent))
    }

    /// One-time migration: boards saved before images moved to disk carry raw
    /// bytes in imageData; write them to ImageStore and drop the bytes from JSON.
    private func migrateLegacyImageData() {
        for boardIndex in visionBoards.indices {
            var migrated = false
            for imageIndex in visionBoards[boardIndex].images.indices {
                let img = visionBoards[boardIndex].images[imageIndex]
                guard img.imageFilename == nil, let data = img.imageData else { continue }
                if let filename = try? ImageStore.saveData(data, filename: "board-\(img.id.uuidString)") {
                    visionBoards[boardIndex].images[imageIndex].imageFilename = filename
                    visionBoards[boardIndex].images[imageIndex].imageData = nil
                    migrated = true
                }
            }
            if migrated {
                visionBoards[boardIndex].schemaVersion = VisionBoard.currentSchemaVersion
                save(visionBoards[boardIndex])
            }
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

