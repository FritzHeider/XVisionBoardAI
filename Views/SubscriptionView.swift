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
    @State private var restoreMessage: String?

    var body: some View {
        if let offering = storeManager.currentOffering {
            PaywallView(offering: offering, displayCloseButton: true)
                .onPurchaseCompleted { customerInfo in
                    storeManager.customerInfo = customerInfo
                    dismiss()
                }
                .onRestoreCompleted { customerInfo in
                    storeManager.customerInfo = customerInfo
                    // onRestoreCompleted fires when the restore *call* succeeds, not
                    // when an entitlement was found. Dismissing unconditionally makes
                    // a no-op restore look like the paywall closed for no reason.
                    if customerInfo.entitlements[StoreManager.entitlementID]?.isActive == true {
                        dismiss()
                    } else {
                        restoreMessage = "No previous purchases were found for this Apple Account."
                    }
                }
                // Deliberately no dismiss() on cancel: tapping Cancel on the system
                // sheet should return the user to the paywall to pick another plan,
                // not close the whole upgrade flow.
                .onPurchaseFailure { error in
                    storeManager.errorMessage = error.localizedDescription
                }
                .onRestoreFailure { error in
                    storeManager.errorMessage = "Restore failed: \(error.localizedDescription)"
                }
                .alert("Restore Purchases", isPresented: Binding<Bool>(
                    get: { restoreMessage != nil },
                    set: { if !$0 { restoreMessage = nil } }
                )) {
                    Button("OK") { restoreMessage = nil }
                } message: {
                    Text(restoreMessage ?? "")
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
    @State private var selectedProduct: StoreProduct?

    /// Human-readable billing period suffix, e.g. "week", "month", "year".
    private func periodLabel(_ product: StoreProduct) -> String {
        switch product.subscriptionPeriod?.unit {
        case .day:   return "day"
        case .week:  return "week"
        case .month: return "month"
        case .year:  return "year"
        default:     return "period"
        }
    }

    private func hasFreeTrial(_ product: StoreProduct) -> Bool {
        product.introductoryDiscount?.paymentMode == .freeTrial
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

                        // Plan selector — shown once real product data has loaded
                        if !storeManager.fallbackProducts.isEmpty {
                            VStack(spacing: AstralTheme.Spacing.sm) {
                                ForEach(storeManager.fallbackProducts, id: \.productIdentifier) { product in
                                    planRow(product)
                                }
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
                        } else if let product = selectedProduct ?? storeManager.fallbackProducts.last {
                            VStack(spacing: AstralTheme.Spacing.sm) {
                                Button {
                                    Task {
                                        if await storeManager.purchase(product: product) {
                                            dismiss()
                                        }
                                    }
                                } label: {
                                    Text(hasFreeTrial(product) ? "Start Free Trial" : "Subscribe")
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

                                Text(renewalTerms(product))
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
                                        await storeManager.fetchFallbackProducts()
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
                            Link("Terms of Use", destination: AppLinks.termsOfUse)
                            Link("Privacy Policy", destination: AppLinks.privacyPolicy)
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
                await storeManager.fetchFallbackProducts()
                // Default to the best-value (last = yearly) plan
                if selectedProduct == nil {
                    selectedProduct = storeManager.fallbackProducts.last
                }
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

    /// One selectable plan row (weekly / monthly / yearly).
    private func planRow(_ product: StoreProduct) -> some View {
        let isSelected = (selectedProduct ?? storeManager.fallbackProducts.last)?.productIdentifier == product.productIdentifier
        return Button {
            selectedProduct = product
        } label: {
            HStack(spacing: AstralTheme.Spacing.md) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .scaledFont(size: 20, relativeTo: .body)
                    .foregroundStyle(isSelected ? Color.astralViolet : Color.astralTextMuted)

                VStack(alignment: .leading, spacing: 2) {
                    Text(product.localizedTitle.isEmpty ? periodLabel(product).capitalized : product.localizedTitle)
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color.astralText)
                    if hasFreeTrial(product) {
                        Text("3-day free trial included")
                            .font(.system(.caption2, design: .rounded, weight: .semibold))
                            .foregroundStyle(Color.astralGold)
                    }
                }

                Spacer()

                Text("\(product.localizedPriceString)/\(periodLabel(product))")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(Color.astralText)
            }
            .padding(AstralTheme.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: AstralTheme.Radius.md)
                    .fill(Color.astralViolet.opacity(isSelected ? 0.16 : 0.05))
                    .overlay {
                        RoundedRectangle(cornerRadius: AstralTheme.Radius.md)
                            .strokeBorder(isSelected ? Color.astralViolet : Color.white.opacity(0.08),
                                          lineWidth: isSelected ? 1.5 : 1)
                    }
            }
        }
        .accessibilityLabel("\(periodLabel(product)) plan, \(product.localizedPriceString)\(hasFreeTrial(product) ? ", 3-day free trial" : "")")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }

    /// App Review requires the auto-renewal terms to be disclosed on the purchase screen.
    private func renewalTerms(_ product: StoreProduct) -> String {
        let period = periodLabel(product)
        let trial = hasFreeTrial(product) ? "3-day free trial, then " : ""
        return "\(trial)\(product.localizedPriceString) per \(period). Auto-renews until cancelled. Cancel anytime in Settings."
    }

    private func featureRow(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: AstralTheme.Spacing.md) {
            ZStack {
                RoundedRectangle(cornerRadius: AstralTheme.Radius.sm)
                    .fill(color.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .scaledFont(size: 16, relativeTo: .subheadline, weight: .semibold)
                    .foregroundStyle(color)
            }
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(Color.astralText)
            Spacer()
            Image(systemName: "checkmark")
                .scaledFont(size: 13, relativeTo: .caption, weight: .bold)
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
