import SwiftUI

// MARK: - Onboarding Data

private struct OnboardingPage {
    let icon: String
    let title: String
    let body: String
    let accentColor: Color
    let glowColor: Color
}

private let onboardingPages: [OnboardingPage] = [
    OnboardingPage(
        icon: "eye.circle.fill",
        title: "Your Vision,\nRealized",
        body: "Create AI-powered vision boards personalized to your face, goals, and dreams.",
        accentColor: .astralViolet,
        glowColor: .astralViolet
    ),
    OnboardingPage(
        icon: "camera.fill",
        title: "Built Around\nYou",
        body: "Take a selfie and choose your style. Our AI places you at the center of every scene.",
        accentColor: .astralIndigo,
        glowColor: .astralRose
    ),
    OnboardingPage(
        icon: "sparkles",
        title: "Attract &\nAchieve",
        body: "Daily affirmations and stunning visuals keep your goals front of mind. Your future starts now.",
        accentColor: .astralRose,
        glowColor: .astralGold
    )
]

// MARK: - OnboardingView

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @Environment(UserManager.self) var userManager
    @State private var currentPage = 0
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color.astralBlack.ignoresSafeArea()

            // Ambient glow that shifts per page
            ambientGlow

            VStack(spacing: 0) {
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(onboardingPages.indices, id: \.self) { index in
                        OnboardingPageView(page: onboardingPages[index], appeared: appeared)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(reduceMotion ? .none : AstralTheme.Motion.smooth, value: currentPage)

                // Bottom controls
                bottomControls
                    .padding(.bottom, 48)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(reduceMotion ? .none : AstralTheme.Motion.smooth.delay(0.3), value: appeared)
            }
        }
        .onAppear { appeared = true }
    }

    // MARK: - Ambient Glow

    private var ambientGlow: some View {
        ZStack {
            let page = onboardingPages[currentPage]

            Ellipse()
                .fill(page.accentColor.opacity(0.18))
                .frame(width: 300, height: 300)
                .blur(radius: 80)
                .offset(x: -60, y: -180)
                .animation(reduceMotion ? .none : AstralTheme.Motion.smooth, value: currentPage)

            Ellipse()
                .fill(page.glowColor.opacity(0.12))
                .frame(width: 260, height: 260)
                .blur(radius: 70)
                .offset(x: 80, y: 80)
                .animation(reduceMotion ? .none : AstralTheme.Motion.smooth, value: currentPage)
        }
        .ignoresSafeArea()
    }

    // MARK: - Bottom Controls

    private var bottomControls: some View {
        VStack(spacing: AstralTheme.Spacing.lg) {
            pageIndicator

            if currentPage < onboardingPages.count - 1 {
                Button("Continue") {
                    withAnimation(reduceMotion ? .none : AstralTheme.Motion.quick) {
                        currentPage += 1
                    }
                }
                .astralButton(.primary)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, AstralTheme.Spacing.lg)

                Button("Skip") { complete() }
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.astralTextMuted)
            } else {
                Button("Get Started") { complete() }
                    .astralButton(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, AstralTheme.Spacing.lg)
            }
        }
    }

    // MARK: - Page Indicator

    private var pageIndicator: some View {
        HStack(spacing: AstralTheme.Spacing.sm) {
            ForEach(onboardingPages.indices, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage
                          ? AnyShapeStyle(Color.auroraGradient)
                          : AnyShapeStyle(Color.astralSurface2))
                    .frame(width: index == currentPage ? 28 : 8, height: 8)
                    .animation(reduceMotion ? .none : AstralTheme.Motion.quick, value: currentPage)
            }
        }
    }

    private func complete() {
        userManager.completeOnboarding()
        showOnboarding = false
    }
}

// MARK: - OnboardingPageView

private struct OnboardingPageView: View {
    let page: OnboardingPage
    let appeared: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: AstralTheme.Spacing.xl) {
            Spacer()

            // Icon
            iconView
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.8)
                .animation(reduceMotion ? .none : AstralTheme.Motion.smooth.delay(0.1), value: appeared)

            // Text
            VStack(spacing: AstralTheme.Spacing.md) {
                Text(page.title)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.astralText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)

                Text(page.body)
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

    private var iconView: some View {
        ZStack {
            // Outer glow
            Circle()
                .fill(page.accentColor.opacity(0.15))
                .frame(width: 160, height: 160)
                .blur(radius: 30)

            // Glass ring
            Circle()
                .strokeBorder(
                    LinearGradient(
                        colors: [page.accentColor.opacity(0.6), page.glowColor.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1.5
                )
                .frame(width: 120, height: 120)

            // Inner fill
            Circle()
                .fill(
                    LinearGradient(
                        colors: [page.accentColor.opacity(0.2), page.glowColor.opacity(0.1)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 118, height: 118)

            // Icon
            Image(systemName: page.icon)
                .font(.system(size: 52, weight: .semibold))
                .foregroundStyle(
                    LinearGradient(
                        colors: [page.accentColor, page.glowColor],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        }
        .astralPulsing()
    }
}

#Preview {
    OnboardingView(showOnboarding: .constant(true))
        .environment(UserManager())
}
