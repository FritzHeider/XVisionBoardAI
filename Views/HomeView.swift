//
//  HomeView.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import SwiftUI

struct HomeView: View {
    @Environment(UserManager.self) var userManager
    @Environment(VisionBoardManager.self) var visionBoardManager
    @Environment(StoreManager.self) var storeManager

    @State private var showingCreateView = false
    @State private var showingUpgradeView = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cosmicBlack.ignoresSafeArea()

                // Background radial glow
                RadialGradient(
                    colors: [Color.cosmicPurple.opacity(0.12), Color.clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: 400
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 28) {
                        headerSection
                        statsSection
                        createVisionBoardSection
                        if !visionBoardManager.recentVisionBoards.isEmpty {
                            recentVisionBoardsSection
                        }
                        manifestationTipsSection
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingCreateView) {
            CreateVisionBoardView()
        }
        .sheet(isPresented: $showingUpgradeView) {
            SubscriptionView()
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center, spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(timeGreeting)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundColor(.cosmicWhite.opacity(0.55))

                Text(userManager.currentUser?.username ?? "Dreamer")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.cosmicWhite, .cosmicPurple.opacity(0.9)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )

                subscriptionBadge
            }

            Spacer()

            avatarView
        }
    }

    private var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good morning ✦"
        case 12..<17: return "Good afternoon ✦"
        case 17..<21: return "Good evening ✦"
        default: return "Good night ✦"
        }
    }

    @ViewBuilder
    private var avatarView: some View {
        ZStack {
            Circle()
                .stroke(Color.cosmicGradient, lineWidth: 2.5)
                .frame(width: 56, height: 56)

            if let profileImage = userManager.currentUser?.profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.cosmicPurple.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay(
                        Image(systemName: "person.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundColor(.cosmicPurple)
                    )
            }
        }
        .shadow(color: .cosmicPurple.opacity(0.4), radius: 8, x: 0, y: 4)
    }

    private var subscriptionBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: storeManager.hasActiveSubscription ? "crown.fill" : "sparkle")
                .font(.caption)
                .foregroundColor(storeManager.hasActiveSubscription ? .cosmicGold : .cosmicWhite.opacity(0.5))

            Text(storeManager.subscriptionDisplayName)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundColor(storeManager.hasActiveSubscription ? .cosmicGold : .cosmicWhite.opacity(0.6))

            if !storeManager.hasActiveSubscription {
                Button("Upgrade") {
                    showingUpgradeView = true
                }
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .padding(.horizontal, 10)
                .padding(.vertical, 3)
                .background(Color.cosmicGold)
                .foregroundColor(.black)
                .clipShape(Capsule())
            }
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: 12) {
            StatCard(
                title: "Boards",
                value: "\(visionBoardManager.totalVisionBoards)",
                icon: "photo.stack.fill",
                color: .cosmicPurple
            )

            StatCard(
                title: "Total Views",
                value: "\(visionBoardManager.totalViews)",
                icon: "eye.fill",
                color: .cosmicBlue
            )

            StatCard(
                title: "Remaining",
                value: storeManager.maxVisionBoards() == -1
                    ? "∞"
                    : "\(max(0, storeManager.maxVisionBoards() - visionBoardManager.totalVisionBoards))",
                icon: "plus.circle.fill",
                color: .cosmicGold
            )
        }
    }

    // MARK: - Create Section

    private var createVisionBoardSection: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Create Personalized\nVision Board")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundColor(.cosmicWhite)
                    .multilineTextAlignment(.center)

                Text("A selfie + your goals → AI places you living your dreams")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(.cosmicWhite.opacity(0.65))
                    .multilineTextAlignment(.center)
            }
            .padding(.top, 4)

            VStack(spacing: 14) {
                benefitRow(icon: "heart.fill", color: .cosmicPink,
                           title: "Emotional Connection",
                           detail: "Seeing yourself makes dreams feel achievable")
                benefitRow(icon: "brain.head.profile", color: .cosmicPurple,
                           title: "Subconscious Programming",
                           detail: "Your brain recognizes you in success scenarios")
                benefitRow(icon: "bolt.fill", color: .cosmicGold,
                           title: "Faster Results",
                           detail: "Studies show 3× acceleration in manifestation")
            }
            .padding(18)
            .cosmicGlowCard(color: .cosmicPurple)

            ZStack {
                // Glow halo behind button
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [Color.cosmicPurple.opacity(0.45), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 80
                        )
                    )
                    .frame(width: 260, height: 60)
                    .blur(radius: 18)

                Button("Start with Your Selfie") {
                    if storeManager.canCreateVisionBoard(currentCount: visionBoardManager.totalVisionBoards) {
                        showingCreateView = true
                    } else {
                        showingUpgradeView = true
                    }
                }
                .cosmicButton()
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func benefitRow(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundColor(.cosmicWhite)
                Text(detail)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.cosmicWhite.opacity(0.65))
            }

            Spacer()
        }
    }

    // MARK: - Recent Vision Boards

    private var recentVisionBoardsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Recent Boards")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundColor(.cosmicWhite)

                Spacer()

                NavigationLink("See All") {
                    VisionBoardGalleryView()
                }
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(colors: [.cosmicPurple, .cosmicBlue], startPoint: .leading, endPoint: .trailing)
                )
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 14) {
                    ForEach(visionBoardManager.recentVisionBoards) { visionBoard in
                        VisionBoardCard(visionBoard: visionBoard)
                            .frame(width: 180)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    // MARK: - Tips Section

    private var manifestationTipsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Daily Practice")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundColor(.cosmicWhite)

            VStack(spacing: 14) {
                benefitRow(icon: "clock.fill", color: .cosmicBlue,
                           title: "Daily Visualization",
                           detail: "Spend 5–10 min each morning viewing your boards")
                benefitRow(icon: "heart.text.square.fill", color: .cosmicPink,
                           title: "Feel the Emotions",
                           detail: "Experience joy and excitement of achieving your goals")
                benefitRow(icon: "target", color: .cosmicPurple,
                           title: "Take Inspired Action",
                           detail: "Let your vision boards guide your daily decisions")
            }
            .padding(18)
            .cosmicCard()
        }
    }
}

// MARK: - Supporting Views

struct IconRow: View {
    let icon: String
    let title: String
    let description: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(iconColor.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundColor(.cosmicWhite)
                Text(description)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.cosmicWhite.opacity(0.65))
            }

            Spacer()
        }
    }
}

struct VisionBoardCard: View {
    let visionBoard: VisionBoard
    @Environment(VisionBoardManager.self) var visionBoardManager

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Preview image
            ZStack(alignment: .bottomLeading) {
                if let firstImage = visionBoard.images.first?.image {
                    Image(uiImage: firstImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(height: 130)
                        .clipped()
                } else {
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [Color.cosmicPurple.opacity(0.4), Color.cosmicBlue.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 130)
                        .overlay(
                            Image(systemName: "photo.fill")
                                .font(.title2)
                                .foregroundColor(.cosmicWhite.opacity(0.35))
                        )
                }

                // Gradient scrim
                LinearGradient(
                    colors: [Color.black.opacity(0.6), Color.clear],
                    startPoint: .bottom,
                    endPoint: .top
                )
                .frame(height: 60)

                if visionBoard.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundColor(.cosmicPink)
                        .padding(8)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(visionBoard.title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundColor(.cosmicWhite)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 10))
                        .foregroundColor(.cosmicBlue.opacity(0.8))
                    Text("\(visionBoard.viewCount)")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.cosmicWhite.opacity(0.55))
                    Spacer()
                    Text(visionBoard.formattedCreatedDate)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundColor(.cosmicWhite.opacity(0.45))
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, 10)
            .padding(.bottom, 4)
        }
        .padding(10)
        .cosmicCard()
        .onTapGesture {
            visionBoardManager.incrementViewCount(visionBoard)
        }
    }
}

#Preview {
    HomeView()
        .environment(UserManager())
        .environment(VisionBoardManager())
        .environment(StoreManager())
}
