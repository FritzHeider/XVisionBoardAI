//
//  VisionBoardDetailView.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import SwiftUI
import AVFoundation // if using AVSpeechSynthesizer
import UserNotifications

struct VisionBoardDetailView: View {
    let visionBoard: VisionBoard
    @Environment(\.dismiss) private var dismiss
    @Environment(VisionBoardManager.self) var visionBoardManager

    @State private var speechManager = SpeechManager()
    @State private var showingEditView = false
    @State private var showingShareSheet = false
    @State private var showingDeleteAlert = false
    @State private var shareImage: UIImage?
    @State private var showingImageShare = false
    @State private var showingFullScreenImage: VisionBoardImage?
    @State private var currentAffirmationIndex = 0
    @State private var affirmationTask: Task<Void, Never>?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.cosmicBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header info
                        headerSection
                        
                        // Vision board grid
                        visionBoardGrid
                        
                        // Affirmations
                        affirmationsSection
                        
                        // Goals
                        if !visionBoard.manifestationGoals.isEmpty {
                            goalsSection
                        }
                        
                        // Actions
                        actionsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.cosmicWhite)
                }
                
                ToolbarItem(placement: .principal) {
                    Text(visionBoard.title)
                        .font(.headline)
                        .foregroundColor(.cosmicWhite)
                        .lineLimit(1)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { showingEditView = true }) {
                            Label("Edit Vision Board", systemImage: "pencil")
                        }

                        Button(action: {
                            visionBoardManager.toggleFavorite(visionBoard)
                        }) {
                            Label(
                                visionBoard.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                                systemImage: visionBoard.isFavorite ? "heart.slash" : "heart"
                            )
                        }

                        Button("Share") {
                            showingShareSheet = true
                        }

                        Button("Delete", role: .destructive) {
                            showingDeleteAlert = true
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.cosmicWhite)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            EditVisionBoardView(visionBoard: visionBoard)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: [createShareableContent()])
        }
        .sheet(isPresented: $showingImageShare) {
            if let img = shareImage {
                ShareSheet(items: [img])
            }
        }
        .alert("Delete Vision Board", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                visionBoardManager.deleteVisionBoard(visionBoard)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this vision board? This action cannot be undone.")
        }
        .fullScreenCover(item: $showingFullScreenImage) { image in
            FullScreenImageView(image: image) {
                showingFullScreenImage = nil
            }
        }
        .onAppear {
            startAffirmationCycle()
        }
        .onDisappear {
            stopAffirmationCycle()
            speechManager.stop()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(visionBoard.title)
                        .manifestationTitle()
                        .multilineTextAlignment(.leading)
                    
                    Text(visionBoard.description)
                        .manifestationBody()
                        .multilineTextAlignment(.leading)
                    
                    HStack(spacing: 16) {
                        InfoBadge(
                            icon: "calendar",
                            text: visionBoard.formattedCreatedDate
                        )
                        
                        InfoBadge(
                            icon: "eye.fill",
                            text: "\(visionBoard.viewCount) views"
                        )
                        
                        if visionBoard.isFavorite {
                            InfoBadge(
                                icon: "heart.fill",
                                text: "Favorite"
                            )
                        }
                    }
                }
                
                Spacer()
            }
            
            // Style and layout info
            HStack {
                StyleInfoCard(
                    title: "Style",
                    value: visionBoard.style.displayName,
                    color: visionBoard.style.primaryColor
                )
                
                StyleInfoCard(
                    title: "Layout",
                    value: visionBoard.layout.displayName,
                    color: .cosmicPurple
                )
                
                StyleInfoCard(
                    title: "Images",
                    value: "\(visionBoard.images.count)",
                    color: .cosmicBlue
                )
            }
        }
    }
    
    // MARK: - Vision Board Grid
    
    private var visionBoardGrid: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Personalized Vision")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.cosmicWhite)
                
                if visionBoard.isPersonalized {
                    PersonalizedBadge()
                }
                
                Spacer()
            }
            
            LazyVGrid(columns: gridColumns, spacing: 8) {
                ForEach(visionBoard.images) { image in
                    VisionBoardImageView(image: image) {
                        showingFullScreenImage = image
                    }
                }
            }
            .cosmicCard()
        }
    }
    
    private var gridColumns: [GridItem] {
        switch visionBoard.layout {
        case .grid3x3:
            return Array(repeating: GridItem(.flexible()), count: 3)
        case .collage:
            return Array(repeating: GridItem(.flexible()), count: 2)
        case .singlePoster:
            return [GridItem(.flexible())]
        }
    }
    
    // MARK: - Affirmations Section
    
    private var affirmationsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Affirmations")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.cosmicWhite)
                
                Spacer()

                Button("Read Aloud") {
                    speechManager.speak(visionBoard.affirmations[currentAffirmationIndex])
                }
                .font(.caption)
                .foregroundColor(.cosmicPurple)
            }
            
            if !visionBoard.affirmations.isEmpty {
                VStack(spacing: 12) {
                    // Current affirmation
                    Text(visionBoard.affirmations[currentAffirmationIndex])
                        .font(.title3)
                        .fontWeight(.medium)
                        .foregroundColor(.cosmicWhite)
                        .multilineTextAlignment(.center)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(
                                    LinearGradient(
                                        colors: [.cosmicPurple.opacity(0.3), .cosmicBlue.opacity(0.3)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )
                        .animation(.easeInOut(duration: 0.5), value: currentAffirmationIndex)
                    
                    // Affirmation indicators
                    HStack(spacing: 8) {
                        ForEach(0..<visionBoard.affirmations.count, id: \.self) { index in
                            Circle()
                                .fill(currentAffirmationIndex == index ? Color.cosmicGold : Color.gray)
                                .frame(width: 8, height: 8)
                                .animation(.easeInOut, value: currentAffirmationIndex)
                        }
                    }
                    
                    // All affirmations list
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(visionBoard.affirmations.indices, id: \.self) { index in
                            HStack {
                                Text("•")
                                    .foregroundColor(.cosmicGold)
                                
                                Text(visionBoard.affirmations[index])
                                    .font(.subheadline)
                                    .foregroundColor(.cosmicWhite.opacity(0.9))
                                
                                Spacer()
                            }
                        }
                    }
                    .padding()
                    .cosmicCard()
                }
            }
        }
    }
    
    // MARK: - Goals Section
    
    private var goalsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Manifestation Goals")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.cosmicWhite)
                
                Spacer()
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(visionBoard.manifestationGoals) { goal in
                    GoalCard(goal: goal.title)
                }
            }
        }
    }
    
    // MARK: - Actions Section
    
    private var actionsSection: some View {
        VStack(spacing: 16) {
            Text("Manifestation Actions")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.cosmicWhite)
            
            VStack(spacing: 12) {
                ActionButton(
                    icon: "heart.text.square.fill",
                    title: "Daily Visualization",
                    description: "Spend 5-10 minutes visualizing these images"
                ) {
                    scheduleDailyReminder()
                }
                
                ActionButton(
                    icon: "square.and.arrow.up",
                    title: "Share Your Vision",
                    description: "Share with friends for accountability"
                ) {
                    if let img = renderBoardImage() {
                        shareImage = img
                        showingImageShare = true
                    }
                }
                
                ActionButton(
                    icon: "photo",
                    title: "Set as Wallpaper",
                    description: "Keep your vision visible daily"
                ) {
                    if let img = renderBoardImage() {
                        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                    }
                }
                
                ActionButton(
                    icon: "printer.fill",
                    title: "Print Vision Board",
                    description: "Create a physical copy to display"
                ) {
                    // Print vision board
                }
            }
            .cosmicCard()
        }
    }
    
    // MARK: - Helper Methods

    private func startAffirmationCycle() {
        guard !visionBoard.affirmations.isEmpty else { return }
        affirmationTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(5))
                guard !Task.isCancelled else { break }
                await MainActor.run {
                    withAnimation { currentAffirmationIndex = (currentAffirmationIndex + 1) % visionBoard.affirmations.count }
                }
            }
        }
    }

    private func stopAffirmationCycle() {
        affirmationTask?.cancel()
        affirmationTask = nil
    }
    
    private func createShareableContent() -> String {
        var content = "Check out my personalized vision board: \(visionBoard.title)\n\n"
        content += "\(visionBoard.description)\n\n"
        content += "My affirmations:\n"

        for affirmation in visionBoard.affirmations {
            content += "• \(affirmation)\n"
        }

        content += "\nCreated with XVisionBoard AI - See yourself living your dreams!"
        return content
    }

    @MainActor
    private func renderBoardImage() -> UIImage? {
        let gridView = LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 4) {
            ForEach(visionBoard.images.prefix(9)) { img in
                VisionBoardImageView(image: img) { }
                    .frame(height: 120)
            }
        }
        .frame(width: 400)
        .background(Color.cosmicBlack)
        let renderer = ImageRenderer(content: gridView)
        renderer.scale = UIScreen.main.scale
        return renderer.uiImage
    }

    private func scheduleDailyReminder() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
            guard granted else { return }
            let content = UNMutableNotificationContent()
            content.title = "Time to Visualize 🌟"
            let affirmation = visionBoard.affirmations.randomElement() ?? "I am living my dream life"
            content.body = affirmation
            content.sound = .default

            var components = DateComponents()
            components.hour = 8
            components.minute = 0
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
            let request = UNNotificationRequest(
                identifier: "daily-visualization-\(visionBoard.id)",
                content: content,
                trigger: trigger
            )
            UNUserNotificationCenter.current().add(request)
        }
    }
}

// MARK: - Supporting Views

struct InfoBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.cosmicGold)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.cosmicWhite.opacity(0.8))
        }
    }
}

struct StyleInfoCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.cosmicWhite.opacity(0.7))
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.cosmicGray)
        )
    }
}

struct VisionBoardImageView: View {
    let image: VisionBoardImage
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                imageContent
                    .frame(minHeight: 100)
                    .clipped()
                
                if image.isPersonalized {
                    VStack {
                        HStack {
                            PersonalizedBadge()
                            Spacer()
                        }
                        Spacer()
                    }
                    .padding(4)
                }
            }
            .cornerRadius(8)
        }
    }

    @ViewBuilder
    private var imageContent: some View {
        if let uiImage = image.image {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else if let urlString = image.imageURL, let url = URL(string: urlString) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().aspectRatio(contentMode: .fill)
                default:
                    imagePlaceholder
                }
            }
        } else {
            imagePlaceholder
        }
    }

    private var imagePlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.cosmicGray)
            .overlay(ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .cosmicPurple)))
    }
}

struct GoalCard: View {
    let goal: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: "target")
                .foregroundColor(.cosmicGold)
            
            Text(goal)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.cosmicWhite)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cosmicGray)
        )
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.cosmicPurple)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.cosmicWhite)
                    
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.cosmicWhite.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.cosmicWhite.opacity(0.5))
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cosmicGray.opacity(0.5))
            )
        }
    }
}

struct FullScreenImageView: View {
    let image: VisionBoardImage
    let onDismiss: () -> Void

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            Group {
                if let uiImage = image.image {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else if let urlString = image.imageURL, let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable().aspectRatio(contentMode: .fit)
                        } else {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                    }
                }
            }
            .pinchToZoom()
            
            VStack {
                HStack {
                    Spacer()
                    
                    Button("Done") {
                        onDismiss()
                    }
                    .foregroundColor(.white)
                    .padding()
                }
                
                Spacer()
                
                if image.isPersonalized {
                    VStack(spacing: 8) {
                        PersonalizedBadge()
                        
                        Text("This is YOU living your dreams!")
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.black.opacity(0.7))
                            )
                    }
                    .padding(.bottom, 40)
                }
            }
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - View Extensions

private struct PinchToZoom: ViewModifier {
    @State private var scale: CGFloat = 1.0
    @State private var lastScale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        let delta = value / lastScale
                        lastScale = value
                        scale = min(max(scale * delta, 1.0), 5.0)
                    }
                    .onEnded { _ in
                        lastScale = 1.0
                    }
            )
    }
}

extension View {
    func pinchToZoom() -> some View {
        modifier(PinchToZoom())
    }
}

#Preview {
    VisionBoardDetailView(visionBoard: VisionBoard.sampleVisionBoard)
        .environment(VisionBoardManager())
}

