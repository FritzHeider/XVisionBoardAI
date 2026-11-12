import SwiftUI

// MARK: - App Tabs

enum AppTab: Hashable {
    case home, create, gallery, profile
}

// MARK: - Root Router

struct ContentView: View {
    @Environment(UserManager.self) var userManager
    @Environment(StoreManager.self) var storeManager
    @State private var selectedTab: AppTab = .home
    @State private var showOnboarding = true

    var body: some View {
        Group {
            #if targetEnvironment(simulator)
            // Screenshot/QA hook: `-paywallPreview boardLimit|audio|general`
            // opens straight to the paywall. Simulator only: it can never ship in a
            // device or App Store build. (#if DEBUG isn't usable here: this target
            // doesn't define DEBUG.)
            if let trigger = Self.debugPaywallTrigger {
                SubscriptionView(trigger: trigger)
            } else {
                router
            }
            #else
            router
            #endif
        }
        // The whole palette is hardcoded dark (astralBlack surfaces, cream text),
        // but nothing locked the color scheme. In Light Mode the status bar drew
        // dark glyphs on the near-black background and every piece of system
        // chrome — alerts, keyboard, share sheet, context menus, date pickers —
        // rendered light over dark content.
        .preferredColorScheme(.dark)
    }

    @ViewBuilder
    private var router: some View {
        if showOnboarding && !userManager.hasCompletedOnboarding {
            OnboardingView(showOnboarding: $showOnboarding)
        } else if userManager.isLoggedIn {
            MainTabView(selectedTab: $selectedTab)
        } else {
            WelcomeView()
        }
    }

    #if targetEnvironment(simulator)
    private static var debugPaywallTrigger: PaywallTrigger? {
        let args = ProcessInfo.processInfo.arguments
        guard let i = args.firstIndex(of: "-paywallPreview") else { return nil }
        switch args.indices.contains(i + 1) ? args[i + 1] : "" {
        case "audio":   return .audio
        case "general": return .general
        default:        return .boardLimit
        }
    }
    #endif
}

// MARK: - Main Tab View

struct MainTabView: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Home", systemImage: "house.fill", value: AppTab.home) {
                HomeView()
            }
            Tab("Create", systemImage: "plus.circle.fill", value: AppTab.create) {
                CreateVisionBoardView()
            }
            Tab("Gallery", systemImage: "photo.stack.fill", value: AppTab.gallery) {
                VisionBoardGalleryView()
            }
            Tab("Profile", systemImage: "person.fill", value: AppTab.profile) {
                ProfileView()
            }
        }
        .tint(.astralViolet)
        .tabViewStyle(.sidebarAdaptable)
    }
}

#Preview {
    ContentView()
        .environment(UserManager())
        .environment(StoreManager())
        .environment(VisionBoardManager())
}
