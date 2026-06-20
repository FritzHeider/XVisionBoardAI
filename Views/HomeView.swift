import SwiftUI

struct HomeView: View {
    @Environment(UserManager.self) var userManager
    @Environment(VisionBoardManager.self) var visionBoardManager
    @Environment(StoreManager.self) var storeManager
    @Environment(\.horizontalSizeClass) private var sizeClass

    @State private var showingCreateView = false
    @State private var showingUpgradeView = false
    @State private var showingInsightSheet = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.astralBlack.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AstralTheme.Spacing.xl) {
                        headerSection
                        statsStrip
                        affirmationCard
                        if userManager.hasPendingInsight {
                            insightCard
                        }
                        createSection
                        if !visionBoardManager.recentVisionBoards.isEmpty {
                            recentSection
                        }
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, AstralTheme.Spacing.lg)
                    .padding(.top, AstralTheme.Spacing.sm)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { userManager.recordDailyVisit() }
        }
        .sheet(isPresented: $showingCreateView) { CreateVisionBoardView() }
        .sheet(isPresented: $showingUpgradeView) { SubscriptionView() }
        .sheet(isPresented: $showingInsightSheet) {
            InsightAnswerSheet(
                question: userManager.nextInsightQuestion,
                onSave: { answer in
                    userManager.addInsight(question: userManager.nextInsightQuestion, answer: answer)
                }
            )
        }
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

    // MARK: - Weekly Insight Card

    private var insightCard: some View {
        Button { showingInsightSheet = true } label: {
            VStack(alignment: .leading, spacing: AstralTheme.Spacing.sm) {
                HStack {
                    Text("WEEKLY REFLECTION")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundStyle(Color.astralRose)
                        .tracking(1.2)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.astralTextDim)
                }

                Text(userManager.nextInsightQuestion)
                    .font(.system(.subheadline, design: .serif, weight: .medium))
                    .foregroundStyle(Color.astralText)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Tap to reflect →")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(Color.astralRose.opacity(0.8))
            }
            .padding(AstralTheme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: AstralTheme.Radius.lg, style: .continuous)
                    .fill(Color.astralRose.opacity(0.1))
                    .overlay(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.astralRose)
                            .frame(width: 3)
                            .padding(.vertical, 12)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: AstralTheme.Radius.lg, style: .continuous)
                            .strokeBorder(Color.astralRose.opacity(0.2), lineWidth: 1)
                    }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Stats Strip (clean horizontal metrics — no icon-in-circle grid)

    private var statsStrip: some View {
        let remaining = storeManager.maxVisionBoards() == -1
            ? "∞"
            : "\(max(0, storeManager.maxVisionBoards() - visionBoardManager.totalVisionBoards))"
        let streakVal = "\(userManager.currentStreak)\(userManager.currentStreak > 0 ? " 🔥" : "")"

        return HStack(spacing: 0) {
            metricCell(value: "\(visionBoardManager.totalVisionBoards)", label: "Boards")
            metricDivider
            metricCell(value: streakVal, label: "Day Streak")
            metricDivider
            metricCell(value: remaining, label: "Remaining")
        }
        .padding(.vertical, AstralTheme.Spacing.md)
        .astralCard()
    }

    private func metricCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(Color.astralText)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.astralTextMuted)
                .textCase(.uppercase)
                .tracking(0.8)
        }
        .frame(maxWidth: .infinity)
    }

    private var metricDivider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.08))
            .frame(width: 1, height: 30)
    }

    // MARK: - Daily Affirmation Card (new feature)

    private var affirmationCard: some View {
        let affirmation = Self.dailyAffirmation
        return VStack(alignment: .leading, spacing: AstralTheme.Spacing.sm) {
            HStack(spacing: 6) {
                Text("TODAY'S AFFIRMATION")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.astralGold)
                    .tracking(1.2)
                Spacer()
                Text(Date(), format: .dateTime.month(.abbreviated).day())
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(Color.astralTextDim)
            }

            Text("\u{201C}\(affirmation)\u{201D}")
                .font(.system(.body, design: .serif, weight: .medium))
                .foregroundStyle(Color.astralText)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AstralTheme.Spacing.md)
        .background {
            RoundedRectangle(cornerRadius: AstralTheme.Radius.lg, style: .continuous)
                .fill(Color.astralViolet.opacity(0.12))
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2)
                        .fill(Color.astralGold)
                        .frame(width: 3)
                        .padding(.vertical, 12)
                        .offset(x: 0)
                }
        }
    }

    private static let affirmations: [String] = [
        "I am worthy of everything I desire and more.",
        "My dreams are becoming my reality with every breath.",
        "I attract abundance effortlessly and joyfully.",
        "I am the architect of my life and I build its foundation daily.",
        "Wealth, love, and health flow to me with ease.",
        "I trust the process and know that I am guided.",
        "Every day I grow closer to the life I am creating.",
        "I deserve deep love, true health, and unlimited abundance.",
        "My vision is clear, my faith is strong, my life is extraordinary.",
        "I am open to receiving miracles in expected and unexpected ways.",
        "I radiate confidence, clarity, and calm.",
        "The universe is always working in my favor.",
        "I am becoming the highest version of myself.",
        "My goals are achievable and I take inspired action toward them.",
        "I choose joy and it chooses me in return.",
        "I am magnetic to the life I am meant to live.",
        "I release what no longer serves me and welcome what does.",
        "Everything I need comes to me at the perfect time.",
        "I am grateful for all that I have and all that is coming.",
        "My potential is limitless and my future is bright.",
        "I deserve to live a life I am genuinely excited about.",
        "I am aligned with the energy of love, abundance, and purpose.",
        "My thoughts create my reality — I choose powerful thoughts.",
        "I am at peace with where I am and excited for where I am going.",
        "I breathe in possibility and breathe out doubt.",
        "Success is natural to me and flows through everything I do.",
        "I am creating a life that feels as good as it looks.",
        "I give myself permission to dream bigger than ever before.",
        "I am loved, I am supported, I am exactly where I need to be.",
        "Today I take one step closer to the life I was born to live.",
    ]

    private static var dailyAffirmation: String {
        let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 1
        return affirmations[dayOfYear % affirmations.count]
    }

    // MARK: - Create Section (editorial style — no feature listicle)

    private var createSection: some View {
        VStack(alignment: .leading, spacing: AstralTheme.Spacing.lg) {
            VStack(alignment: .leading, spacing: AstralTheme.Spacing.sm) {
                Text("SEE YOURSELF\nLIVING IT.")
                    .font(.system(.title, design: .serif, weight: .bold))
                    .foregroundStyle(Color.auroraGradient)
                    .lineSpacing(2)

                Text("Upload a selfie. Describe your goals. AI places you inside your dream life.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.astralTextMuted)
                    .lineSpacing(3)
            }

            Button {
                if storeManager.canCreateVisionBoard(currentCount: visionBoardManager.totalVisionBoards) {
                    showingCreateView = true
                } else {
                    showingUpgradeView = true
                }
            } label: {
                HStack(spacing: AstralTheme.Spacing.sm) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Create Your Vision Board")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                }
                .frame(maxWidth: .infinity)
            }
            .astralButton(.primary)
        }
        .padding(AstralTheme.Spacing.lg)
        .background {
            RoundedRectangle(cornerRadius: AstralTheme.Radius.xl, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.astralViolet.opacity(0.14),
                            Color.astralRose.opacity(0.08),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay {
                    RoundedRectangle(cornerRadius: AstralTheme.Radius.xl, style: .continuous)
                        .strokeBorder(Color.astralViolet.opacity(0.2), lineWidth: 1)
                }
        }
    }

    // MARK: - Recent Vision Boards

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: AstralTheme.Spacing.md) {
            HStack {
                Text("Your Boards")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.astralText)

                Spacer()

                NavigationLink("See All") { VisionBoardGalleryView() }
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.auroraGradient)
            }

            ScrollView(.horizontal) {
                HStack(spacing: AstralTheme.Spacing.md) {
                    ForEach(visionBoardManager.recentVisionBoards) { board in
                        VisionBoardCard(visionBoard: board)
                            .frame(width: sizeClass == .regular ? 220 : 180)
                    }

                    // Inline "add new board" tile after existing boards
                    Button {
                        if storeManager.canCreateVisionBoard(currentCount: visionBoardManager.totalVisionBoards) {
                            showingCreateView = true
                        } else {
                            showingUpgradeView = true
                        }
                    } label: {
                        VStack(spacing: AstralTheme.Spacing.sm) {
                            RoundedRectangle(cornerRadius: AstralTheme.Radius.md, style: .continuous)
                                .strokeBorder(
                                    Color.astralViolet.opacity(0.35),
                                    style: StrokeStyle(lineWidth: 1.5, dash: [6])
                                )
                                .frame(height: 130)
                                .overlay {
                                    VStack(spacing: AstralTheme.Spacing.sm) {
                                        Image(systemName: "plus.circle")
                                            .font(.system(size: 26, weight: .medium))
                                            .foregroundStyle(Color.astralViolet)
                                        Text("New Board")
                                            .font(.system(.caption, design: .rounded, weight: .semibold))
                                            .foregroundStyle(Color.astralViolet)
                                    }
                                }

                            Spacer(minLength: 28)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(width: 130)
                }
                .padding(.horizontal, 2)
            }
            .scrollIndicators(.hidden)
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

// MARK: - Insight Answer Sheet

struct InsightAnswerSheet: View {
    let question: String
    let onSave: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var answer = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.astralBlack.ignoresSafeArea()

                VStack(alignment: .leading, spacing: AstralTheme.Spacing.xl) {
                    // Coaching context
                    CoachingCard(
                        icon: "brain.head.profile",
                        color: .astralViolet,
                        text: "Taking time to reflect on your desires builds a clearer signal for the universe. The more vividly you can feel your answer, the more real it becomes."
                    )

                    // Question
                    VStack(alignment: .leading, spacing: AstralTheme.Spacing.sm) {
                        Text(question)
                            .font(.system(.title3, design: .rounded, weight: .bold))
                            .foregroundStyle(Color.astralText)
                            .lineSpacing(3)

                        TextEditor(text: $answer)
                            .scrollContentBackground(.hidden)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(Color.astralText)
                            .frame(minHeight: 140)
                            .padding(AstralTheme.Spacing.md)
                            .background(Color.astralSurface2)
                            .clipShape(RoundedRectangle(cornerRadius: AstralTheme.Radius.md, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: AstralTheme.Radius.md, style: .continuous)
                                    .strokeBorder(
                                        focused ? Color.astralViolet.opacity(0.6) : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                            .focused($focused)

                        Text("Write freely — there are no wrong answers.")
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(Color.astralTextDim)
                    }

                    Button("Save Reflection") {
                        let trimmed = answer.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        onSave(trimmed)
                        dismiss()
                    }
                    .astralButton(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .secondary : .primary)
                    .frame(maxWidth: .infinity)
                    .disabled(answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    .animation(AstralTheme.Motion.quick, value: answer.isEmpty)

                    Spacer()
                }
                .padding(AstralTheme.Spacing.lg)
            }
            .navigationTitle("Weekly Reflection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip") { dismiss() }
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Color.astralTextMuted)
                }
            }
        }
        .onAppear { focused = true }
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
    }
}

#Preview {
    HomeView()
        .environment(UserManager())
        .environment(VisionBoardManager())
        .environment(StoreManager())
}
