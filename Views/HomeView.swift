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
                Color.astralBlack.ignoresSafeArea()

                // Ambient glow
                ZStack {
                    Ellipse()
                        .fill(Color.astralViolet.opacity(0.13))
                        .frame(width: 340, height: 340)
                        .blur(radius: 90)
                        .offset(x: 80, y: -160)

                    Ellipse()
                        .fill(Color.astralIndigo.opacity(0.09))
                        .frame(width: 280, height: 280)
                        .blur(radius: 80)
                        .offset(x: -100, y: 100)
                }
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AstralTheme.Spacing.xl) {
                        headerSection
                        statsSection
                        createSection
                        if !visionBoardManager.recentVisionBoards.isEmpty {
                            recentSection
                        }
                        dailyPracticeSection
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, AstralTheme.Spacing.lg)
                    .padding(.top, AstralTheme.Spacing.sm)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .sheet(isPresented: $showingCreateView) { CreateVisionBoardView() }
        .sheet(isPresented: $showingUpgradeView) { SubscriptionView() }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack(alignment: .center, spacing: AstralTheme.Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text(timeGreeting)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(Color.astralTextMuted)

                Text(userManager.currentUser?.username ?? "Dreamer")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.auroraGradient)

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
                .strokeBorder(Color.auroraGradient, lineWidth: 2.5)
                .frame(width: 56, height: 56)

            if let profileImage = userManager.currentUser?.profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.astralViolet.opacity(0.2))
                    .frame(width: 50, height: 50)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(Color.astralViolet)
                    }
            }
        }
        .shadow(color: .astralViolet.opacity(0.4), radius: 10, x: 0, y: 4)
    }

    private var subscriptionBadge: some View {
        HStack(spacing: 6) {
            Image(systemName: storeManager.hasActiveSubscription ? "crown.fill" : "sparkle")
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(storeManager.hasActiveSubscription ? Color.astralGold : Color.astralTextMuted)

            Text(storeManager.subscriptionDisplayName)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(storeManager.hasActiveSubscription ? Color.astralGold : Color.astralTextMuted)

            if !storeManager.hasActiveSubscription {
                Button("Upgrade") { showingUpgradeView = true }
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 3)
                    .background(Color.astralGold)
                    .foregroundStyle(Color.black)
                    .clipShape(Capsule())
            }
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: AstralTheme.Spacing.sm) {
            StatCard(title: "Boards", value: "\(visionBoardManager.totalVisionBoards)",
                     icon: "photo.stack.fill", color: .astralViolet)
            StatCard(title: "Total Views", value: "\(visionBoardManager.totalViews)",
                     icon: "eye.fill", color: .astralIndigo)
            StatCard(
                title: "Remaining",
                value: storeManager.maxVisionBoards() == -1
                    ? "∞"
                    : "\(max(0, storeManager.maxVisionBoards() - visionBoardManager.totalVisionBoards))",
                icon: "plus.circle.fill",
                color: .astralGold
            )
        }
    }

    // MARK: - Create Section

    private var createSection: some View {
        VStack(spacing: AstralTheme.Spacing.lg) {
            VStack(spacing: AstralTheme.Spacing.xs) {
                Text("Create Personalized\nVision Board")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.astralText)
                    .multilineTextAlignment(.center)

                Text("A selfie + your goals → AI places you living your dreams")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.astralTextMuted)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: AstralTheme.Spacing.md) {
                benefitRow(icon: "heart.fill", color: .astralRose,
                           title: "Emotional Connection",
                           detail: "Seeing yourself makes dreams feel achievable")
                benefitRow(icon: "brain.head.profile", color: .astralViolet,
                           title: "Subconscious Programming",
                           detail: "Your brain recognizes you in success scenarios")
                benefitRow(icon: "bolt.fill", color: .astralGold,
                           title: "Faster Results",
                           detail: "Studies show 3× acceleration in manifestation")
            }
            .padding(AstralTheme.Spacing.lg)
            .astralGlass(tint: .astralViolet)

            // CTA with glow halo
            ZStack {
                Ellipse()
                    .fill(
                        RadialGradient(
                            colors: [Color.astralViolet.opacity(0.40), Color.clear],
                            center: .center, startRadius: 0, endRadius: 80
                        )
                    )
                    .frame(width: 260, height: 60)
                    .blur(radius: 20)

                Button("Start with Your Selfie") {
                    if storeManager.canCreateVisionBoard(currentCount: visionBoardManager.totalVisionBoards) {
                        showingCreateView = true
                    } else {
                        showingUpgradeView = true
                    }
                }
                .astralButton(.primary)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func benefitRow(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(spacing: AstralTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AstralTheme.Radius.sm)
                    .fill(color.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.astralText)
                Text(detail)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Color.astralTextMuted)
            }

            Spacer()
        }
    }

    // MARK: - Recent Vision Boards

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: AstralTheme.Spacing.md) {
            HStack {
                Text("Recent Boards")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.astralText)

                Spacer()

                NavigationLink("See All") { VisionBoardGalleryView() }
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.auroraGradient)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AstralTheme.Spacing.md) {
                    ForEach(visionBoardManager.recentVisionBoards) { board in
                        VisionBoardCard(visionBoard: board)
                            .frame(width: 180)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    // MARK: - Daily Practice

    private var dailyPracticeSection: some View {
        VStack(alignment: .leading, spacing: AstralTheme.Spacing.md) {
            Text("Daily Practice")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(Color.astralText)

            VStack(spacing: AstralTheme.Spacing.md) {
                benefitRow(icon: "clock.fill", color: .astralIndigo,
                           title: "Daily Visualization",
                           detail: "Spend 5–10 min each morning viewing your boards")
                benefitRow(icon: "heart.text.square.fill", color: .astralRose,
                           title: "Feel the Emotions",
                           detail: "Experience joy and excitement of achieving your goals")
                benefitRow(icon: "target", color: .astralViolet,
                           title: "Take Inspired Action",
                           detail: "Let your vision boards guide your daily decisions")
            }
            .padding(AstralTheme.Spacing.lg)
            .astralCard()
        }
    }
}

// MARK: - VisionBoardCard

struct VisionBoardCard: View {
    let visionBoard: VisionBoard
    @Environment(VisionBoardManager.self) var visionBoardManager
    @State private var showingDetail = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
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
                                colors: [Color.astralViolet.opacity(0.4), Color.astralIndigo.opacity(0.3)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 130)
                        .overlay {
                            Image(systemName: "photo.fill")
                                .font(.title2)
                                .foregroundStyle(Color.astralTextDim)
                        }
                }

                // Scrim
                LinearGradient(
                    colors: [Color.black.opacity(0.6), Color.clear],
                    startPoint: .bottom, endPoint: .top
                )
                .frame(height: 60)

                if visionBoard.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.caption)
                        .foregroundStyle(Color.astralRose)
                        .padding(8)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: AstralTheme.Radius.md, style: .continuous))

            VStack(alignment: .leading, spacing: 4) {
                Text(visionBoard.title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.astralText)
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Image(systemName: "eye.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.astralIndigo.opacity(0.8))
                    Text("\(visionBoard.viewCount)")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(Color.astralTextMuted)
                    Spacer()
                    Text(visionBoard.formattedCreatedDate)
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(Color.astralTextDim)
                }
            }
            .padding(.horizontal, 4)
            .padding(.top, AstralTheme.Spacing.sm)
            .padding(.bottom, 4)
        }
        .padding(AstralTheme.Spacing.sm)
        .astralCard()
        .onTapGesture {
            visionBoardManager.incrementViewCount(visionBoard)
            showingDetail = true
        }
        .sheet(isPresented: $showingDetail) {
            VisionBoardDetailView(visionBoard: visionBoard)
        }
    }
}

// MARK: - IconRow (shared utility)

struct IconRow: View {
    let icon: String
    let title: String
    let description: String
    let iconColor: Color

    var body: some View {
        HStack(spacing: AstralTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AstralTheme.Radius.sm)
                    .fill(iconColor.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.astralText)
                Text(description)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Color.astralTextMuted)
            }

            Spacer()
        }
    }
}

#Preview {
    HomeView()
        .environment(UserManager())
        .environment(VisionBoardManager())
        .environment(StoreManager())
}
