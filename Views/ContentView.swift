//
//  ContentView.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var storeManager: StoreManager
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var selectedTab = 0
    @State private var showOnboarding = true
    
    var body: some View {
        Group {
            if showOnboarding && !userManager.hasCompletedOnboarding {
                OnboardingView(showOnboarding: $showOnboarding)
            } else if isLoggedIn {
                MainTabView(selectedTab: $selectedTab)
            } else {
                WelcomeView()
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            setupAppearance()
        }
    }
    
    private func setupAppearance() {
        // Configure app-wide appearance
        UITabBar.appearance().backgroundColor = UIColor.black
        UINavigationBar.appearance().backgroundColor = UIColor.black
    }
}

struct MainTabView: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var userManager: UserManager
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Image(systemName: "house.fill")
                    Text("Home")
                }
                .tag(0)
            
            CreateVisionBoardView()
                .tabItem {
                    Image(systemName: "camera.fill")
                    Text("Create")
                }
                .tag(1)
            
            VisionBoardGalleryView()
                .tabItem {
                    Image(systemName: "photo.stack.fill")
                    Text("Gallery")
                }
                .tag(2)
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.fill")
                    Text("Profile")
                }
                .tag(3)
        }
        .accentColor(Color.cosmicPurple)
        .background(Color.cosmicBlack)
    }
}

#Preview {
    ContentView()
        .environmentObject(UserManager())
        .environmentObject(StoreManager())
        .environmentObject(VisionBoardManager())
}

