import SwiftUI

// MARK: - OnboardingView

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @Environment(UserManager.self) var userManager
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var step = 0
    @State private var appeared = false

    // Questionnaire state
    @State private var selectedAreas: Set<LifeArea> = []
    @State private var primaryDream = ""
    @State private var timeline: ManifestationTimeline = .thisYear

    private var questionnaireFilled: Bool {
        !selectedAreas.isEmpty && !primaryDream.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            Color.astralBlack.ignoresSafeArea()
            ambientGlow

            VStack(spacing: 0) {
                stepContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                bottomBar
                    .padding(.bottom, 48)
                    .opacity(appeared ? 1 : 0)
                    .animation(reduceMotion ? .none : AstralTheme.Motion.smooth.delay(0.3), value: appeared)
            }
        }
        .onAppear { appeared = true }
    }

    // MARK: - Step Router

    @ViewBuilder
    private var stepContent: some View {
        switch step {
        case 0:  WelcomeStep(appeared: appeared)
        case 1:  QuestionnaireStep(
                     selectedAreas: $selectedAreas,
                     primaryDream: $primaryDream,
                     timeline: $timeline
                 )
        default: SummaryStep(
                     selectedAreas: selectedAreas,
                     primaryDream: primaryDream,
                     timeline: timeline
                 )
        }
    }

    // MARK: - Ambient Glow

    private var ambientGlow: some View {
        let colors: [(Color, CGFloat, CGFloat, CGFloat, CGFloat)] = [
            (.astralViolet, 0.18, 300, -60, -180),
            (.astralRose,   0.10, 260,  80,   80),
        ]
        return ZStack {
            ForEach(Array(colors.enumerated()), id: \.0) { _, c in
                Ellipse()
                    .fill(c.0.opacity(c.1))
                    .frame(width: c.2, height: c.2)
                    .blur(radius: 80)
                    .offset(x: c.3, y: c.4)
            }
        }
        .ignoresSafeArea()
        .animation(reduceMotion ? .none : AstralTheme.Motion.smooth, value: step)
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        VStack(spacing: AstralTheme.Spacing.lg) {
            stepIndicator

            if step == 0 {
                Button("Continue") { advance() }
                    .astralButton(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, AstralTheme.Spacing.lg)

                Button("Skip") { complete(answers: nil) }
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.astralTextMuted)

            } else if step == 1 {
                Button("Continue") { advance() }
                    .astralButton(questionnaireFilled ? .primary : .secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, AstralTheme.Spacing.lg)
                    .disabled(!questionnaireFilled)
                    .animation(reduceMotion ? .none : AstralTheme.Motion.quick, value: questionnaireFilled)

            } else {
                Button("Begin My Journey") {
                    let answers = OnboardingAnswers(
                        lifeAreas: Array(selectedAreas),
                        primaryDream: primaryDream.trimmingCharacters(in: .whitespaces),
                        timeline: timeline,
                        completedAt: Date()
                    )
                    complete(answers: answers)
                }
                .astralButton(.primary)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, AstralTheme.Spacing.lg)
            }
        }
    }

    // MARK: - Step Indicator

    private var stepIndicator: some View {
        HStack(spacing: AstralTheme.Spacing.sm) {
            ForEach(0..<3) { index in
                Capsule()
                    .fill(index == step
                          ? AnyShapeStyle(Color.auroraGradient)
                          : AnyShapeStyle(Color.astralSurface2))
                    .frame(width: index == step ? 28 : 8, height: 8)
                    .animation(reduceMotion ? .none : AstralTheme.Motion.quick, value: step)
            }
        }
    }

    // MARK: - Navigation

    private func advance() {
        withAnimation(reduceMotion ? .none : AstralTheme.Motion.smooth) {
            step = min(step + 1, 2)
        }
    }

    private func complete(answers: OnboardingAnswers?) {
        if let answers {
            userManager.saveOnboardingAnswers(answers)
        }
        userManager.completeOnboarding()
        showOnboarding = false
    }
}

// MARK: - Step 0: Welcome

private struct WelcomeStep: View {
    let appeared: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: AstralTheme.Spacing.xl) {
            Spacer()

            // Icon
            ZStack {
                Circle()
                    .fill(Color.astralViolet.opacity(0.15))
                    .frame(width: 160, height: 160)
                    .blur(radius: 30)

                Circle()
                    .strokeBorder(
                        LinearGradient(
                            colors: [Color.astralViolet.opacity(0.6), Color.astralRose.opacity(0.3)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.5
                    )
                    .frame(width: 120, height: 120)

                if #available(iOS 26, *) {
                    Circle()
                        .fill(Color.astralViolet.opacity(0.15))
                        .glassEffect(.regular, in: Circle())
                        .frame(width: 118, height: 118)
                } else {
                    Circle()
                        .fill(Color.astralViolet.opacity(0.2))
                        .frame(width: 118, height: 118)
                }

                Image(systemName: "eye.circle.fill")
                    .font(.system(size: 52, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.astralViolet, .astralRose],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                    )
            }
            .astralPulsing()
            .opacity(appeared ? 1 : 0)
            .scaleEffect(appeared ? 1 : 0.8)
            .animation(reduceMotion ? .none : AstralTheme.Motion.smooth.delay(0.1), value: appeared)

            // Text
            VStack(spacing: AstralTheme.Spacing.md) {
                Text("Your Vision,\nRealized")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.astralText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)

                Text("In the next two steps, you'll set your intentions.\nOur AI will turn them into your first vision board.")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(Color.astralTextMuted)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, AstralTheme.Spacing.xl)
                    .lineSpacing(3)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 16)
            .animation(reduceMotion ? .none : AstralTheme.Motion.smooth.delay(0.2), value: appeared)

            Spacer()
            Spacer()
        }
    }
}

// MARK: - Step 1: Questionnaire

private struct QuestionnaireStep: View {
    @Binding var selectedAreas: Set<LifeArea>
    @Binding var primaryDream: String
    @Binding var timeline: ManifestationTimeline
    @FocusState private var dreamFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AstralTheme.Spacing.xl) {
                // Header
                VStack(alignment: .leading, spacing: AstralTheme.Spacing.xs) {
                    Text("Set Your Intentions")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(Color.astralText)

                    Text("Clarity is the first step. The more specific your intention, the faster it manifests.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Color.astralTextMuted)
                        .lineSpacing(2)
                }
                .padding(.top, AstralTheme.Spacing.lg)

                // Life area picker
                VStack(alignment: .leading, spacing: AstralTheme.Spacing.md) {
                    Label("What area are you ready to transform?", systemImage: "sparkles")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color.astralText)

                    LifeAreaGrid(selectedAreas: $selectedAreas)
                }

                // Dream input
                VStack(alignment: .leading, spacing: AstralTheme.Spacing.sm) {
                    Label("Describe your dream in one sentence", systemImage: "text.quote")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color.astralText)

                    TextField("e.g. I am living in my dream home by the ocean…", text: $primaryDream, axis: .vertical)
                        .lineLimit(2...4)
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(Color.astralText)
                        .padding(AstralTheme.Spacing.md)
                        .background(Color.astralSurface2)
                        .clipShape(RoundedRectangle(cornerRadius: AstralTheme.Radius.md, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: AstralTheme.Radius.md, style: .continuous)
                                .strokeBorder(
                                    dreamFocused ? Color.astralViolet.opacity(0.7) : Color.astralSurface2,
                                    lineWidth: 1
                                )
                        )
                        .focused($dreamFocused)
                        .submitLabel(.done)
                        .onSubmit { dreamFocused = false }

                    Text("Write in the present tense as if it's already true.")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Color.astralTextDim)
                }

                // Timeline
                VStack(alignment: .leading, spacing: AstralTheme.Spacing.sm) {
                    Label("When do you see yourself living this?", systemImage: "calendar")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color.astralText)

                    HStack(spacing: AstralTheme.Spacing.sm) {
                        ForEach(ManifestationTimeline.allCases) { option in
                            TimelineChip(option: option, isSelected: timeline == option) {
                                withAnimation(AstralTheme.Motion.quick) { timeline = option }
                            }
                        }
                    }
                }

                // Coaching insight
                CoachingCard(
                    icon: "lightbulb.fill",
                    color: .astralGold,
                    text: "Manifestation works best when you focus on one clear intention at a time. Small, believable goals build momentum faster than grand vague wishes."
                )

                Spacer(minLength: 120)
            }
            .padding(.horizontal, AstralTheme.Spacing.lg)
        }
        .onTapGesture { dreamFocused = false }
    }
}

// MARK: - Life Area Grid

private struct LifeAreaGrid: View {
    @Binding var selectedAreas: Set<LifeArea>

    var body: some View {
        let columns = [GridItem(.adaptive(minimum: 140), spacing: AstralTheme.Spacing.sm)]
        LazyVGrid(columns: columns, spacing: AstralTheme.Spacing.sm) {
            ForEach(LifeArea.allCases) { area in
                LifeAreaChip(area: area, isSelected: selectedAreas.contains(area)) {
                    withAnimation(AstralTheme.Motion.quick) {
                        if selectedAreas.contains(area) {
                            selectedAreas.remove(area)
                        } else {
                            selectedAreas.insert(area)
                        }
                    }
                }
            }
        }
    }
}

private struct LifeAreaChip: View {
    let area: LifeArea
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: area.icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : area.color)

                Text(area.displayName)
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : Color.astralText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isSelected
                    ? AnyShapeStyle(area.color.opacity(0.85))
                    : AnyShapeStyle(Color.astralSurface2)
            )
            .clipShape(RoundedRectangle(cornerRadius: AstralTheme.Radius.sm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AstralTheme.Radius.sm, style: .continuous)
                    .strokeBorder(
                        isSelected ? area.color : Color.astralSurface2,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

private struct TimelineChip: View {
    let option: ManifestationTimeline
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: option.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.astralViolet : Color.astralTextMuted)
                Text(option.displayName)
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(isSelected ? Color.astralText : Color.astralTextMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                isSelected
                    ? AnyShapeStyle(Color.astralViolet.opacity(0.18))
                    : AnyShapeStyle(Color.astralSurface2)
            )
            .clipShape(RoundedRectangle(cornerRadius: AstralTheme.Radius.sm, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AstralTheme.Radius.sm, style: .continuous)
                    .strokeBorder(
                        isSelected ? Color.astralViolet.opacity(0.6) : Color.clear,
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 2: Summary

private struct SummaryStep: View {
    let selectedAreas: Set<LifeArea>
    let primaryDream: String
    let timeline: ManifestationTimeline
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var appeared = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: AstralTheme.Spacing.xl) {
                // Header
                VStack(alignment: .leading, spacing: AstralTheme.Spacing.sm) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 40, weight: .semibold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.astralViolet, .astralRose],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .padding(.top, AstralTheme.Spacing.lg)
                        .opacity(appeared ? 1 : 0)
                        .scaleEffect(appeared ? 1 : 0.7)
                        .animation(reduceMotion ? .none : AstralTheme.Motion.smooth.delay(0.05), value: appeared)

                    Text("Your Intentions\nAre Set")
                        .font(.system(.largeTitle, design: .rounded, weight: .bold))
                        .foregroundStyle(Color.astralText)
                        .lineSpacing(2)
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 12)
                        .animation(reduceMotion ? .none : AstralTheme.Motion.smooth.delay(0.1), value: appeared)
                }

                // Dream card
                VStack(alignment: .leading, spacing: AstralTheme.Spacing.sm) {
                    Text("\"\(primaryDream)\"")
                        .font(.system(.title3, design: .rounded, weight: .medium))
                        .foregroundStyle(Color.astralText)
                        .italic()
                        .lineSpacing(3)

                    HStack(spacing: 6) {
                        Image(systemName: timeline.icon)
                            .font(.caption)
                        Text(timeline.displayName)
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                    }
                    .foregroundStyle(Color.astralViolet)
                }
                .padding(AstralTheme.Spacing.lg)
                .astralGlass(tint: .astralViolet)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
                .animation(reduceMotion ? .none : AstralTheme.Motion.smooth.delay(0.15), value: appeared)

                // Life areas
                if !selectedAreas.isEmpty {
                    VStack(alignment: .leading, spacing: AstralTheme.Spacing.sm) {
                        Text("Focusing on")
                            .font(.system(.caption, design: .rounded, weight: .semibold))
                            .foregroundStyle(Color.astralTextMuted)
                            .textCase(.uppercase)
                            .tracking(1)

                        FlowLayout(spacing: 8) {
                            ForEach(Array(selectedAreas)) { area in
                                HStack(spacing: 5) {
                                    Image(systemName: area.icon)
                                        .font(.system(size: 11, weight: .semibold))
                                    Text(area.displayName)
                                        .font(.system(.caption, design: .rounded, weight: .semibold))
                                }
                                .foregroundStyle(area.color)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(area.color.opacity(0.15))
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .opacity(appeared ? 1 : 0)
                    .animation(reduceMotion ? .none : AstralTheme.Motion.smooth.delay(0.2), value: appeared)
                }

                // Coaching
                CoachingCard(
                    icon: "brain.head.profile",
                    color: .astralViolet,
                    text: "Manifestation gains power through repetition and emotion. Your first board will be built around your #1 intention — look at it every morning and feel it as already real."
                )
                .opacity(appeared ? 1 : 0)
                .animation(reduceMotion ? .none : AstralTheme.Motion.smooth.delay(0.25), value: appeared)

                // What happens next
                VStack(alignment: .leading, spacing: AstralTheme.Spacing.sm) {
                    Text("What happens next")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color.astralTextMuted)
                        .textCase(.uppercase)
                        .tracking(1)

                    VStack(spacing: AstralTheme.Spacing.sm) {
                        NextStepRow(number: "1", text: "Take a quick selfie so AI can place you in your dream scenes")
                        NextStepRow(number: "2", text: "Choose your visual style and AI generates your first board")
                        NextStepRow(number: "3", text: "We'll ask a new question each week to deepen your manifestation practice")
                    }
                }
                .opacity(appeared ? 1 : 0)
                .animation(reduceMotion ? .none : AstralTheme.Motion.smooth.delay(0.3), value: appeared)

                Spacer(minLength: 120)
            }
            .padding(.horizontal, AstralTheme.Spacing.lg)
        }
        .onAppear { appeared = true }
    }
}

private struct NextStepRow: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: AstralTheme.Spacing.md) {
            ZStack {
                Circle()
                    .fill(Color.astralViolet.opacity(0.2))
                    .frame(width: 28, height: 28)
                Text(number)
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.astralViolet)
            }
            Text(text)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Color.astralTextMuted)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Coaching Card

struct CoachingCard: View {
    let icon: String
    let color: Color
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: AstralTheme.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(color)
                .frame(width: 28)

            Text(text)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Color.astralTextMuted)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(AstralTheme.Spacing.md)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: AstralTheme.Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: AstralTheme.Radius.md, style: .continuous)
                .strokeBorder(color.opacity(0.25), lineWidth: 1)
        )
    }
}

// MARK: - Flow Layout (wrapping HStack)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var height: CGFloat = 0
        var row: CGFloat = 0
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if row + size.width > maxWidth {
                height += rowHeight + spacing
                row = 0
                rowHeight = 0
            }
            row += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        height += rowHeight
        return CGSize(width: maxWidth, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let maxWidth = bounds.width
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0

        for view in subviews {
            let size = view.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            view.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

#Preview {
    OnboardingView(showOnboarding: .constant(true))
        .environment(UserManager())
}
