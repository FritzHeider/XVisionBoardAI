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
                Color.astralBlack.ignoresSafeArea()

                Ellipse()
                    .fill(Color.astralViolet.opacity(0.12))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: 80, y: -200)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AstralTheme.Spacing.xl) {
                        profileHeader
                        statsSection
                        subscriptionSection
                        settingsSection
                        supportSection
                        accountActionsSection
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, AstralTheme.Spacing.lg)
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
        .sheet(isPresented: $showingSubscriptionView) { SubscriptionView() }
        .sheet(isPresented: $showingCustomerCenter) { CustomerCenterView() }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Sign Out", role: .destructive) {
                Task {
                    await storeManager.logout()
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
    }

    // MARK: - Profile Header

    private var profileHeader: some View {
        VStack(spacing: AstralTheme.Spacing.md) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.auroraGradient)
                    .frame(width: 120, height: 120)
                    .opacity(0.15)
                    .blur(radius: 20)

                Circle()
                    .strokeBorder(Color.auroraGradient, lineWidth: 2.5)
                    .frame(width: 104, height: 104)

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
                                colors: [Color.astralViolet.opacity(0.35), Color.astralIndigo.opacity(0.2)],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .overlay {
                            Image(systemName: "person.fill")
                                .font(.system(size: 44, weight: .medium))
                                .foregroundStyle(Color.astralViolet)
                        }
                }
            }

            VStack(spacing: AstralTheme.Spacing.xs) {
                Text(userManager.currentUser?.username ?? "Dreamer")
                    .font(.system(.title2, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.astralText)

                Text(userManager.currentUser?.email ?? "")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.astralTextMuted)

                // Tier badge
                HStack(spacing: 6) {
                    Image(systemName: storeManager.hasActiveSubscription ? "crown.fill" : "sparkle")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(storeManager.hasActiveSubscription ? Color.astralGold : Color.astralTextMuted)

                    Text(storeManager.subscriptionDisplayName)
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(storeManager.hasActiveSubscription ? Color.astralGold : Color.astralTextMuted)
                }
                .padding(.horizontal, AstralTheme.Spacing.md)
                .padding(.vertical, 7)
                .background {
                    Capsule()
                        .fill(Color.astralSurface)
                        .overlay {
                            Capsule()
                                .strokeBorder(
                                    storeManager.hasActiveSubscription
                                        ? Color.astralGold.opacity(0.45)
                                        : Color.white.opacity(0.08),
                                    lineWidth: 1
                                )
                        }
                }
            }
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        VStack(alignment: .leading, spacing: AstralTheme.Spacing.md) {
            sectionHeader("Your Journey")

            HStack(spacing: AstralTheme.Spacing.sm) {
                StatCard(title: "Boards", value: "\(visionBoardManager.totalVisionBoards)",
                         icon: "photo.stack.fill", color: .astralViolet)
                StatCard(title: "Total Views", value: "\(visionBoardManager.totalViews)",
                         icon: "eye.fill", color: .astralIndigo)
                StatCard(title: "Favorites", value: "\(visionBoardManager.favoriteVisionBoards.count)",
                         icon: "heart.fill", color: .astralRose)
            }
        }
    }

    // MARK: - Subscription

    private var subscriptionSection: some View {
        VStack(alignment: .leading, spacing: AstralTheme.Spacing.md) {
            sectionHeader("Subscription")

            VStack(spacing: AstralTheme.Spacing.md) {
                if storeManager.hasActiveSubscription {
                    HStack(spacing: AstralTheme.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(Color.astralSuccess.opacity(0.18))
                                .frame(width: 44, height: 44)
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(Color.astralSuccess)
                                .font(.title3)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Active Subscription")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundStyle(Color.astralText)
                            Text("You have access to all premium features")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(Color.astralTextMuted)
                        }

                        Spacer()
                    }

                    if let productID = storeManager.activeProductID {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundStyle(Color.astralTextMuted)
                            Text(productID.capitalized + " plan")
                                .font(.system(size: 12, design: .rounded))
                                .foregroundStyle(Color.astralTextMuted)
                        }
                    }

                    Button("Manage Subscription") { showingCustomerCenter = true }
                        .astralButton(.secondary)
                        .frame(maxWidth: .infinity)
                } else {
                    HStack(spacing: AstralTheme.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(Color.astralGold.opacity(0.18))
                                .frame(width: 44, height: 44)
                            Image(systemName: "crown.fill")
                                .foregroundStyle(Color.astralGold)
                                .font(.title3)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text("Upgrade to Pro")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundStyle(Color.astralText)
                            Text("Unlock unlimited boards and premium features")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(Color.astralTextMuted)
                        }

                        Spacer()
                    }

                    Button("View Plans") { showingSubscriptionView = true }
                        .astralButton(.gold)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(AstralTheme.Spacing.lg)
            .astralGlass(tint: storeManager.hasActiveSubscription ? .astralSuccess : .astralGold)
        }
    }

    // MARK: - Settings

    private var settingsSection: some View {
        profileListSection("Settings") {
            SettingsRow(icon: "bell.fill", iconColor: .astralViolet,
                        title: "Notifications", subtitle: "Manage your notification preferences") { }
            SettingsRow(icon: "photo.fill", iconColor: .astralIndigo,
                        title: "Photo Quality", subtitle: "Choose image generation quality") { }
            SettingsRow(icon: "speaker.wave.2.fill", iconColor: .astralRose,
                        title: "Audio Settings", subtitle: "Configure affirmation audio") { }
            SettingsRow(icon: "lock.fill", iconColor: .astralTextMuted,
                        title: "Privacy", subtitle: "Manage your privacy settings") { }
        }
    }

    // MARK: - Support

    private var supportSection: some View {
        profileListSection("Support") {
            SettingsRow(icon: "person.crop.circle.badge.questionmark", iconColor: .astralViolet,
                        title: "Customer Center",
                        subtitle: "Manage billing, cancellations & refunds") {
                showingCustomerCenter = true
            }
            SettingsRow(icon: "questionmark.circle.fill", iconColor: .astralIndigo,
                        title: "Help Center", subtitle: "Get answers to common questions") { }
            SettingsRow(icon: "envelope.fill", iconColor: .astralRose,
                        title: "Contact Support", subtitle: "Get help from our support team") { }
            SettingsRow(icon: "star.fill", iconColor: .astralGold,
                        title: "Rate the App", subtitle: "Share your experience on the App Store") { }
            SettingsRow(icon: "square.and.arrow.up.fill", iconColor: .astralIndigo,
                        title: "Share App", subtitle: "Tell your friends about ManifestMe") { }
        }
    }

    // MARK: - Account Actions

    private var accountActionsSection: some View {
        VStack(alignment: .leading, spacing: AstralTheme.Spacing.md) {
            sectionHeader("Account")

            VStack(spacing: AstralTheme.Spacing.sm) {
                Button("Sign Out") { showingSignOutAlert = true }
                    .astralButton(.secondary)
                    .frame(maxWidth: .infinity)

                Button("Delete Account") { showingDeleteAccountAlert = true }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, AstralTheme.Spacing.xl)
                    .padding(.vertical, AstralTheme.Spacing.md)
                    .background {
                        Capsule()
                            .fill(Color.astralError.opacity(0.12))
                            .overlay {
                                Capsule().strokeBorder(Color.astralError.opacity(0.35), lineWidth: 1)
                            }
                    }
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(Color.astralError)
            }
        }
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(.title3, design: .rounded, weight: .bold))
            .foregroundStyle(Color.astralText)
    }

    private func profileListSection<C: View>(_ title: String, @ViewBuilder content: () -> C) -> some View {
        VStack(alignment: .leading, spacing: AstralTheme.Spacing.md) {
            sectionHeader(title)

            VStack(spacing: 0) { content() }
                .astralCard()
        }
    }
}

// MARK: - SettingsRow

struct SettingsRow: View {
    let icon: String
    var iconColor: Color = .astralViolet
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: AstralTheme.Spacing.md) {
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(iconColor.opacity(0.18))
                        .frame(width: 34, height: 34)
                    Image(systemName: icon)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color.astralText)
                    Text(subtitle)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Color.astralTextMuted)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.astralTextDim)
            }
            .padding(.horizontal, AstralTheme.Spacing.md)
            .padding(.vertical, AstralTheme.Spacing.md)
        }
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.06))
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
