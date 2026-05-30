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
    
    private var currentBoard: VisionBoard {
        visionBoardManager.visionBoards.first { $0.id == visionBoard.id } ?? visionBoard
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.astralBlack.ignoresSafeArea()
                
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
                    .foregroundStyle(Color.astralText)
                }
                
                ToolbarItem(placement: .principal) {
                    Text(visionBoard.title)
                        .font(.headline)
                        .foregroundStyle(Color.astralText)
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
                            .foregroundStyle(Color.astralText)
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            EditVisionBoardView(visionBoard: visionBoard)
        }
        .sheet(isPresented: $showingShareSheet) {
            ShareSheet(items: shareableItems())
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
                    .foregroundStyle(Color.astralText)
                
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
                    .foregroundStyle(Color.astralText)
                
                Spacer()

                Button("Read Aloud") {
                    guard !visionBoard.affirmations.isEmpty else { return }
                    speechManager.speak(visionBoard.affirmations[currentAffirmationIndex])
                }
                .font(.caption)
                .foregroundStyle(Color.astralViolet)
            }
            
            if !visionBoard.affirmations.isEmpty {
                VStack(spacing: 16) {
                    // Current affirmation hero card
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(
                                LinearGradient(colors: [.cosmicGold, .cosmicPurple], startPoint: .leading, endPoint: .trailing)
                            )

                        Text(visionBoard.affirmations[currentAffirmationIndex])
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .foregroundStyle(Color.astralText)
                            .multilineTextAlignment(.center)
                            .transition(.opacity.combined(with: .scale(scale: 0.97)))
                            .id(currentAffirmationIndex)
                    }
                    .padding(24)
                    .frame(maxWidth: .infinity)
                    .cosmicGlowCard(color: .cosmicPurple)
                    .animation(.easeInOut(duration: 0.4), value: currentAffirmationIndex)

                    // Page dots
                    HStack(spacing: 6) {
                        ForEach(0..<visionBoard.affirmations.count, id: \.self) { index in
                            Capsule()
                                .fill(currentAffirmationIndex == index ? Color.cosmicGold : Color.cosmicWhite.opacity(0.25))
                                .frame(width: currentAffirmationIndex == index ? 20 : 6, height: 6)
                                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentAffirmationIndex)
                        }
                    }

                    // All affirmations list
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(visionBoard.affirmations.indices, id: \.self) { index in
                            HStack(alignment: .top, spacing: 10) {
                                Circle()
                                    .fill(Color.cosmicGold.opacity(0.7))
                                    .frame(width: 6, height: 6)
                                    .padding(.top, 6)

                                Text(visionBoard.affirmations[index])
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(Color.astralText.opacity(0.88))

                                Spacer()
                            }
                        }
                    }
                    .padding(18)
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
                    .foregroundStyle(Color.astralText)

                Spacer()

                let achieved = currentBoard.manifestationGoals.filter { $0.isAchieved }.count
                let total = currentBoard.manifestationGoals.count
                if total > 0 {
                    Text("\(achieved)/\(total)")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color.astralGold)
                }
            }

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(currentBoard.manifestationGoals) { goal in
                    Button {
                        visionBoardManager.toggleGoalAchieved(goal, in: visionBoard.id)
                    } label: {
                        GoalCard(goal: goal.title, isAchieved: goal.isAchieved)
                    }
                }
            }
        }
    }
    
    // MARK: - Actions Section

    private var actionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Manifestation Actions")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(Color.astralText)

            VStack(spacing: 0) {
                actionRow(icon: "bell.badge.fill", iconColor: .cosmicPurple,
                          title: "Daily Reminder",
                          description: "Get a daily nudge to visualize") {
                    scheduleDailyReminder()
                }

                actionRow(icon: "square.and.arrow.up.fill", iconColor: .cosmicBlue,
                          title: "Share Your Vision",
                          description: "Share with friends for accountability") {
                    if let img = renderBoardImage() {
                        shareImage = img
                        showingImageShare = true
                    }
                }

                actionRow(icon: "photo.fill", iconColor: .cosmicPink,
                          title: "Set as Wallpaper",
                          description: "Keep your vision visible daily") {
                    if let img = renderBoardImage() {
                        UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                    }
                }

                actionRow(icon: "printer.fill", iconColor: .cosmicGold,
                          title: "Print Vision Board",
                          description: "Create a physical copy to display") { }
            }
            .cosmicCard()
        }
    }

    private func actionRow(icon: String, iconColor: Color, title: String, description: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(iconColor.opacity(0.18))
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color.astralText)
                    Text(description)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Color.astralText.opacity(0.55))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.astralText.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.cosmicWhite.opacity(0.06))
                .frame(height: 0.5)
                .padding(.leading, 70)
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
    
    @MainActor
    private func shareableItems() -> [Any] {
        var items: [Any] = []
        if let img = renderBoardImage() { items.append(img) }
        items.append(createShareableContent())
        return items
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
        renderer.scale = UITraitCollection.current.displayScale
        return renderer.uiImage
    }

    private func scheduleDailyReminder() {
        Task {
            let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])) ?? false
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
            try? await UNUserNotificationCenter.current().add(request)
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
                .foregroundStyle(Color.astralGold)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(Color.astralText.opacity(0.8))
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
                .foregroundStyle(Color.astralText.opacity(0.7))
            
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(color)
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
    var isAchieved: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: isAchieved ? "checkmark.circle.fill" : "target")
                    .foregroundStyle(isAchieved ? Color.astralSuccess : Color.astralGold)
                Spacer()
                if isAchieved {
                    Text("Done")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.black)
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(Capsule().fill(Color.astralSuccess))
                }
            }

            Text(goal)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(isAchieved ? Color.astralTextMuted : Color.astralText)
                .multilineTextAlignment(.leading)
                .strikethrough(isAchieved, color: .astralTextMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background {
            RoundedRectangle(cornerRadius: 12)
                .fill(isAchieved ? Color.astralSuccess.opacity(0.10) : Color.astralSurface)
                .overlay {
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isAchieved ? Color.astralSuccess.opacity(0.4) : Color.white.opacity(0.07),
                            lineWidth: 1
                        )
                }
        }
        .animation(AstralTheme.Motion.quick, value: isAchieved)
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
                    .foregroundStyle(.white)
                    .padding()
                }
                
                Spacer()
                
                if image.isPersonalized {
                    VStack(spacing: 8) {
                        PersonalizedBadge()
                        
                        Text("This is YOU living your dreams!")
                            .font(.subheadline)
                            .foregroundStyle(.white)
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

