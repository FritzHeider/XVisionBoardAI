//
//  ProfileView.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var storeManager: StoreManager
    @EnvironmentObject var visionBoardManager: VisionBoardManager
    
    @State private var showingSubscriptionView = false
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.cosmicBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Profile header
                        profileHeader
                        
                        // Stats section
                        statsSection
                        
                        // Subscription section
                        subscriptionSection
                        
                        // Settings sections
                        settingsSection
                        
                        // Support section
                        supportSection
                        
                        // Account actions
                        accountActionsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingSubscriptionView) {
            SubscriptionView()
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Sign Out", role: .destructive) {
                userManager.signOut()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
            Button("Delete", role: .destructive) {
                Task {
                        await userManager.deleteAccount()
                    }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete your account and all vision boards. This action cannot be undone.")
        }
    }
    
    // MARK: - Profile Header
    
    private var profileHeader: some View {
        VStack(spacing: 16) {
            // Profile image
            if let profileImage = userManager.currentUser?.profileImage {
                Image(uiImage: profileImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.cosmicPurple, lineWidth: 3)
                    )
            } else {
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.cosmicPurple)
            }
            
            VStack(spacing: 8) {
                Text(userManager.currentUser?.username ?? "User")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.cosmicWhite)
                
                Text(userManager.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.cosmicWhite.opacity(0.7))
                
                // Subscription badge
                HStack {
                    Image(systemName: storeManager.hasActiveSubscription ? "crown.fill" : "star.fill")
                        .foregroundColor(storeManager.hasActiveSubscription ? .cosmicGold : .gray)
                    
                    Text(userManager.subscriptionDisplayName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.cosmicWhite)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.cosmicGray)
                )
            }
        }
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
        VStack(spacing: 16) {
            Text("Your Journey")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.cosmicWhite)
            
            HStack(spacing: 16) {
                StatCard(
                    title: "Vision Boards",
                    value: "\(visionBoardManager.totalVisionBoards)",
                    icon: "photo.stack.fill",
                    color: .cosmicPurple
                )
                
                StatCard(
                    title: "Total Views",
                    value: "\(visionBoardManager.totalViews)",
                    icon: "eye.fill",
                    color: .cosmicBlue
                )
                
                StatCard(
                    title: "Favorites",
                    value: "\(visionBoardManager.favoriteVisionBoards.count)",
                    icon: "heart.fill",
                    color: .cosmicPink
                )
            }
        }
    }
    
    // MARK: - Subscription Section
    
    private var subscriptionSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Subscription")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.cosmicWhite)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                if storeManager.hasActiveSubscription {
                    // Active subscription info
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Active Subscription")
                                    .font(.headline)
                                    .foregroundColor(.cosmicWhite)
                                
                                Text("You have access to all premium features")
                                    .font(.caption)
                                    .foregroundColor(.cosmicWhite.opacity(0.7))
                            }
                            
                            Spacer()
                        }
                        
                        Button("Manage Subscription") {
                            // Open App Store subscription management
                            if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
                                UIApplication.shared.open(url)
                            }
                        }
                        .cosmicButton()
                    }
                } else {
                    // Upgrade prompt
                    VStack(spacing: 12) {
                        HStack {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.cosmicGold)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Upgrade to Pro")
                                    .font(.headline)
                                    .foregroundColor(.cosmicWhite)
                                
                                Text("Unlock unlimited vision boards and premium features")
                                    .font(.caption)
                                    .foregroundColor(.cosmicWhite.opacity(0.7))
                            }
                            
                            Spacer()
                        }
                        
                        Button("View Plans") {
                            showingSubscriptionView = true
                        }
                        .cosmicButton()
                    }
                }
            }
            .padding()
            .cosmicCard()
        }
    }
    
    // MARK: - Settings Section
    
    private var settingsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.cosmicWhite)
                
                Spacer()
            }
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "bell.fill",
                    title: "Notifications",
                    subtitle: "Manage your notification preferences"
                ) {
                    // Open notification settings
                }
                
                Divider()
                    .background(Color.cosmicWhite.opacity(0.1))
                
                SettingsRow(
                    icon: "photo.fill",
                    title: "Photo Quality",
                    subtitle: "Choose image generation quality"
                ) {
                    // Open photo quality settings
                }
                
                Divider()
                    .background(Color.cosmicWhite.opacity(0.1))
                
                SettingsRow(
                    icon: "speaker.wave.2.fill",
                    title: "Audio Settings",
                    subtitle: "Configure affirmation audio"
                ) {
                    // Open audio settings
                }
                
                Divider()
                    .background(Color.cosmicWhite.opacity(0.1))
                
                SettingsRow(
                    icon: "lock.fill",
                    title: "Privacy",
                    subtitle: "Manage your privacy settings"
                ) {
                    // Open privacy settings
                }
            }
            .cosmicCard()
        }
    }
    
    // MARK: - Support Section
    
    private var supportSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Support")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.cosmicWhite)
                
                Spacer()
            }
            
            VStack(spacing: 0) {
                SettingsRow(
                    icon: "questionmark.circle.fill",
                    title: "Help Center",
                    subtitle: "Get answers to common questions"
                ) {
                    // Open help center
                }
                
                Divider()
                    .background(Color.cosmicWhite.opacity(0.1))
                
                SettingsRow(
                    icon: "envelope.fill",
                    title: "Contact Support",
                    subtitle: "Get help from our support team"
                ) {
                    // Open contact support
                }
                
                Divider()
                    .background(Color.cosmicWhite.opacity(0.1))
                
                SettingsRow(
                    icon: "star.fill",
                    title: "Rate the App",
                    subtitle: "Share your experience on the App Store"
                ) {
                    // Open App Store rating
                }
                
                Divider()
                    .background(Color.cosmicWhite.opacity(0.1))
                
                SettingsRow(
                    icon: "square.and.arrow.up.fill",
                    title: "Share App",
                    subtitle: "Tell your friends about XVisionBoard AI"
                ) {
                    // Share app
                }
            }
            .cosmicCard()
        }
    }
    
    // MARK: - Account Actions Section
    
    private var accountActionsSection: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Account")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.cosmicWhite)
                
                Spacer()
            }
            
            VStack(spacing: 12) {
                Button("Sign Out") {
                    showingSignOutAlert = true
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.cosmicGray)
                .foregroundColor(.cosmicWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                
                Button("Delete Account") {
                    showingDeleteAccountAlert = true
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red.opacity(0.2))
                .foregroundColor(.red)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Supporting Views

struct SettingsRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.cosmicPurple)
                    .frame(width: 24)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.cosmicWhite)
                    
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.cosmicWhite.opacity(0.7))
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.cosmicWhite.opacity(0.5))
            }
            .padding()
        }
    }
}

#Preview {
    ProfileView()
        .environmentObject(UserManager())
        .environmentObject(StoreManager())
        .environmentObject(VisionBoardManager())
}

