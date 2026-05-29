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
    }
}

#Preview {
    ContentView()
        .environment(UserManager())
        .environment(StoreManager())
        .environment(VisionBoardManager())
}
