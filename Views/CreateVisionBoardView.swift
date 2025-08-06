//
//  CreateVisionBoardView.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import SwiftUI

struct CreateVisionBoardView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var visionBoardManager: VisionBoardManager
    @EnvironmentObject var storeManager: StoreManager
    
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
    
    enum CreationStep: CaseIterable {
        case selfie, details, layout, style, goals, generate, complete
        
        var title: String {
            switch self {
            case .selfie: return "Capture Your Selfie"
            case .details: return "Vision Details"
            case .layout: return "Choose Layout"
            case .style: return "Select Style"
            case .goals: return "Manifestation Goals"
            case .generate: return "Generating..."
            case .complete: return "Complete!"
            }
        }
        
        var progress: Double {
            switch self {
            case .selfie: return 0.15
            case .details: return 0.3
            case .layout: return 0.45
            case .style: return 0.6
            case .goals: return 0.75
            case .generate: return 0.9
            case .complete: return 1.0
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.cosmicBlack.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Progress bar
                    progressBar
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 24) {
                            stepContent
                        }
                        .padding()
                    }
                    
                    // Navigation buttons
                    navigationButtons
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.cosmicWhite)
                }
                
                ToolbarItem(placement: .principal) {
                    Text(currentStep.title)
                        .font(.headline)
                        .foregroundColor(.cosmicWhite)
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraView(capturedImage: $capturedSelfie, isPresented: $showingCamera)
        }
        .sheet(isPresented: $showingUpgrade) {
            SubscriptionView()
        }
        .onChange(of: visionBoardManager.isGenerating) { isGenerating in
            if !isGenerating && currentStep == .generate {
                if let visionBoard = visionBoardManager.currentGeneratingBoard {
                    createdVisionBoard = visionBoard
                    currentStep = .complete
                }
            }
        }
    }
    
    // MARK: - Progress Bar
    
    private var progressBar: some View {
        VStack(spacing: 8) {
            ProgressView(value: currentStep.progress)
                .progressViewStyle(LinearProgressViewStyle(tint: .cosmicPurple))
                .scaleEffect(x: 1, y: 2, anchor: .center)
            
            HStack {
                Text("Step \(CreationStep.allCases.firstIndex(of: currentStep)! + 1) of \(CreationStep.allCases.count)")
                    .font(.caption)
                    .foregroundColor(.cosmicWhite.opacity(0.7))
                
                Spacer()
                
                Text("\(Int(currentStep.progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.cosmicWhite.opacity(0.7))
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
        case .layout:
            layoutStep
        case .style:
            styleStep
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
                .foregroundColor(.cosmicPurple)
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
                FeatureBadge(icon: "brain.head.profile", text: "AI-Powered Personalization")
                FeatureBadge(icon: "camera.fill", text: "Face Integration")
                FeatureBadge(icon: "heart.fill", text: "Dream Visualization")
            }
            
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
                    .foregroundColor(.cosmicPurple)
                }
            } else {
                VStack(spacing: 16) {
                    Button("Take Photo") {
                        showingCamera = true
                    }
                    .cosmicButton()
                    
                    Button("Upload Photo") {
                        // Handle photo upload
                        showingCamera = true
                    }
                    .cosmicButton()
                }
            }
            
            // Tips
            VStack(spacing: 8) {
                Text("💡 Tips for best results:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.cosmicGold)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("• Look directly at the camera")
                    Text("• Use good lighting (natural light works best)")
                    Text("• Keep your face clearly visible")
                    Text("• Smile naturally - you're manifesting your dreams!")
                }
                .font(.caption)
                .foregroundColor(.cosmicWhite.opacity(0.8))
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
                        .foregroundColor(.cosmicWhite)
                    
                    TextEditor(text: $description)
                        .frame(minHeight: 120)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.cosmicGray)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.cosmicPurple.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .foregroundColor(.cosmicWhite)
                }
            }
            
            // Example prompts
            VStack(alignment: .leading, spacing: 12) {
                Text("💡 Example descriptions:")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.cosmicGold)
                
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
    
    private var layoutStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("Choose Your Layout")
                    .manifestationTitle()
                
                Text("Select how you want your personalized vision board to be arranged.")
                    .manifestationBody()
                    .multilineTextAlignment(.center)
            }
            
            VStack(spacing: 16) {
                ForEach(VisionBoardLayout.allCases, id: \.self) { layout in
                    LayoutOption(
                        layout: layout,
                        isSelected: selectedLayout == layout
                    ) {
                        selectedLayout = layout
                    }
                }
            }
        }
    }
    
    // MARK: - Style Step
    
    private var styleStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Text("Select Your Style")
                    .manifestationTitle()
                
                Text("Choose the visual aesthetic for your personalized vision board.")
                    .manifestationBody()
                    .multilineTextAlignment(.center)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                ForEach(VisionBoardStyle.allCases, id: \.self) { style in
                    StyleOption(
                        style: style,
                        isSelected: selectedStyle == style
                    ) {
                        selectedStyle = style
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
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
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
                        .foregroundColor(.cosmicWhite)
                    
                    ForEach(manifestationGoals.indices, id: \.self) { index in
                        HStack {
                            Text("• \(manifestationGoals[index])")
                                .foregroundColor(.cosmicWhite)
                            
                            Spacer()
                            
                            Button(action: {
                                manifestationGoals.remove(at: index)
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                            }
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
                    .foregroundColor(.cosmicGold)
                
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
                        .foregroundColor(.cosmicWhite)
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
                .foregroundColor(.cosmicPurple)
                .pulsing()
            
            VStack(spacing: 16) {
                Text("Creating Your Personalized Vision Board")
                    .manifestationTitle()
                    .multilineTextAlignment(.center)
                
                Text("AI is generating images featuring YOU living your dreams...")
                    .manifestationBody()
                    .multilineTextAlignment(.center)
            }
            
            // Progress indicator
            VStack(spacing: 16) {
                ProgressView(value: visionBoardManager.generationProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: .cosmicPurple))
                    .scaleEffect(x: 1, y: 3, anchor: .center)
                
                Text("\(Int(visionBoardManager.generationProgress * 100))% Complete")
                    .font(.subheadline)
                    .foregroundColor(.cosmicWhite)
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
                .foregroundColor(.green)
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
                        .foregroundColor(.cosmicWhite)
                    
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
                                    .cornerRadius(8)
                            } else {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.cosmicGray)
                                    .frame(height: 80)
                                    .overlay(
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .cosmicPurple))
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
                    // Navigate to vision board detail
                    dismiss()
                }
                .cosmicButton()
                
                Button("Create Another") {
                    resetForm()
                    currentStep = .selfie
                }
                .foregroundColor(.cosmicPurple)
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
                .foregroundColor(.cosmicWhite)
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
        case .selfie: return capturedSelfie != nil
        case .details: return !title.isEmpty && !description.isEmpty
        case .layout: return true
        case .style: return true
        case .goals: return true
        case .generate: return false
        case .complete: return true
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
        case .selfie: currentStep = .details
        case .details: currentStep = .layout
        case .layout: currentStep = .style
        case .style: currentStep = .goals
        case .goals:
            if userManager.canCreateVisionBoard {
                generateVisionBoard()
            } else {
                showingUpgrade = true
            }
        case .generate: break
        case .complete: dismiss()
        }
    }
    
    private func previousStep() {
        switch currentStep {
        case .details: currentStep = .selfie
        case .layout: currentStep = .details
        case .style: currentStep = .layout
        case .goals: currentStep = .style
        default: break
        }
    }
    
    private func generateVisionBoard() {
        guard let selfieData = capturedSelfie?.jpegData(compressionQuality: 0.8) else { return }
        
        currentStep = .generate
        
        Task {
            let visionBoard = await visionBoardManager.createVisionBoard(
                title: title,
                description: description,
                userImageData: selfieData,
                layout: selectedLayout,
                style: selectedStyle,
                manifestationGoals: manifestationGoals
            )
            
            if visionBoard != nil {
                userManager.incrementVisionBoardCount()
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

// MARK: - Supporting Views

struct ExamplePrompt: View {
    let text: String
    
    var body: some View {
        Text("“\(text)”")
            .font(.caption)
            .foregroundColor(.cosmicWhite.opacity(0.8))
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
                    .foregroundColor(isSelected ? .cosmicGold : .cosmicWhite)
                    .frame(width: 30)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(layout.displayName)
                        .font(.headline)
                        .foregroundColor(.cosmicWhite)
                    
                    Text(layout.description)
                        .font(.caption)
                        .foregroundColor(.cosmicWhite.opacity(0.8))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.cosmicGold)
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
                
                VStack(spacing: 4) {
                    Text(style.displayName)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.cosmicWhite)
                    
                    Text(style.description)
                        .font(.caption)
                        .foregroundColor(.cosmicWhite.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
            }
        }
    }
}

struct GenerationStep: View {
    let title: String
    let isComplete: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isComplete ? "checkmark.circle.fill" : "circle")
                .foregroundColor(isComplete ? .green : .gray)
            
            Text(title)
                .foregroundColor(.cosmicWhite)
            
            Spacer()
            
            if isComplete {
                Image(systemName: "checkmark")
                    .foregroundColor(.green)
            }
        }
    }
}

#Preview {
    CreateVisionBoardView()
        .environmentObject(UserManager())
        .environmentObject(VisionBoardManager())
        .environmentObject(StoreManager())
}

