import SwiftUI

struct WelcomeView: View {
    @Environment(UserManager.self) var userManager
    @State private var showingSignUp = false
    @State private var showingSignIn = false
    @State private var appeared = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            // Deep aurora background
            Color.astralBlack.ignoresSafeArea()

            // Ambient glow blobs
            ZStack {
                Ellipse()
                    .fill(Color.astralViolet.opacity(0.20))
                    .frame(width: 320, height: 320)
                    .blur(radius: 80)
                    .offset(x: -80, y: -200)

                Ellipse()
                    .fill(Color.astralRose.opacity(0.14))
                    .frame(width: 280, height: 280)
                    .blur(radius: 70)
                    .offset(x: 100, y: -80)

                Ellipse()
                    .fill(Color.astralIndigo.opacity(0.12))
                    .frame(width: 240, height: 240)
                    .blur(radius: 60)
                    .offset(x: -40, y: 200)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                // Hero
                heroSection
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 24)
                    .animation(reduceMotion ? .none : AstralTheme.Motion.smooth.delay(0.1), value: appeared)

                Spacer()

                // Feature pills
                featurePills
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 16)
                    .animation(reduceMotion ? .none : AstralTheme.Motion.smooth.delay(0.25), value: appeared)

                Spacer()

                // CTAs
                ctaSection
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
                    .animation(reduceMotion ? .none : AstralTheme.Motion.smooth.delay(0.4), value: appeared)
                    .padding(.bottom, 48)
            }
            .padding(.horizontal, AstralTheme.Spacing.lg)
        }
        .onAppear { appeared = true }
        .sheet(isPresented: $showingSignUp) { SignUpView() }
        .sheet(isPresented: $showingSignIn) { SignInView() }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: AstralTheme.Spacing.lg) {
            // Icon with aurora ring
            ZStack {
                Circle()
                    .fill(Color.auroraGradient)
                    .frame(width: 120, height: 120)
                    .opacity(0.18)
                    .blur(radius: 20)

                Circle()
                    .strokeBorder(Color.auroraGradient, lineWidth: 2)
                    .frame(width: 104, height: 104)

                Image(systemName: "sparkles")
                    .font(.system(size: 44, weight: .semibold))
                    .foregroundStyle(Color.auroraGradient)
            }
            .astralPulsing()

            // Brand name + tagline
            VStack(spacing: AstralTheme.Spacing.sm) {
                Text("ManifestMe")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.auroraGradient)

                Text("AI Future Self")
                    .font(.system(.title3, design: .rounded, weight: .medium))
                    .foregroundStyle(Color.astralTextMuted)
            }

            // Main hook
            VStack(spacing: AstralTheme.Spacing.sm) {
                Text("See Yourself\nLiving Your Dreams")
                    .font(.system(.title, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.astralText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)

                Text("AI-powered vision boards personalized to your face, goals, and future self.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.astralTextMuted)
                    .multilineTextAlignment(.center)
            }
        }
    }

    // MARK: - Feature Pills

    private var featurePills: some View {
        VStack(spacing: AstralTheme.Spacing.sm) {
            HStack(spacing: AstralTheme.Spacing.sm) {
                WelcomeFeaturePill(icon: "person.fill.viewfinder", text: "Your Face in Every Board", color: .astralViolet)
                WelcomeFeaturePill(icon: "sparkles", text: "AI Affirmations", color: .astralGold)
            }
            HStack(spacing: AstralTheme.Spacing.sm) {
                WelcomeFeaturePill(icon: "photo.fill", text: "HD Wallpapers", color: .astralIndigo)
                WelcomeFeaturePill(icon: "bell.badge.fill", text: "Daily Reminders", color: .astralRose)
            }
        }
    }

    // MARK: - CTAs

    private var ctaSection: some View {
        VStack(spacing: AstralTheme.Spacing.md) {
            Button("Start Your Journey — Free") {
                showingSignUp = true
            }
            .astralButton(.primary)
            .frame(maxWidth: .infinity)

            Button("I already have an account") {
                showingSignIn = true
            }
            .font(.system(.subheadline, design: .rounded))
            .foregroundStyle(Color.astralTextMuted)
        }
    }
}

// MARK: - Feature Pill

struct WelcomeFeaturePill: View {
    let icon: String
    let text: String
    let color: Color

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(color)

            Text(text)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(Color.astralText)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background {
            Capsule()
                .fill(color.opacity(0.10))
                .overlay {
                    Capsule().strokeBorder(color.opacity(0.25), lineWidth: 1)
                }
        }
    }
}

// Backward compat alias
typealias FeatureBadge = WelcomeFeaturePill

#Preview {
    WelcomeView()
        .environment(UserManager())
}
