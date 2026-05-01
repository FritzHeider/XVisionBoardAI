import SwiftUI

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @Environment(UserManager.self) var userManager
    @State private var currentPage = 0

    private let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "eye.circle.fill",
            title: "Your Vision,\nRealized",
            body: "Create AI-powered vision boards personalized to your face, goals, and dreams.",
            gradient: [.cosmicPurple, .cosmicBlue]
        ),
        OnboardingPage(
            icon: "camera.fill",
            title: "Built Around\nYou",
            body: "Take a selfie and choose your style. Our AI places you at the center of every scene.",
            gradient: [.cosmicBlue, .cosmicPink]
        ),
        OnboardingPage(
            icon: "sparkles",
            title: "Attract &\nAchieve",
            body: "Daily affirmations and stunning visuals keep your goals front of mind. Your future starts now.",
            gradient: [.cosmicPink, .cosmicPurple]
        )
    ]

    var body: some View {
        ZStack {
            Color.cosmicBlack.ignoresSafeArea()

            VStack(spacing: 0) {
                TabView(selection: $currentPage) {
                    ForEach(pages.indices, id: \.self) { index in
                        pageView(pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: currentPage)

                bottomControls
                    .padding(.bottom, 48)
            }
        }
    }

    private func pageView(_ page: OnboardingPage) -> some View {
        VStack(spacing: 32) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: page.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    .frame(width: 140, height: 140)
                    .opacity(0.2)

                Image(systemName: page.icon)
                    .font(.system(size: 64, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: page.gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }

            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.cosmicWhite)
                    .multilineTextAlignment(.center)

                Text(page.body)
                    .font(.body)
                    .foregroundColor(.cosmicWhite.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
            Spacer()
        }
    }

    private var bottomControls: some View {
        VStack(spacing: 24) {
            pageIndicator

            if currentPage < pages.count - 1 {
                Button("Continue") {
                    withAnimation { currentPage += 1 }
                }
                .cosmicButton()

                Button("Skip") {
                    complete()
                }
                .font(.subheadline)
                .foregroundColor(.cosmicWhite.opacity(0.5))
            } else {
                Button("Get Started") {
                    complete()
                }
                .cosmicButton()
            }
        }
    }

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(pages.indices, id: \.self) { index in
                Capsule()
                    .fill(index == currentPage ? Color.cosmicPurple : Color.cosmicGray)
                    .frame(width: index == currentPage ? 24 : 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: currentPage)
            }
        }
    }

    private func complete() {
        userManager.completeOnboarding()
        showOnboarding = false
    }
}

private struct OnboardingPage {
    let icon: String
    let title: String
    let body: String
    let gradient: [Color]
}

#Preview {
    OnboardingView(showOnboarding: .constant(true))
        .environment(UserManager())
}
