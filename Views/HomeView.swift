//
//  HomeView.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var visionBoardManager: VisionBoardManager
    @EnvironmentObject var storeManager: StoreManager
    
    @State private var showingCreateView = false
    @State private var showingUpgradeView = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.cosmicBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        headerSection
                        
                        // Quick stats
                        statsSection
                        
                        // Main action
                        createVisionBoardSection
                        
                        // Recent vision boards
                        if !visionBoardManager.recentVisionBoards.isEmpty {
                            recentVisionBoardsSection
                        }
                        
                        // Manifestation tips
                        manifestationTipsSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingCreateView) {
            CreateVisionBoardView()
        }
        .sheet(isPresented: $showingUpgradeView) {
            SubscriptionView()
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Ready to see")
                        .font(.title2)
                        .foregroundColor(.cosmicWhite.opacity(0.8))
                    
                    HStack(spacing: 4) {
                        Text("yourself")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.cosmicPurple)
                        
                        Text("living your dreams?")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.cosmicWhite)
                    }
                }
                
                Spacer()
                
                // Profile image
                if let profileImage = userManager.currentUser?.profileImage {
                    Image(uiImage: profileImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(Color.cosmicPurple, lineWidth: 2)
                        )
                } else {
                    Image(systemName: "person.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.cosmicPurple)
                }
            }
            
            // Subscription badge
            HStack {
                Image(systemName: storeManager.hasActiveSubscription ? "crown.fill" : "star.fill")
                    .foregroundColor(storeManager.hasActiveSubscription ? .cosmicGold : .gray)
                
                Text(userManager.subscriptionDisplayName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.cosmicWhite)
                
                Spacer()
                
                if !storeManager.hasActiveSubscription {
                    Button("Upgrade") {
                        showingUpgradeView = true
                    }
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(Color.cosmicGold)
                    .foregroundColor(.black)
                    .clipShape(Capsule())
                }
            }
            .padding()
            .cosmicCard()
        }
    }
    
    // MARK: - Stats Section
    
    private var statsSection: some View {
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
                title: "Remaining",
                value: userManager.remainingVisionBoards == Int.max ? "∞" : "\(userManager.remainingVisionBoards)",
                icon: "plus.circle.fill",
                color: .cosmicGold
            )
        }
    }
    
    // MARK: - Create Vision Board Section
    
    private var createVisionBoardSection: some View {
        VStack(spacing: 16) {
            VStack(spacing: 8) {
                Text("Create Personalized Vision Board")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.cosmicWhite)
                
                Text("Start by taking or uploading a selfie, then create vision boards featuring YOU living your dreams")
                    .font(.body)
                    .foregroundColor(.cosmicWhite.opacity(0.8))
                    .multilineTextAlignment(.center)
            }
            
            // Why personalization works
            VStack(spacing: 12) {
                PersonalizationBenefit(
                    icon: "heart.fill",
                    title: "Emotional Connection",
                    description: "Seeing yourself makes dreams feel achievable"
                )
                
                PersonalizationBenefit(
                    icon: "brain.head.profile",
                    title: "Subconscious Programming",
                    description: "Your brain recognizes you in success scenarios"
                )
                
                PersonalizationBenefit(
                    icon: "bolt.fill",
                    title: "Faster Results",
                    description: "Studies show 3x acceleration in manifestation"
                )
            }
            .padding()
            .cosmicCard()
            
            Button("Start with Your Selfie") {
                if userManager.canCreateVisionBoard {
                    showingCreateView = true
                } else {
                    showingUpgradeView = true
                }
            }
            .cosmicButton()
            .font(.headline)
        }
    }
    
    // MARK: - Recent Vision Boards Section
    
    private var recentVisionBoardsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Recent Vision Boards")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.cosmicWhite)
                
                Spacer()
                
                NavigationLink("See All") {
                    VisionBoardGalleryView()
                }
                .foregroundColor(.cosmicPurple)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(visionBoardManager.recentVisionBoards) { visionBoard in
                        VisionBoardCard(visionBoard: visionBoard)
                            .frame(width: 200)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Manifestation Tips Section
    
    private var manifestationTipsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Manifestation Tips")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.cosmicWhite)
            
            VStack(spacing: 12) {
                ManifestationTip(
                    icon: "clock.fill",
                    title: "Daily Visualization",
                    description: "Spend 5-10 minutes daily viewing your vision boards"
                )
                
                ManifestationTip(
                    icon: "heart.text.square.fill",
                    title: "Feel the Emotions",
                    description: "Experience the joy and excitement of achieving your goals"
                )
                
                ManifestationTip(
                    icon: "target",
                    title: "Take Inspired Action",
                    description: "Let your vision boards guide your daily decisions and actions"
                )
            }
            .padding()
            .cosmicCard()
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.cosmicWhite)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.cosmicWhite.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .cosmicCard()
    }
}

struct PersonalizationBenefit: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.cosmicGold)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.cosmicWhite)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.cosmicWhite.opacity(0.8))
            }
            
            Spacer()
        }
    }
}

struct ManifestationTip: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.cosmicPurple)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.cosmicWhite)
                
                Text(description)
                    .font(.caption)
                    .foregroundColor(.cosmicWhite.opacity(0.8))
            }
            
            Spacer()
        }
    }
}

struct VisionBoardCard: View {
    let visionBoard: VisionBoard
    @EnvironmentObject var visionBoardManager: VisionBoardManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Preview image (first image or placeholder)
            if let firstImage = visionBoard.images.first?.image {
                Image(uiImage: firstImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(height: 120)
                    .clipped()
                    .cornerRadius(12)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.cosmicGray)
                    .frame(height: 120)
                    .overlay(
                        Image(systemName: "photo.fill")
                            .font(.title)
                            .foregroundColor(.cosmicWhite.opacity(0.5))
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(visionBoard.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.cosmicWhite)
                    .lineLimit(1)
                
                Text(visionBoard.formattedCreatedDate)
                    .font(.caption)
                    .foregroundColor(.cosmicWhite.opacity(0.7))
                
                HStack {
                    Image(systemName: "eye.fill")
                        .font(.caption)
                        .foregroundColor(.cosmicBlue)
                    
                    Text("\(visionBoard.viewCount)")
                        .font(.caption)
                        .foregroundColor(.cosmicWhite.opacity(0.7))
                    
                    Spacer()
                    
                    if visionBoard.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.caption)
                            .foregroundColor(.cosmicPink)
                    }
                }
            }
        }
        .padding()
        .cosmicCard()
        .onTapGesture {
            visionBoardManager.incrementViewCount(visionBoard)
        }
    }
}

#Preview {
    HomeView()
        .environmentObject(UserManager())
        .environmentObject(VisionBoardManager())
        .environmentObject(StoreManager())
}

