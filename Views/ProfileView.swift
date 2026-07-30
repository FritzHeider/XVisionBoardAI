import SwiftUI
import RevenueCatUI
import StoreKit

struct ProfileView: View {
    @Environment(UserManager.self) var userManager
    @Environment(StoreManager.self) var storeManager
    @Environment(VisionBoardManager.self) var visionBoardManager
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview

    @State private var showingSubscriptionView = false
    @State private var showingCustomerCenter = false
    @State private var showingSignOutAlert = false
    @State private var showingDeleteAccountAlert = false
    @State private var showingNotificationSettings = false
    @State private var showingSignUp = false
    /// Working copy for the picker; committed to UserManager on Save so that
    /// cancelling the sheet doesn't silently change the schedule.
    @State private var reminderTime: Date = UserManager.defaultReminderTime

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
                        legalSection
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
        .sheet(isPresented: $showingSignUp) { SignUpView() }
        // Customer Center is where users cancel, change plan, or request refunds,
        // so entitlement state is stale the moment it closes.
        .sheet(isPresented: $showingCustomerCenter, onDismiss: {
            Task { await storeManager.refreshCustomerInfo() }
        }) { CustomerCenterView() }
        .sheet(isPresented: $showingNotificationSettings) {
            notificationSettingsSheet
                // Seed the picker from the saved value each time it opens.
                .onAppear { reminderTime = userManager.reminderTime }
        }
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Sign Out", role: .destructive) {
                // Deliberately does NOT call Purchases.logOut(): nothing ever
                // calls logIn, so RevenueCat runs anonymous and logging out just
                // rotates to a fresh anonymous ID, briefly showing a paying user
                // as non-Pro. The entitlement comes from the Apple Account
                // receipt, which is unchanged by signing out of our own app.
                userManager.signOut()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to sign out? Your vision boards stay on this device.")
        }
        .alert(destructiveActionTitle, isPresented: $showingDeleteAccountAlert) {
            Button("Delete", role: .destructive) {
                Task { await userManager.deleteAccount(boardManager: visionBoardManager) }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(userManager.isGuest
                 ? "This will permanently delete all your vision boards and reset the app. This action cannot be undone."
                 : "This will permanently delete your account and all vision boards. This action cannot be undone.")
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

                // A guest has no email, so the line would otherwise render blank.
                Text(userManager.isGuest
                     ? "Guest · saved on this device"
                     : (userManager.currentUser?.email ?? ""))
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Color.astralTextMuted)

                // Tier badge
                HStack(spacing: 6) {
                    Image(systemName: storeManager.hasActiveSubscription ? "crown.fill" : "sparkle")
                        .scaledFont(size: 12, relativeTo: .caption, weight: .semibold)
                        .foregroundStyle(storeManager.hasActiveSubscription ? Color.astralGold : Color.astralTextMuted)

                    Text(storeManager.subscriptionDisplayName)
                        .scaledFont(size: 13, relativeTo: .caption, weight: .semibold, design: .rounded)
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
                                .scaledFont(size: 12, relativeTo: .caption, design: .rounded)
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

    /// Every row in this screen must do something. Rows that were previously
    /// rendered disabled with a "Coming soon" pill were removed — App Review
    /// opens Settings and taps each one, and a screen of inert rows reads as an
    /// incomplete app under Guideline 2.1.
    private var settingsSection: some View {
        profileListSection("Settings") {
            SettingsRow(icon: "bell.fill", iconColor: .astralViolet,
                        title: "Notifications", subtitle: "Daily reminder at \(formattedReminderTime)") {
                showingNotificationSettings = true
            }
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
            SettingsRow(icon: "envelope.fill", iconColor: .astralRose,
                        title: "Contact Support", subtitle: AppLinks.supportEmail) {
                openURL(AppLinks.supportMailto)
            }
            SettingsRow(icon: "star.fill", iconColor: .astralGold,
                        title: "Rate the App", subtitle: "Share your experience on the App Store") {
                requestReview()
            }
            ShareLink(item: AppLinks.marketingSite,
                      subject: Text("ManifestMe"),
                      message: Text("I'm using ManifestMe to build AI vision boards of my dream life.")) {
                SettingsRowLabel(icon: "square.and.arrow.up.fill", iconColor: .astralIndigo,
                                 title: "Share App", subtitle: "Tell your friends about ManifestMe")
            }
        }
    }

    // MARK: - Legal

    /// Guideline 5.1.1(i) requires the privacy policy to be reachable inside
    /// the app, not only from App Store Connect metadata. It is also linked on
    /// the paywall, but a user who never opens the paywall must still find it.
    private var legalSection: some View {
        profileListSection("Legal") {
            SettingsRow(icon: "lock.fill", iconColor: .astralTextMuted,
                        title: "Privacy Policy", subtitle: "How your data is used and shared") {
                openURL(AppLinks.privacyPolicy)
            }
            SettingsRow(icon: "doc.text.fill", iconColor: .astralTextMuted,
                        title: "Terms of Use", subtitle: "Standard Apple EULA") {
                openURL(AppLinks.termsOfUse)
            }
        }
    }

    // MARK: - Account Actions

    private var accountActionsSection: some View {
        VStack(alignment: .leading, spacing: AstralTheme.Spacing.md) {
            sectionHeader("Account")

            VStack(spacing: AstralTheme.Spacing.sm) {
                // Guests can claim an account without signing out first, so the
                // guest path isn't a one-way door.
                if userManager.isGuest {
                    Button("Create an Account") { showingSignUp = true }
                        .astralButton(.primary)
                        .frame(maxWidth: .infinity)
                }

                Button("Sign Out") { showingSignOutAlert = true }
                    .astralButton(.secondary)
                    .frame(maxWidth: .infinity)

                Button(destructiveActionTitle) { showingDeleteAccountAlert = true }
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

    /// A guest has no account to delete, but the data wipe is still offered.
    private var destructiveActionTitle: String {
        userManager.isGuest ? "Delete All My Data" : "Delete Account"
    }

    private var formattedReminderTime: String { userManager.formattedReminderTime }

    private var notificationSettingsSheet: some View {
        NavigationStack {
            ZStack {
                Color.astralBlack.ignoresSafeArea()
                VStack(spacing: AstralTheme.Spacing.xl) {
                    VStack(spacing: AstralTheme.Spacing.sm) {
                        Image(systemName: "bell.badge.fill")
                            .font(.system(size: 44))
                            .foregroundStyle(Color.auroraGradient)
                        Text("Daily Reminder")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(Color.astralText)
                        Text("We'll remind you to visualize your boards and stay aligned with your goals.")
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(Color.astralTextMuted)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, AstralTheme.Spacing.xl)

                    DatePicker("Reminder Time", selection: $reminderTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                        // .colorScheme(.dark) removed: the root now locks the
                        // scheme, so this local workaround is redundant.
                        .padding(AstralTheme.Spacing.lg)
                        .astralCard()
                        .padding(.horizontal, AstralTheme.Spacing.lg)

                    Button("Save Reminder") {
                        userManager.reminderTime = reminderTime
                        showingNotificationSettings = false
                    }
                    .astralButton(.primary)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, AstralTheme.Spacing.lg)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showingNotificationSettings = false }
                        .foregroundStyle(Color.astralTextMuted)
                }
            }
        }
    }

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

/// The row chrome, without any tap behavior. Split out from `SettingsRow` so a
/// `ShareLink` can present an identical-looking row.
///
/// There is deliberately no disabled/"Coming soon" variant: a settings row that
/// does nothing is a Guideline 2.1 completeness finding, so unfinished features
/// are omitted from the screen instead of shown greyed out.
struct SettingsRowLabel: View {
    let icon: String
    var iconColor: Color = .astralViolet
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: AstralTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: 9)
                    .fill(iconColor.opacity(0.18))
                    .frame(width: 34, height: 34)
                Image(systemName: icon)
                    .scaledFont(size: 15, relativeTo: .footnote, weight: .semibold)
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
                .scaledFont(size: 12, relativeTo: .caption, weight: .semibold)
                .foregroundStyle(Color.astralTextDim)
        }
        .padding(.horizontal, AstralTheme.Spacing.md)
        .padding(.vertical, AstralTheme.Spacing.md)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 0.5)
                .padding(.leading, 64)
        }
    }
}

struct SettingsRow: View {
    let icon: String
    var iconColor: Color = .astralViolet
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            SettingsRowLabel(icon: icon, iconColor: iconColor, title: title, subtitle: subtitle)
        }
    }
}

#Preview {
    ProfileView()
        .environment(UserManager())
        .environment(StoreManager())
        .environment(VisionBoardManager())
}
