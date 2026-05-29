//
//  ProfileView.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import SwiftUI
import RevenueCatUI

struct ProfileView: View {
    @Environment(UserManager.self) var userManager
    @Environment(StoreManager.self) var storeManager
    @Environment(VisionBoardManager.self) var visionBoardManager

    @State private var showingSubscriptionView = false
    @State private var showingCustomerCenter = false
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cosmicBlack.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        profileHeader
                        statsSection
                        subscriptionSection
                        settingsSection
                        supportSection
                        accountActionsSection
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 20)
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
                Task {
                    await storeManager.logout() // reset RC to anonymous user
                    userManager.signOut()
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account", isPresented: $showingDeleteAccountAlert) {
            Button("Delete", role: .destructive) {
                Task { await userManager.deleteAccount() }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This will permanently delete your account and all vision boards. This action cannot be undone.")
        }
        .sheet(isPresented: $showingCustomerCenter) {
            CustomerCenterView()
        }
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        ZStack {
            RadialGradient(
                colors: [Color.cosmicPurple.opacity(0.3), Color.cosmicBlue.opacity(0.1), Color.clear],
                center: .center,
                startRadius: 0,
                endRadius: 160
            )
            .frame(height: 220)
            .blur(radius: 20)

            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(Color.cosmicGradient, lineWidth: 3)
                        .frame(width: 108, height: 108)
                        .shadow(color: .cosmicPurple.opacity(0.5), radius: 12, x: 0, y: 6)

                    if let profileImage = userManager.currentUser?.profileImage {
                        Image(uiImage: profileImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 100, height: 100)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.cosmicPurple.opacity(0.35), Color.cosmicBlue.opacity(0.2)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 44, weight: .medium))
                                    .foregroundColor(.cosmicPurple)
                            )
                    }
                }

                VStack(spacing: 6) {
                    Text(userManager.currentUser?.username ?? "Dreamer")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .foregroundColor(.cosmicWhite)

                    Text(userManager.currentUser?.email ?? "")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.cosmicWhite.opacity(0.55))

                    HStack(spacing: 6) {
                        Image(systemName: storeManager.hasActiveSubscription ? "crown.fill" : "sparkle")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(storeManager.hasActiveSubscription ? .cosmicGold : .cosmicWhite.opacity(0.5))

                        Text(storeManager.subscriptionDisplayName)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(storeManager.hasActiveSubscription ? .cosmicGold : .cosmicWhite.opacity(0.6))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(Color(red: 0.12, green: 0.12, blue: 0.18))
                            .overlay(
                                Capsule()
                                    .stroke(
                                        storeManager.hasActiveSubscription
                                            ? Color.cosmicGold.opacity(0.5)
                                            : Color.cosmicWhite.opacity(0.1),
                                        lineWidth: 1
                                    )
                            )
                    )
                }
            }
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Your Journey")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundColor(.cosmicWhite)

            HStack(spacing: 12) {
                StatCard(
                    title: "Boards",
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

    // MARK: - Subscription

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Subscription")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundColor(.cosmicWhite)

            VStack(spacing: 16) {
                if storeManager.hasActiveSubscription {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.18))
                                .frame(width: 44, height: 44)
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Active Subscription")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundColor(.cosmicWhite)
                            Text("You have access to all premium features")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.cosmicWhite.opacity(0.6))
                        }

                        Spacer()
                    }

                    // Active subscription detail badge
                    if let productID = storeManager.activeProductID {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundColor(.cosmicWhite.opacity(0.5))
                            Text(productID.capitalized + " plan")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundColor(.cosmicWhite.opacity(0.5))
                        }
                    }

                    Button("Manage Subscription") {
                        showingCustomerCenter = true
                    }
                    .cosmicButton()
                    .frame(maxWidth: .infinity)
                } else {
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(Color.cosmicGold.opacity(0.18))
                                .frame(width: 44, height: 44)
                            Image(systemName: "crown.fill")
                                .foregroundColor(.cosmicGold)
                                .font(.title3)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Upgrade to Pro")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundColor(.cosmicWhite)
                            Text("Unlock unlimited boards and premium features")
                                .font(.system(.caption, design: .rounded))
                                .foregroundColor(.cosmicWhite.opacity(0.6))
                        }

                        Spacer()
                    }

                    Button("View Plans") {
                        showingSubscriptionView = true
                    }
                    .cosmicButton()
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(18)
            .cosmicGlowCard(color: storeManager.hasActiveSubscription ? .green : .cosmicGold)
        }
    }

    // MARK: - Settings

    private var settingsSection: some View {
        profileListSection(title: "Settings") {
            SettingsRow(icon: "bell.fill", iconColor: .cosmicPurple,
                        title: "Notifications", subtitle: "Manage your notification preferences") { }
            SettingsRow(icon: "photo.fill", iconColor: .cosmicBlue,
                        title: "Photo Quality", subtitle: "Choose image generation quality") { }
            SettingsRow(icon: "speaker.wave.2.fill", iconColor: .cosmicPink,
                        title: "Audio Settings", subtitle: "Configure affirmation audio") { }
            SettingsRow(icon: "lock.fill", iconColor: .cosmicGray,
                        title: "Privacy", subtitle: "Manage your privacy settings") { }
        }
    }

    // MARK: - Support

    private var supportSection: some View {
        profileListSection(title: "Support") {
            SettingsRow(icon: "person.crop.circle.badge.questionmark", iconColor: .cosmicPurple,
                        title: "Customer Center",
                        subtitle: "Manage billing, cancellations & refunds") {
                showingCustomerCenter = true
            }
            SettingsRow(icon: "questionmark.circle.fill", iconColor: .cosmicBlue,
                        title: "Help Center", subtitle: "Get answers to common questions") { }
            SettingsRow(icon: "envelope.fill", iconColor: .cosmicPink,
                        title: "Contact Support", subtitle: "Get help from our support team") { }
            SettingsRow(icon: "star.fill", iconColor: .cosmicGold,
                        title: "Rate the App", subtitle: "Share your experience on the App Store") { }
            SettingsRow(icon: "square.and.arrow.up.fill", iconColor: .cosmicBlue,
                        title: "Share App", subtitle: "Tell your friends about XVisionBoard AI") { }
        }
    }

    private func profileListSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title)
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundColor(.cosmicWhite)

            VStack(spacing: 0) {
                content()
            }
            .cosmicCard()
        }
    }

    // MARK: - Account Actions

    private var accountActionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Account")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundColor(.cosmicWhite)

            VStack(spacing: 10) {
                Button("Sign Out") {
                    showingSignOutAlert = true
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 0.11, green: 0.11, blue: 0.17))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.cosmicWhite.opacity(0.12), lineWidth: 1)
                        )
                )
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundColor(.cosmicWhite.opacity(0.85))

                Button("Delete Account") {
                    showingDeleteAccountAlert = true
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.red.opacity(0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.red.opacity(0.35), lineWidth: 1)
                        )
                )
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundColor(.red.opacity(0.85))
            }
        }
    }
}

// MARK: - Supporting Views

struct SettingsRow: View {
    let icon: String
    var iconColor: Color = .cosmicPurple
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(iconColor.opacity(0.18))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundColor(.cosmicWhite)

                    Text(subtitle)
                        .font(.system(.caption, design: .rounded))
                        .foregroundColor(.cosmicWhite.opacity(0.55))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.cosmicWhite.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.cosmicWhite.opacity(0.06))
                .frame(height: 0.5)
                .padding(.leading, 64)
        }
    }
}

#Preview {
    ProfileView()
        .environment(UserManager())
        .environment(StoreManager())
        .environment(VisionBoardManager())
}
