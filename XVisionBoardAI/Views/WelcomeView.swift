//
//  WelcomeView.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var userManager: UserManager
    @State private var showingSignUp = false
    @State private var showingSignIn = false
    
    var body: some View {
        ZStack {
            // Background gradient
            Color.cosmicGradient
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo and title
                VStack(spacing: 24) {
                    Image(systemName: "eye.circle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.cosmicWhite)
                        .pulsing()
                    
                    VStack(spacing: 8) {
                        Text("XVisionBoard AI")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.cosmicWhite)
                        
                        Text("Program Your Reality")
                            .font(.title2)
                            .fontWeight(.medium)
                            .foregroundColor(.cosmicWhite.opacity(0.9))
                    }
                }
                
                // Main message
                VStack(spacing: 16) {
                    Text("See YOURSELF Living Your Dreams")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.cosmicWhite)
                        .multilineTextAlignment(.center)
                    
                    Text("Create personalized AI vision boards where you appear achieving your goals. Transform manifestation with the power of seeing yourself succeed.")
                        .font(.body)
                        .foregroundColor(.cosmicWhite.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
                
                // Feature highlights
                VStack(spacing: 12) {
                    FeatureBadge(icon: "camera.fill", text: "Personalized with YOUR Face")
                    FeatureBadge(icon: "brain.head.profile", text: "AI-Powered Manifestation")
                    FeatureBadge(icon: "heart.fill", text: "Emotional Connection")
                    FeatureBadge(icon: "bolt.fill", text: "Instant Results")
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 16) {
                    Button("Start Your Transformation") {
                        showingSignUp = true
                    }
                    .cosmicButton()
                    .font(.headline)
                    
                    Button("Already have an account? Sign In") {
                        showingSignIn = true
                    }
                    .foregroundColor(.cosmicWhite.opacity(0.8))
                    .font(.subheadline)
                }
                .padding(.bottom, 40)
            }
            .padding()
        }
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
        }
        .sheet(isPresented: $showingSignIn) {
            SignInView()
        }
    }
}

struct FeatureBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.cosmicGold)
            
            Text(text)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.cosmicWhite)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.3))
        )
    }
}

struct OnboardingView: View {
    @Binding var showOnboarding: Bool
    @EnvironmentObject var userManager: UserManager
    @State private var currentPage = 0
    
    private let pages = [
        OnboardingPage(
            icon: "camera.fill",
            title: "Capture Your Selfie",
            description: "Take or upload a photo to personalize your vision boards with your face",
            color: .cosmicPurple
        ),
        OnboardingPage(
            icon: "brain.head.profile",
            title: "AI Creates Your Vision",
            description: "Advanced AI generates personalized vision boards featuring YOU living your dreams",
            color: .cosmicBlue
        ),
        OnboardingPage(
            icon: "heart.fill",
            title: "See Yourself Succeed",
            description: "Experience powerful emotional connection by seeing yourself achieving your goals",
            color: .cosmicPink
        ),
        OnboardingPage(
            icon: "bolt.fill",
            title: "Manifest Faster",
            description: "Studies show personalized visualization accelerates manifestation by 3x",
            color: .cosmicGold
        )
    ]
    
    var body: some View {
        ZStack {
            Color.cosmicBlack.ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Skip button
                HStack {
                    Spacer()
                    Button("Skip") {
                        completeOnboarding()
                    }
                    .foregroundColor(.cosmicWhite.opacity(0.7))
                    .padding()
                }
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(page: pages[index])
                            .tag(index)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                
                // Page indicator
                HStack(spacing: 8) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        Circle()
                            .fill(currentPage == index ? Color.cosmicPurple : Color.gray)
                            .frame(width: 8, height: 8)
                            .animation(.easeInOut, value: currentPage)
                    }
                }
                
                // Navigation buttons
                HStack {
                    if currentPage > 0 {
                        Button("Previous") {
                            withAnimation {
                                currentPage -= 1
                            }
                        }
                        .foregroundColor(.cosmicWhite)
                    }
                    
                    Spacer()
                    
                    if currentPage < pages.count - 1 {
                        Button("Next") {
                            withAnimation {
                                currentPage += 1
                            }
                        }
                        .cosmicButton()
                    } else {
                        Button("Get Started") {
                            completeOnboarding()
                        }
                        .cosmicButton()
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 40)
            }
        }
    }
    
    private func completeOnboarding() {
        userManager.completeOnboarding()
        showOnboarding = false
    }
}

struct OnboardingPage {
    let icon: String
    let title: String
    let description: String
    let color: Color
}

struct OnboardingPageView: View {
    let page: OnboardingPage
    
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: page.icon)
                .font(.system(size: 80))
                .foregroundColor(page.color)
                .pulsing()
            
            VStack(spacing: 16) {
                Text(page.title)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.cosmicWhite)
                    .multilineTextAlignment(.center)
                
                Text(page.description)
                    .font(.body)
                    .foregroundColor(.cosmicWhite.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
        .padding()
    }
}

#Preview {
    WelcomeView()
        .environmentObject(UserManager())
}

#Preview("Onboarding") {
    OnboardingView(showOnboarding: .constant(true))
        .environmentObject(UserManager())
}

