import SwiftUI

// MARK: - App Tabs

enum AppTab: Hashable {
    case home, create, gallery, profile
}

// MARK: - Root Router

@MainActor
struct ContentView: View {
    @Environment(UserManager.self) var userManager
    @Environment(StoreManager.self) var storeManager
    @State private var selectedTab: AppTab = .home
    @State private var showOnboarding = true

    var body: some View {
        Group {
            if showOnboarding && !userManager.hasCompletedOnboarding {
                OnboardingView(showOnboarding: $showOnboarding)
            } else if userManager.isLoggedIn {
                MainTabView(selectedTab: $selectedTab)
            } else {
                WelcomeView()
            }
        }
    }
}

// MARK: - Main Tab View

@MainActor
struct MainTabView: View {
    @Binding var selectedTab: AppTab

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(AppTab.home)

            CreateVisionBoardView()
                .tabItem {
                    Label("Create", systemImage: "plus.circle.fill")
                }
                .tag(AppTab.create)

            VisionBoardGalleryView()
                .tabItem {
                    Label("Gallery", systemImage: "photo.stack.fill")
                }
                .tag(AppTab.gallery)

            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(AppTab.profile)
        }
        .tint(.astralViolet)
    }
}

#Preview {
    ContentView()
        .environment(UserManager())
        .environment(StoreManager())
        .environment(VisionBoardManager())
}
