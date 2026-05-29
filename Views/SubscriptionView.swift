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

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cosmicBlack.ignoresSafeArea()

                RadialGradient(
                    colors: [Color.cosmicPurple.opacity(0.15), Color.clear],
                    center: .top,
                    startRadius: 0,
                    endRadius: 400
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(Color.cosmicGold.opacity(0.15))
                                    .frame(width: 100, height: 100)
                                Image(systemName: "crown.fill")
                                    .font(.system(size: 48, weight: .semibold))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.cosmicGold, .orange],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            }
                            .pulsing()

                            Text("Unlock XVisionBoard AI Pro")
                                .font(.system(.title, design: .rounded, weight: .bold))
                                .foregroundColor(.cosmicWhite)
                                .multilineTextAlignment(.center)

                            Text("Create unlimited personalized vision boards and accelerate your manifestation journey.")
                                .font(.system(.body, design: .rounded))
                                .foregroundColor(.cosmicWhite.opacity(0.7))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }
                        .padding(.top, 8)

                        // Feature highlights
                        VStack(spacing: 14) {
                            featureRow("Unlimited Vision Boards",      icon: "infinity",             color: .cosmicPurple)
                            featureRow("HD Export & Wallpaper",        icon: "photo.fill",           color: .cosmicBlue)
                            featureRow("AI-Generated Affirmations",    icon: "sparkles",             color: .cosmicGold)
                            featureRow("Offline Image Caching",        icon: "icloud.and.arrow.down",color: .cosmicPink)
                            featureRow("Daily Reminder Notifications", icon: "bell.badge.fill",      color: .cosmicPurple)
                            featureRow("Priority Support",             icon: "headphones",           color: .cosmicBlue)
                        }
                        .padding(20)
                        .cosmicGlowCard(color: .cosmicPurple)

                        // Loading/error state
                        if storeManager.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .cosmicPurple))
                                .scaleEffect(1.4)
                        } else if storeManager.currentOffering == nil {
                            VStack(spacing: 12) {
                                Text("Loading subscription options…")
                                    .font(.system(.subheadline, design: .rounded))
                                    .foregroundColor(.cosmicWhite.opacity(0.6))

                                Button("Retry") {
                                    Task { await storeManager.fetchCurrentOffering() }
                                }
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundColor(.cosmicPurple)
                            }
                        }

                        // Restore
                        Button("Restore Purchases") {
                            Task { await storeManager.restorePurchases() }
                        }
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundColor(.cosmicWhite.opacity(0.5))

                        Spacer(minLength: 60)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.cosmicWhite)
                }
            }
        }
        .task {
            await storeManager.fetchCurrentOffering()
        }
    }

    private func featureRow(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.18))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }
            Text(title)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundColor(.cosmicWhite)
            Spacer()
            Image(systemName: "checkmark")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.green.opacity(0.8))
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
