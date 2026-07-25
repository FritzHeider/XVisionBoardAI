//
//  SubscriptionView.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import SwiftUI
import RevenueCat
import RevenueCatUI

// MARK: - SubscriptionView
// Presents the RevenueCat Paywall configured in the RC dashboard.
// Falls back to a hand-crafted paywall if no RC template is configured.

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) var storeManager

    var body: some View {
        if let offering = storeManager.currentOffering {
            PaywallView(offering: offering, displayCloseButton: true)
                .onPurchaseCompleted { customerInfo in
                    storeManager.customerInfo = customerInfo
                    dismiss()
                }
                .onRestoreCompleted { customerInfo in
                    storeManager.customerInfo = customerInfo
                    dismiss()
                }
                .onPurchaseCancelled {
                    dismiss()
                }
        } else {
            // Fallback: no offering configured yet (SDK still loading)
            FallbackPaywallView()
        }
    }
}

// MARK: - FallbackPaywallView
// Shown only when the RC offering hasn't loaded. Provides basic upgrade UI
// and retries loading the offering on appear.

private struct FallbackPaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) var storeManager
    @State private var infoMessage: String?

    // Apple's standard EULA; replace privacyPolicyURL with the app's hosted policy before release.
    private static let termsURL = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!
    private static let privacyPolicyURL = URL(string: "https://xvisionboardai.com/privacy")!

    private var trialBadgeText: String? {
        guard let product = storeManager.fallbackProduct else { return nil }
        if product.introductoryDiscount?.paymentMode == .freeTrial {
            return "Free Trial — then \(product.localizedPriceString)/year"
        }
        return "\(product.localizedPriceString)/year"
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.astralBlack.ignoresSafeArea()

                Ellipse()
                    .fill(Color.astralViolet.opacity(0.15))
                    .frame(width: 340, height: 340)
                    .blur(radius: 90)
                    .offset(x: 60, y: -200)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: AstralTheme.Spacing.xl) {
                        // Header
                        VStack(spacing: AstralTheme.Spacing.md) {
                            ZStack {
                                Circle()
                                    .fill(Color.astralGold.opacity(0.15))
                                    .frame(width: 100, height: 100)
                                    .blur(radius: 16)
                                Circle()
                                    .strokeBorder(Color.astralGold.opacity(0.4), lineWidth: 1.5)
                                    .frame(width: 88, height: 88)
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 44, weight: .semibold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.astralGold, .orange],
                                            startPoint: .top, endPoint: .bottom
                                        )
                                    )
                            }
                            .astralPulsing()

                            Text("Unlock ManifestMe Pro")
                                .font(.system(.title, design: .rounded, weight: .bold))
                                .foregroundStyle(Color.astralText)
                                .multilineTextAlignment(.center)

                            Text("Create unlimited personalized vision boards and accelerate your manifestation journey.")
                                .font(.system(.body, design: .rounded))
                                .foregroundStyle(Color.astralTextMuted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }
                        .padding(.top, AstralTheme.Spacing.sm)

                        // Price badge — only shown once real product data has loaded
                        if let badgeText = trialBadgeText {
                            HStack(spacing: 6) {
                                Image(systemName: "gift.fill")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.astralGold)
                                Text(badgeText)
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundStyle(Color.astralGold)
                            }
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background {
                                Capsule()
                                    .fill(Color.astralGold.opacity(0.12))
                                    .overlay { Capsule().strokeBorder(Color.astralGold.opacity(0.35), lineWidth: 1) }
                            }
                        }

                        // Feature highlights
                        VStack(spacing: AstralTheme.Spacing.md) {
                            featureRow("Unlimited Vision Boards",      icon: "infinity",              color: .astralViolet)
                            featureRow("HD Export & Wallpaper",        icon: "photo.fill",            color: .astralIndigo)
                            featureRow("AI-Generated Affirmations",    icon: "sparkles",              color: .astralGold)
                            featureRow("Offline Image Caching",        icon: "icloud.and.arrow.down", color: .astralRose)
                            featureRow("Daily Reminder Notifications", icon: "bell.badge.fill",       color: .astralViolet)
                            featureRow("Priority Support",             icon: "headphones",            color: .astralIndigo)
                        }
                        .padding(AstralTheme.Spacing.lg)
                        .astralGlass(tint: .astralViolet)

                        // Purchase / loading state
                        if storeManager.isLoading {
                            ProgressView()
                                .tint(Color.astralViolet)
                                .scaleEffect(1.4)
                        } else if let product = storeManager.fallbackProduct {
                            VStack(spacing: AstralTheme.Spacing.sm) {
                                Button {
                                    Task {
                                        if await storeManager.purchase(product: product) {
                                            dismiss()
                                        }
                                    }
                                } label: {
                                    Text("Subscribe — \(product.localizedPriceString)/year")
                                        .font(.system(.headline, design: .rounded, weight: .bold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 16)
                                        .background {
                                            Capsule().fill(
                                                LinearGradient(
                                                    colors: [.astralViolet, .astralIndigo],
                                                    startPoint: .leading, endPoint: .trailing
                                                )
                                            )
                                        }
                                        .foregroundStyle(Color.astralText)
                                }

                                Text("Auto-renews yearly until cancelled. Cancel anytime in Settings.")
                                    .font(.system(.caption2, design: .rounded))
                                    .foregroundStyle(Color.astralTextMuted)
                                    .multilineTextAlignment(.center)
                            }
                        } else {
                            VStack(spacing: AstralTheme.Spacing.sm) {
                                Text("Loading subscription options…")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundStyle(Color.astralTextMuted)

                                Button("Retry") {
                                    Task {
                                        await storeManager.fetchCurrentOffering()
                                        await storeManager.fetchFallbackProduct()
                                    }
                                }
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundStyle(Color.astralViolet)
                            }
                        }

                        Button("Restore Purchases") {
                            Task {
                                if await storeManager.restorePurchases() {
                                    dismiss()
                                } else if storeManager.errorMessage == nil {
                                    infoMessage = "No previous purchases were found for this Apple Account."
                                }
                            }
                        }
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(Color.astralTextMuted)

                        // Legal links (required on subscription purchase screens)
                        HStack(spacing: AstralTheme.Spacing.lg) {
                            Link("Terms of Use", destination: Self.termsURL)
                            Link("Privacy Policy", destination: Self.privacyPolicyURL)
                        }
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(Color.astralTextMuted)

                        Spacer(minLength: 60)
                    }
                    .padding(.horizontal, AstralTheme.Spacing.xl)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(Color.astralTextMuted)
                }
            }
        }
        .task {
            await storeManager.fetchCurrentOffering()
            if storeManager.currentOffering == nil {
                await storeManager.fetchFallbackProduct()
            }
        }
        .alert("Something Went Wrong", isPresented: Binding(
            get: { storeManager.errorMessage != nil },
            set: { if !$0 { storeManager.errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(storeManager.errorMessage ?? "")
        }
        .alert("Restore Purchases", isPresented: Binding(
            get: { infoMessage != nil },
            set: { if !$0 { infoMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(infoMessage ?? "")
        }
    }

    private func featureRow(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: AstralTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AstralTheme.Radius.sm)
                    .fill(color.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(color)
            }
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(Color.astralText)
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(Color.astralSuccess)
        }
    }
}

// MARK: - Paywall Gating Modifier

extension View {
    /// Presents a RevenueCat Paywall if the user doesn't have the Pro entitlement.
    func requiresProEntitlement(isPresented: Binding<Bool>) -> some View {
        self.sheet(isPresented: isPresented) {
            SubscriptionView()
        }
    }
}

#Preview {
    SubscriptionView()
        .environment(StoreManager())
        .environment(UserManager())
}
