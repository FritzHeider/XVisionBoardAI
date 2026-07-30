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
import Photos

struct VisionBoardDetailView: View {
    let visionBoard: VisionBoard
    @Environment(\.dismiss) private var dismiss
    @Environment(VisionBoardManager.self) var visionBoardManager
    /// Needed for the user's chosen daily-reminder time.
    @Environment(UserManager.self) var userManager
    /// Gates the two Pro export/audio promises made on the paywall.
    @Environment(StoreManager.self) var storeManager
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var speechManager = SpeechManager()
    @State private var showingUpgrade = false
    @State private var showingEditView = false
    @State private var showingShareSheet = false
    @State private var showingDeleteAlert = false
    @State private var shareImage: UIImage?
    @State private var showingImageShare = false
    @State private var showingFullScreenImage: VisionBoardImage?
    @State private var currentAffirmationIndex = 0
    @State private var affirmationTask: Task<Void, Never>?
    @State private var actionFeedback: String?
    
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
                ToolbarItem(placement: .topBarLeading) {
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
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu("Options", systemImage: "ellipsis.circle") {
                        Button("Edit Vision Board", systemImage: "pencil", action: { showingEditView = true })

                        // Read through currentBoard, not the `visionBoard` snapshot:
                        // toggleFavorite mutates the stored copy, so a snapshot-driven
                        // label never updates and the button reads "Add to Favorites"
                        // even after the board has been favorited.
                        Button(
                            currentBoard.isFavorite ? "Remove from Favorites" : "Add to Favorites",
                            systemImage: currentBoard.isFavorite ? "heart.slash" : "heart",
                            action: { visionBoardManager.toggleFavorite(currentBoard) }
                        )

                        Button("Share", systemImage: "square.and.arrow.up", action: { showingShareSheet = true })

                        Button("Delete", systemImage: "trash", role: .destructive, action: { showingDeleteAlert = true })
                    }
                    .labelStyle(.iconOnly)
                    .foregroundStyle(Color.astralText)
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
        .alert("Manifestation Actions", isPresented: Binding(
            get: { actionFeedback != nil },
            set: { if !$0 { actionFeedback = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(actionFeedback ?? "")
        }
        .sheet(isPresented: $showingUpgrade) { SubscriptionView() }
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
                            text: "\(currentBoard.viewCount) views"
                        )

                        if currentBoard.isFavorite {
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
                ForEach(currentBoard.images) { image in
                    VisionBoardImageView(
                        image: image,
                        action: { showingFullScreenImage = image },
                        onRetry: {
                            Task {
                                await visionBoardManager.regenerateImage(
                                    boardID: currentBoard.id,
                                    imageID: image.id
                                )
                            }
                        }
                    )
                }
            }
            .cosmicCard()
        }
    }
    
    private var gridColumns: [GridItem] {
        let base: Int
        switch visionBoard.layout {
        case .grid3x3: base = 3
        case .collage: base = 2
        case .singlePoster: base = 1
        }
        let count = sizeClass == .regular && base > 1 ? base + 1 : base
        return Array(repeating: GridItem(.flexible()), count: count)
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

                // "Audio affirmations" is sold as a Pro feature, so it is gated
                // here rather than being silently free.
                Button {
                    guard !visionBoard.affirmations.isEmpty else { return }
                    guard storeManager.canUseAudioAffirmations() else {
                        showingUpgrade = true
                        return
                    }
                    speechManager.speak(visionBoard.affirmations[currentAffirmationIndex])
                } label: {
                    HStack(spacing: 4) {
                        Text("Read Aloud")
                        if !storeManager.canUseAudioAffirmations() {
                            Image(systemName: "crown.fill")
                                .scaledFont(size: 9, relativeTo: .caption2)
                                .foregroundStyle(Color.astralGold)
                        }
                    }
                }
                .font(.caption)
                .foregroundStyle(Color.astralViolet)
            }
            
            if !visionBoard.affirmations.isEmpty {
                VStack(spacing: 16) {
                    // Current affirmation hero card
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .scaledFont(size: 20, relativeTo: .body, weight: .semibold)
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
                    } else {
                        actionFeedback = "Couldn't render your board image. Please try again."
                    }
                }

                actionRow(icon: "photo.fill", iconColor: .cosmicPink,
                          title: "Set as Wallpaper",
                          description: "Keep your vision visible daily") {
                    saveWallpaperToPhotos()
                }

                actionRow(icon: "printer.fill", iconColor: .cosmicGold,
                          title: "Print Vision Board",
                          description: "Create a physical copy to display") {
                    printBoard()
                }
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
                        .scaledFont(size: 17, relativeTo: .subheadline, weight: .semibold)
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
                    .scaledFont(size: 12, relativeTo: .caption, weight: .semibold)
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

        content += "\nCreated with ManifestMe - See yourself living your dreams!"
        return content
    }

    /// The single render path behind Share, Set as Wallpaper, and Print.
    ///
    /// The paywall promises Pro users "HD Export" and free users "Watermarked
    /// exports" at "Standard resolution". Both halves of that promise are
    /// enforced here, so App Review can verify the difference by purchasing in
    /// sandbox and exporting the same board twice.
    ///
    /// Rows are built with a plain VStack/HStack rather than LazyVGrid: at HD
    /// size most tiles sit outside the visible bounds, and `ImageRenderer` is
    /// not guaranteed to materialize lazy content it thinks is offscreen.
    @MainActor
    private func renderBoardImage() -> UIImage? {
        let isHD = storeManager.canExportHD()
        let width: CGFloat = isHD ? 1200 : 400
        let spacing: CGFloat = isHD ? 12 : 4
        let tileHeight: CGFloat = isHD ? 360 : 120
        let tiles = Array(visionBoard.images.prefix(9))
        let rows = stride(from: 0, to: tiles.count, by: 3).map { start in
            Array(tiles[start..<min(start + 3, tiles.count)])
        }

        let boardView = VStack(spacing: spacing) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: spacing) {
                    ForEach(row) { img in
                        VisionBoardImageView(image: img) { }
                            .frame(height: tileHeight)
                    }
                    // Keep a short final row left-aligned instead of stretched.
                    if row.count < 3 {
                        ForEach(0..<(3 - row.count), id: \.self) { _ in
                            Color.clear.frame(height: tileHeight)
                        }
                    }
                }
            }
        }
        .frame(width: width)
        .background(Color.cosmicBlack)
        .overlay(alignment: .bottom) {
            if !isHD { exportWatermark(width: width) }
        }

        let renderer = ImageRenderer(content: boardView)
        renderer.scale = UITraitCollection.current.displayScale
        return renderer.uiImage
    }

    /// Burned into free-tier exports. Sized relative to the render width so it
    /// stays legible at whatever resolution the tier renders at.
    private func exportWatermark(width: CGFloat) -> some View {
        HStack(spacing: width * 0.015) {
            Image(systemName: "sparkles")
            Text("Made with ManifestMe")
        }
        // Deliberately a fixed size, not `scaledFont`: an exported image must
        // not change dimensions with the reader's Dynamic Type setting.
        .font(.system(size: width * 0.034, weight: .semibold, design: .rounded))
        .foregroundStyle(Color.white.opacity(0.92))
        .padding(.horizontal, width * 0.032)
        .padding(.vertical, width * 0.018)
        .background(Capsule().fill(Color.black.opacity(0.55)))
        .padding(.bottom, width * 0.03)
    }

    private func saveWallpaperToPhotos() {
        guard let img = renderBoardImage() else {
            actionFeedback = "Couldn't render your board image. Please try again."
            return
        }
        Task {
            do {
                try await PHPhotoLibrary.shared().performChanges {
                    PHAssetChangeRequest.creationRequestForAsset(from: img)
                }
                actionFeedback = "Saved to Photos! Open the Photos app to set it as your wallpaper."
            } catch {
                actionFeedback = "Couldn't save to Photos. Check photo access for ManifestMe in Settings."
            }
        }
    }

    private func printBoard() {
        guard let img = renderBoardImage() else {
            actionFeedback = "Couldn't render your board image. Please try again."
            return
        }
        let printInfo = UIPrintInfo(dictionary: nil)
        printInfo.outputType = .photo
        printInfo.jobName = currentBoard.title
        let controller = UIPrintInteractionController.shared
        controller.printInfo = printInfo
        controller.printingItem = img

        let completion: UIPrintInteractionController.CompletionHandler = { _, completed, error in
            if let error, !completed {
                actionFeedback = "Couldn't print: \(error.localizedDescription)"
            }
        }

        // On iPad the print controller must be presented as a popover from an
        // anchor; the iPhone-style present() throws NSInternalInconsistencyException.
        if UIDevice.current.userInterfaceIdiom == .pad,
           let anchorView = Self.keyWindow {
            let bounds = anchorView.bounds
            let anchor = CGRect(x: bounds.midX, y: bounds.midY, width: 1, height: 1)
            controller.present(from: anchor, in: anchorView, animated: true, completionHandler: completion)
        } else {
            controller.present(animated: true, completionHandler: completion)
        }
    }

    private static var keyWindow: UIWindow? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first(where: \.isKeyWindow)
    }

    private func scheduleDailyReminder() {
        Task {
            let granted = (try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])) ?? false
            guard granted else {
                actionFeedback = "Notifications are disabled. Enable them for ManifestMe in Settings to get daily reminders."
                return
            }
            let content = UNMutableNotificationContent()
            content.title = "Time to Visualize 🌟"
            let affirmation = visionBoard.affirmations.randomElement() ?? "I am living my dream life"
            content.body = affirmation
            content.sound = .default

            // Use the time the user actually picked in Profile. This was hardcoded
            // to 08:00, so the Profile reminder-time picker silently did nothing.
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: userManager.reminderComponents,
                repeats: true
            )
            let request = UNNotificationRequest(
                identifier: "daily-visualization-\(visionBoard.id)",
                content: content,
                trigger: trigger
            )
            do {
                try await UNUserNotificationCenter.current().add(request)
                actionFeedback = "Daily reminder set! You'll get a visualization nudge every day at \(userManager.formattedReminderTime)."
            } catch {
                actionFeedback = "Couldn't schedule the reminder: \(error.localizedDescription)"
            }
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
    var onRetry: (() -> Void)? = nil

    @State private var isRetrying = false

    /// True when generation finished without producing anything — nothing on
    /// disk, nothing to download. Distinct from "still loading".
    private var generationFailed: Bool {
        image.image == nil && image.imageURL == nil
    }

    var body: some View {
        Group {
            if generationFailed, let onRetry {
                Button {
                    isRetrying = true
                    onRetry()
                } label: {
                    failedPlaceholder
                }
                .disabled(isRetrying)
                .accessibilityLabel("Image generation failed. Retry")
            } else {
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
                    .clipShape(.rect(cornerRadius: 8))
                }
                .accessibilityLabel("Vision board image: \(image.prompt)")
            }
        }
        .onChange(of: image.imageFilename) { _, _ in isRetrying = false }
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
            .overlay(ProgressView().progressViewStyle(.circular).tint(.astralViolet))
    }

    private var failedPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.cosmicGray)
            .frame(minHeight: 100)
            .overlay {
                VStack(spacing: 6) {
                    if isRetrying {
                        ProgressView().progressViewStyle(.circular).tint(.astralViolet)
                    } else {
                        Image(systemName: "arrow.clockwise.circle.fill")
                            .scaledFont(size: 26, relativeTo: .title3)
                            .foregroundStyle(Color.astralViolet)
                        Text("Retry")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(Color.astralTextMuted)
                    }
                }
            }
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
                        .scaledFont(size: 10, relativeTo: .caption2, weight: .bold, design: .rounded)
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
                            ProgressView().progressViewStyle(.circular).tint(.white)
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

    private static let minScale: CGFloat = 1.0
    private static let maxScale: CGFloat = 5.0
    private static let step: CGFloat = 1.5

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        let delta = value / lastScale
                        lastScale = value
                        scale = min(max(scale * delta, Self.minScale), Self.maxScale)
                    }
                    .onEnded { _ in
                        lastScale = 1.0
                    }
            )
            // Double-tap works for anyone who can't perform a two-finger pinch.
            .onTapGesture(count: 2) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    scale = scale > Self.minScale ? Self.minScale : 2.5
                }
            }
            // Zoom was pinch-only, so it was unreachable via VoiceOver and Switch
            // Control (WCAG 2.5.1). These surface it in the VoiceOver rotor.
            .accessibilityAction(named: "Zoom In") {
                scale = min(scale * Self.step, Self.maxScale)
            }
            .accessibilityAction(named: "Zoom Out") {
                scale = max(scale / Self.step, Self.minScale)
            }
            .accessibilityAction(named: "Reset Zoom") {
                scale = Self.minScale
            }
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
        .environment(UserManager())
}

