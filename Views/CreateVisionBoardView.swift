//
//  CreateVisionBoardView.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import SwiftUI
import PhotosUI

struct CreateVisionBoardView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(UserManager.self) var userManager
    @Environment(VisionBoardManager.self) var visionBoardManager
    @Environment(StoreManager.self) var storeManager
    
    @State private var currentStep: CreationStep = .selfie
    @State private var capturedSelfie: UIImage?
    @State private var title = ""
    @State private var description = ""
    @State private var selectedLayout: VisionBoardLayout = .grid3x3
    @State private var selectedStyle: VisionBoardStyle = .cinematic
    @State private var manifestationGoals: [String] = []
    @State private var newGoal = ""
    @State private var showingCamera = false
    @State private var showingUpgrade = false
    @State private var createdVisionBoard: VisionBoard?
    @State private var showingPhotoPicker = false
    @State private var photoPickerItem: PhotosPickerItem?
    @State private var generationError: String?
    @State private var showingBoardDetail = false
    @State private var generationTask: Task<Void, Never>?
    @State private var showingAIConsent = false
    
    enum CreationStep: CaseIterable {
        case selfie, details, customize, goals, generate, complete

        var title: String {
            switch self {
            case .selfie:    return "Your Photo"
            case .details:   return "Vision Details"
            case .customize: return "Layout & Style"
            case .goals:     return "Your Goals"
            case .generate:  return "Generating..."
            case .complete:  return "Complete!"
            }
        }

        var progress: Double {
            switch self {
            case .selfie:    return 0.17
            case .details:   return 0.34
            case .customize: return 0.51
            case .goals:     return 0.68
            case .generate:  return 0.85
            case .complete:  return 1.0
            }
        }
    }
    
    private var hasReachedLimit: Bool {
        !storeManager.canCreateVisionBoard(currentCount: visionBoardManager.totalVisionBoards)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.astralBlack.ignoresSafeArea()

                if hasReachedLimit {
                    limitReachedView
                } else {
                    VStack(spacing: 0) {
                        // Progress bar
                        progressBar

                        // Content — safeAreaInset pins nav buttons above the tab bar
                        // and auto-insets the scroll view so content stays visible
                        ScrollView {
                            VStack(spacing: 24) {
                                stepContent
                            }
                            .padding()
                        }
                        .safeAreaInset(edge: .bottom, spacing: 0) {
                            navigationButtons
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        generationTask?.cancel()
                        dismiss()
                    }
                    .foregroundStyle(Color.astralText)
                }

                ToolbarItem(placement: .principal) {
                    Text(hasReachedLimit ? "Create Board" : currentStep.title)
                        .font(.headline)
                        .foregroundStyle(Color.astralText)
                }
            }
        }
        // Swipe-to-dismiss bypasses the Cancel button, so without this the generation
        // Task keeps running after the sheet is gone — still issuing billed fal.ai
        // requests and mutating the shared VisionBoardManager the user can no longer see.
        .onDisappear {
            generationTask?.cancel()
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(capturedImage: $capturedSelfie, isPresented: $showingCamera)
        }
        .sheet(isPresented: $showingUpgrade) {
            SubscriptionView()
        }
        // Resume generation only if consent was actually granted; dismissing
        // without agreeing leaves the user on the goals step with nothing sent.
        .sheet(isPresented: $showingAIConsent, onDismiss: {
            if userManager.hasConsentedToAIProcessing {
                generateVisionBoard()
            }
        }) {
            AIProcessingConsentView {
                userManager.hasConsentedToAIProcessing = true
                showingAIConsent = false
            }
        }
        .sheet(isPresented: $showingBoardDetail, onDismiss: { dismiss() }) {
            if let board = createdVisionBoard {
                VisionBoardDetailView(visionBoard: board)
            }
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $photoPickerItem, matching: .images)
        .onChange(of: photoPickerItem) { _, item in
            Task {
                if let data = try? await item?.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    capturedSelfie = image
                }
            }
        }
        .alert("Generation Failed", isPresented: Binding<Bool>(
            get: { generationError != nil },
            set: { if !$0 { generationError = nil } }
        )) {
            Button("OK") { generationError = nil }
        } message: {
            Text(generationError ?? "")
        }
        // The app had no haptics at all. Finishing a board is its defining moment
        // and can take minutes, so it's exactly where a success tap belongs.
        .sensoryFeedback(.success, trigger: createdVisionBoard?.id)
        .sensoryFeedback(.error, trigger: generationError)
    }
    
    // MARK: - Limit Reached View

    private var limitReachedView: some View {
        VStack(spacing: 32) {
            Spacer()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.astralGold.opacity(0.12))
                        .frame(width: 100, height: 100)
                    Image(systemName: "crown.fill")
                        .font(.system(size: 44, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(colors: [.astralGold, .orange], startPoint: .top, endPoint: .bottom)
                        )
                }
                .astralPulsing()

                Text("Upgrade to Create More")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.astralText)
                    .multilineTextAlignment(.center)

                Text("You've used your free board. Upgrade to ManifestMe Pro for unlimited vision boards.")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(Color.astralTextMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
            }

            Button {
                showingUpgrade = true
            } label: {
                Label("Unlock Pro", systemImage: "crown.fill")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(colors: [.astralViolet, .astralIndigo], startPoint: .leading, endPoint: .trailing)
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: AstralTheme.Radius.lg))
            }
            .padding(.horizontal, AstralTheme.Spacing.xl)

            Spacer()
        }
        .padding()
    }

    // MARK: - Progress Bar

    private var progressBar: some View {
        VStack(spacing: 8) {
            ProgressView(value: currentStep.progress)
                .progressViewStyle(.linear)
                .tint(.astralViolet)
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            HStack {
                Text("Step \(CreationStep.allCases.firstIndex(of: currentStep)! + 1) of \(CreationStep.allCases.count - 1)")
                    .font(.caption)
                    .foregroundStyle(Color.astralText.opacity(0.7))
                
                Spacer()
                
                Text("\(Int(currentStep.progress * 100))%")
                    .font(.caption)
                    .foregroundStyle(Color.astralText.opacity(0.7))
            }
        }
        .padding()
        .background(Color.cosmicGray)
    }
    
    // MARK: - Step Content
    
    @ViewBuilder
    private var stepContent: some View {
        switch currentStep {
        case .selfie:
            selfieStep
        case .details:
            detailsStep
        case .customize:
            customizeStep
        case .goals:
            goalsStep
        case .generate:
            generateStep
        case .complete:
            completeStep
        }
    }
    
    // MARK: - Selfie Step
    
    private var selfieStep: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.astralViolet)
                .pulsing()
            
            VStack(spacing: 16) {
                Text("Let's Get Personal")
                    .manifestationTitle()
                
                Text("Take or upload a selfie to create personalized vision boards where you appear living your dreams. This makes your manifestations more powerful and emotionally connected.")
                    .manifestationBody()
                    .multilineTextAlignment(.center)
            }
            
            // Feature badges
            VStack(spacing: 12) {
                FeatureBadge(icon: "brain.head.profile", text: "AI-Powered Personalization", color: .astralViolet)
                FeatureBadge(icon: "camera.fill", text: "Face Integration", color: .astralIndigo)
                FeatureBadge(icon: "heart.fill", text: "Dream Visualization", color: .astralRose)
            }

            // Standing disclosure, shown every time rather than only in the
            // one-time consent sheet: the user is about to hand over a photo of
            // their face and should be able to see where it goes at the moment
            // they choose it, not just the first time.
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle")
                    .scaledFont(size: 12, relativeTo: .caption2)
                Text("Your photo is sent to fal.ai to generate your images. [Privacy Policy](\(AppLinks.privacyPolicy.absoluteString))")
                    .fixedSize(horizontal: false, vertical: true)
            }
            .font(.system(.caption2, design: .rounded))
            .foregroundStyle(Color.astralTextMuted)
            .tint(Color.astralViolet)
            .padding(.horizontal, 4)

            // Selfie preview or capture
            if let selfie = capturedSelfie {
                VStack(spacing: 16) {
                    Image(uiImage: selfie)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 150, height: 150)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.cosmicPurple, lineWidth: 3)
                        )
                    
                    Button("Retake Photo") {
                        showingCamera = true
                    }
                    .foregroundStyle(Color.astralViolet)
                }
            } else {
                VStack(spacing: 16) {
                    Button("Take Photo") {
                        showingCamera = true
                    }
                    .cosmicButton()
                    
                    Button("Upload Photo") {
                        showingPhotoPicker = true
                    }
                    .cosmicButton()
                }
            }
            
            // Tips
            VStack(spacing: 8) {
                Text("💡 Tips for best results:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.astralGold)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Look directly at the camera")
                    Text("• Use good lighting (natural light works best)")
                    Text("• Keep your face clearly visible")
                    Text("• Smile naturally - you're manifesting your dreams!")
                }
                .font(.caption)
                .foregroundStyle(Color.astralText.opacity(0.8))
            }
            .padding()
            .cosmicCard()
        }
    }
    
    // MARK: - Details Step
    
    private var detailsStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("Describe Your Vision")
                    .manifestationTitle()
                
                Text("Tell us about your dreams and goals. The more specific you are, the better AI can create personalized images of you achieving them.")
                    .manifestationBody()
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 20) {
                CustomTextField(title: "Vision Board Title", text: $title)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("Vision Description")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(Color.astralText)
                    
                    TextEditor(text: $description)
                        .frame(minHeight: 120)
                        .scrollContentBackground(.hidden)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.astralSurface)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.astralViolet.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .foregroundStyle(Color.astralText)
                }
            }
            
            // Example prompts
            VStack(alignment: .leading, spacing: 12) {
                Text("💡 Example descriptions:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.astralGold)
                
                VStack(alignment: .leading, spacing: 8) {
                    ExamplePrompt(text: "I want to live in a beautiful modern home by the ocean, travel to exotic destinations, and run a successful business that helps people.")
                    
                    ExamplePrompt(text: "My dream is to be a published author, speak at conferences, and inspire millions while living in financial abundance.")
                    
                    ExamplePrompt(text: "I see myself as a fitness influencer, living a healthy lifestyle, and motivating others to achieve their health goals.")
                }
            }
            .padding()
            .cosmicCard()
        }
    }
    
    // MARK: - Layout Step
    
    // MARK: - Customize Step (Layout + Style combined)

    private var customizeStep: some View {
        VStack(spacing: 28) {
            VStack(spacing: 8) {
                Text("Layout & Style")
                    .manifestationTitle()
                Text("Choose how your board is arranged and its visual mood.")
                    .manifestationBody()
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("LAYOUT")
                    .scaledFont(size: 11, relativeTo: .caption2, weight: .bold)
                    .foregroundStyle(Color.astralGold)
                    .tracking(1.5)

                VStack(spacing: 10) {
                    ForEach(VisionBoardLayout.allCases, id: \.self) { layout in
                        LayoutOption(layout: layout, isSelected: selectedLayout == layout) {
                            selectedLayout = layout
                        }
                    }
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("STYLE")
                    .scaledFont(size: 11, relativeTo: .caption2, weight: .bold)
                    .foregroundStyle(Color.astralGold)
                    .tracking(1.5)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(VisionBoardStyle.allCases, id: \.self) { style in
                        StyleOption(style: style, isSelected: selectedStyle == style) {
                            selectedStyle = style
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Goals Step
    
    private var goalsStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("Manifestation Goals")
                    .manifestationTitle()
                
                Text("Add specific goals to make your vision board more focused and powerful.")
                    .manifestationBody()
                    .multilineTextAlignment(.center)
            }
            
            // Add new goal
            HStack {
                TextField("Enter a manifestation goal...", text: $newGoal)
                    .textFieldStyle(.roundedBorder)
                
                Button("Add") {
                    if !newGoal.isEmpty {
                        manifestationGoals.append(newGoal)
                        newGoal = ""
                    }
                }
                .cosmicButton()
                .disabled(newGoal.isEmpty)
            }
            
            // Goals list
            if !manifestationGoals.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Goals:")
                        .font(.headline)
                        .foregroundStyle(Color.astralText)
                    
                    ForEach(manifestationGoals.indices, id: \.self) { index in
                        HStack {
                            Text("• \(manifestationGoals[index])")
                                .foregroundStyle(Color.astralText)
                            
                            Spacer()
                            
                            Button(action: {
                                manifestationGoals.remove(at: index)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                            }
                            // Otherwise every row is just "xmark circle fill, button".
                            .accessibilityLabel("Remove goal: \(manifestationGoals[index])")
                            .frame(minWidth: 44, minHeight: 44)
                            .contentShape(Rectangle())
                        }
                        .padding()
                        .cosmicCard()
                    }
                }
            }
            
            // Suggested goals
            VStack(alignment: .leading, spacing: 12) {
                Text("💡 Suggested goals:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(Color.astralGold)
                
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 8) {
                    ForEach(suggestedGoals, id: \.self) { goal in
                        Button(goal) {
                            if !manifestationGoals.contains(goal) {
                                manifestationGoals.append(goal)
                            }
                        }
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.cosmicPurple.opacity(0.3))
                        .foregroundStyle(Color.astralText)
                        .clipShape(Capsule())
                    }
                }
            }
            .padding()
            .cosmicCard()
        }
    }
    
    // MARK: - Generate Step

    private var generateStep: some View {
        VStack(spacing: 32) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundStyle(Color.astralViolet)
                .pulsing()

            VStack(spacing: 16) {
                Text("Creating Your Personalized Vision Board")
                    .manifestationTitle()
                    .multilineTextAlignment(.center)

                Text("AI is generating images featuring YOU living your dreams...")
                    .manifestationBody()
                    .multilineTextAlignment(.center)
            }

            // Live image preview grid — thumbnails appear as each image is generated
            if let images = visionBoardManager.currentGeneratingBoard?.images, !images.isEmpty {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 8) {
                    ForEach(images) { img in
                        VisionBoardImageView(image: img) { }
                            .frame(height: 90)
                            .clipShape(RoundedRectangle(cornerRadius: AstralTheme.Radius.sm))
                    }
                    ForEach(images.count..<(visionBoardManager.currentGeneratingBoard!.layout.imageCount), id: \.self) { _ in
                        RoundedRectangle(cornerRadius: AstralTheme.Radius.sm)
                            .fill(Color.astralSurface2)
                            .frame(height: 90)
                            .astralShimmer()
                    }
                }
                .padding(AstralTheme.Spacing.md)
                .astralCard()
                .transition(.opacity.combined(with: .scale(scale: 0.97)))
                .animation(AstralTheme.Motion.smooth, value: images.count)
            }

            // Progress indicator
            VStack(spacing: 16) {
                ProgressView(value: visionBoardManager.generationProgress)
                    .progressViewStyle(.linear)
                    .tint(.astralViolet)
                    .scaleEffect(x: 1, y: 3, anchor: .center)

                Text("\(Int(visionBoardManager.generationProgress * 100))% Complete")
                    .font(.subheadline)
                    .foregroundStyle(Color.astralText)
            }
            .padding()
            .cosmicCard()
            
            // Generation steps
            VStack(alignment: .leading, spacing: 12) {
                GenerationStep(
                    title: "Analyzing your selfie",
                    isComplete: visionBoardManager.generationProgress > 0.2
                )
                
                GenerationStep(
                    title: "Creating AI affirmations",
                    isComplete: visionBoardManager.generationProgress > 0.4
                )
                
                GenerationStep(
                    title: "Generating personalized images",
                    isComplete: visionBoardManager.generationProgress > 0.8
                )
                
                GenerationStep(
                    title: "Finalizing your vision board",
                    isComplete: visionBoardManager.generationProgress >= 1.0
                )
            }
            .padding()
            .cosmicCard()
        }
    }
    
    // MARK: - Complete Step
    
    private var completeStep: some View {
        VStack(spacing: 32) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(Color.astralSuccess)
                .pulsing()
            
            VStack(spacing: 16) {
                Text("Vision Board Created!")
                    .manifestationTitle()
                
                Text("Your personalized vision board featuring YOU living your dreams is ready!")
                    .manifestationBody()
                    .multilineTextAlignment(.center)
            }
            
            if let visionBoard = createdVisionBoard {
                VStack(spacing: 16) {
                    Text(visionBoard.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color.astralText)
                    
                    // Preview of first few images
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 8) {
                        ForEach(visionBoard.images.prefix(3)) { image in
                            if let uiImage = image.image {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(height: 80)
                                    .clipped()
                                    .clipShape(.rect(cornerRadius: 8))
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.cosmicGray)
                                    .frame(height: 80)
                                    .overlay(
                                        ProgressView()
                                            .progressViewStyle(.circular)
                                                .tint(.astralViolet)
                                    )
                            }
                        }
                    }
                    .padding()
                    .cosmicCard()
                }
            }
            
            VStack(spacing: 16) {
                Button("View Your Vision Board") {
                    showingBoardDetail = true
                }
                .cosmicButton()
                
                Button("Create Another") {
                    resetForm()
                    currentStep = .selfie
                }
                .foregroundStyle(Color.astralViolet)
            }
        }
    }
    
    // MARK: - Navigation Buttons
    
    private var navigationButtons: some View {
        HStack {
            if currentStep != .selfie && currentStep != .generate && currentStep != .complete {
                Button("Previous") {
                    previousStep()
                }
                .foregroundStyle(Color.astralText)
            }
            
            Spacer()
            
            if currentStep != .complete {
                Button(nextButtonTitle) {
                    nextStep()
                }
                .cosmicButton(isEnabled: canProceed)
                .disabled(!canProceed)
            }
        }
        .padding()
        .background(Color.cosmicGray)
    }
    
    // MARK: - Helper Properties
    
    private var nextButtonTitle: String {
        switch currentStep {
        case .goals: return "Generate Vision Board"
        case .generate: return "Generating..."
        default: return "Next"
        }
    }
    
    private var canProceed: Bool {
        switch currentStep {
        case .selfie:    return capturedSelfie != nil
        case .details:   return !title.isEmpty && !description.isEmpty
        case .customize: return true
        case .goals:     return true
        case .generate:  return false
        case .complete:  return true
        }
    }
    
    private var suggestedGoals: [String] {
        [
            "Financial Freedom",
            "Dream Home",
            "Travel the World",
            "Perfect Health",
            "Loving Relationship",
            "Successful Business",
            "Creative Expression",
            "Personal Growth"
        ]
    }
    
    // MARK: - Helper Methods
    
    private func nextStep() {
        switch currentStep {
        case .selfie:
            if storeManager.canCreateVisionBoard(currentCount: visionBoardManager.totalVisionBoards) {
                currentStep = .details
            } else {
                showingUpgrade = true
            }
        case .details:   currentStep = .customize
        case .customize: currentStep = .goals
        case .goals:     generateVisionBoard()
        case .generate:  break
        case .complete:  dismiss()
        }
    }
    
    private func previousStep() {
        switch currentStep {
        case .details:   currentStep = .selfie
        case .customize: currentStep = .details
        case .goals:     currentStep = .customize
        default: break
        }
    }
    
    private func generateVisionBoard() {
        guard let selfie = capturedSelfie else { return }

        // Nothing leaves the device until the user has explicitly agreed to
        // third-party AI processing. This is the single chokepoint in front of
        // both providers, so the guard lives here rather than in the button
        // handler — any future caller inherits it. Guideline 5.1.2(i).
        guard userManager.hasConsentedToAIProcessing else {
            showingAIConsent = true
            return
        }

        currentStep = .generate

        // Generation realistically runs 30s-3min (fal.ai polls up to ~60 attempts
        // per image, all images in parallel). Nothing is persisted until it
        // finishes, so if iOS suspends the app while the user checks a message the
        // whole run is lost with no error and no record it ever happened. A
        // background task assertion buys time to finish or fail visibly.
        var backgroundTask: UIBackgroundTaskIdentifier = .invalid
        backgroundTask = UIApplication.shared.beginBackgroundTask(withName: "VisionBoardGeneration") {
            // Expiration handler: iOS is reclaiming the assertion.
            if backgroundTask != .invalid {
                UIApplication.shared.endBackgroundTask(backgroundTask)
                backgroundTask = .invalid
            }
        }

        generationTask = Task {
            defer {
                if backgroundTask != .invalid {
                    UIApplication.shared.endBackgroundTask(backgroundTask)
                    backgroundTask = .invalid
                }
            }

            let visionBoard = await visionBoardManager.createVisionBoard(
                title: title,
                description: description,
                userImage: selfie,
                layout: selectedLayout,
                style: selectedStyle,
                manifestationGoals: manifestationGoals
            )

            guard !Task.isCancelled else { return }

            if let board = visionBoard {
                userManager.incrementVisionBoardCount()
                createdVisionBoard = board
                currentStep = .complete
            } else {
                generationError = visionBoardManager.errorMessage ?? "Generation failed. Please try again."
                visionBoardManager.generationProgress = 0.0
                currentStep = .goals
            }
        }
    }
    
    private func resetForm() {
        capturedSelfie = nil
        title = ""
        description = ""
        selectedLayout = .grid3x3
        selectedStyle = .cinematic
        manifestationGoals = []
        newGoal = ""
        createdVisionBoard = nil
    }
}

// MARK: - AI Processing Consent

/// Explicit opt-in shown once, immediately before the first generation run.
///
/// App Review Guideline 5.1.2(i) requires clear disclosure and explicit
/// permission before personal data is shared with third parties, and this app
/// sends the user's face. The copy here must stay factually accurate about what
/// is transmitted and to whom — if the provider list in `FalAIService` or
/// `GeminiTextService` changes, update this screen in the same commit.
struct AIProcessingConsentView: View {
    @Environment(\.dismiss) private var dismiss
    let onAgree: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                Color.astralBlack.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: AstralTheme.Spacing.lg) {
                        VStack(spacing: AstralTheme.Spacing.sm) {
                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: 40))
                                .foregroundStyle(Color.auroraGradient)

                            Text("Before we generate")
                                .font(.system(.title2, design: .rounded, weight: .bold))
                                .foregroundStyle(Color.astralText)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, AstralTheme.Spacing.lg)

                        Text("Creating your board means sending some of what you entered to AI services outside this app. Here's exactly what leaves your device:")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(Color.astralTextMuted)

                        VStack(alignment: .leading, spacing: AstralTheme.Spacing.md) {
                            disclosureItem(
                                icon: "person.crop.square.fill",
                                title: "Your photo → fal.ai",
                                detail: "The selfie you chose is sent to fal.ai, which generates the images of you in your dream scenes."
                            )
                            disclosureItem(
                                icon: "text.alignleft",
                                title: "Your goals → Google Gemini",
                                detail: "Your vision description, goals, and chosen style are sent to Google Gemini, which writes your affirmations."
                            )
                            disclosureItem(
                                icon: "iphone",
                                title: "Everything else stays here",
                                detail: "Your email, username, and finished boards are stored on this device only. We don't sell your data or use it for advertising."
                            )
                        }
                        .padding(AstralTheme.Spacing.lg)
                        .astralCard()

                        Text("You can't create a vision board without this — it's how the images and affirmations are made. Full details are in our [Privacy Policy](\(AppLinks.privacyPolicy.absoluteString)).")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(Color.astralTextMuted)
                            .tint(Color.astralViolet)

                        VStack(spacing: AstralTheme.Spacing.sm) {
                            Button("I Agree — Generate My Board") {
                                onAgree()
                            }
                            .astralButton(.primary)
                            .frame(maxWidth: .infinity)

                            Button("Not Now") { dismiss() }
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundStyle(Color.astralTextMuted)
                        }

                        Spacer(minLength: AstralTheme.Spacing.xl)
                    }
                    .padding(.horizontal, AstralTheme.Spacing.lg)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Color.astralTextMuted)
                }
            }
        }
        // Declining must be possible, but not by accident — an interactive
        // dismiss that skipped the decision would leave the user stuck on the
        // goals step with no explanation.
        .interactiveDismissDisabled()
    }

    private func disclosureItem(icon: String, title: String, detail: String) -> some View {
        HStack(alignment: .top, spacing: AstralTheme.Spacing.md) {
            Image(systemName: icon)
                .scaledFont(size: 16, relativeTo: .subheadline, weight: .semibold)
                .foregroundStyle(Color.astralViolet)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.astralText)
                Text(detail)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Color.astralTextMuted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

// MARK: - Supporting Views

struct ExamplePrompt: View {
    let text: String
    
    var body: some View {
        Text("“\(text)”")
            .font(.caption)
            .foregroundStyle(Color.astralText.opacity(0.8))
            .italic()
            .padding(.leading, 8)
    }
}

struct LayoutOption: View {
    let layout: VisionBoardLayout
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                Image(systemName: layout.systemImage)
                    .font(.title2)
                    .foregroundStyle(isSelected ? Color.astralGold : Color.astralText)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(layout.displayName)
                        .font(.headline)
                        .foregroundStyle(Color.astralText)
                    
                    Text(layout.description)
                        .font(.caption)
                        .foregroundStyle(Color.astralText.opacity(0.8))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(Color.astralGold)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.cosmicPurple.opacity(0.3) : Color.cosmicGray)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.cosmicGold : Color.clear, lineWidth: 2)
                    )
            )
        }
        // Read as one control ("3x3 Grid, 9 personalized images…, selected")
        // rather than three separate fragments.
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

struct StyleOption: View {
    let style: VisionBoardStyle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: style.gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.cosmicGold : Color.clear, lineWidth: 3)
                    )
                    .overlay(alignment: .topTrailing) {
                        // Selection was signalled by the gold stroke alone.
                        // A checkmark gives a shape cue as well, so the state
                        // survives Differentiate Without Colour and any form
                        // of colour blindness. Matches LayoutOption.
                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(Color.cosmicGold)
                                .padding(6)
                        }
                    }

                VStack(spacing: 4) {
                    Text(style.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundStyle(Color.astralText)

                    Text(style.description)
                        .font(.caption)
                        .foregroundStyle(Color.astralText.opacity(0.8))
                        .multilineTextAlignment(.center)
                        // Was lineLimit(2): the descriptions run to two lines
                        // already at the default size, so any scaling clipped
                        // them. Let the card grow instead.
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

struct GenerationStep: View {
    let title: String
    let isComplete: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isComplete ? Color.astralSuccess : Color.astralTextDim)

            Text(title)
                .foregroundStyle(Color.astralText)

            Spacer()

            if isComplete {
                Image(systemName: "checkmark")
                    .foregroundStyle(Color.astralSuccess)
            }
        }
    }
}

#Preview {
    CreateVisionBoardView()
        .environment(UserManager())
        .environment(VisionBoardManager())
        .environment(StoreManager())
}

