//
//  StoreManager.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import Foundation
import SwiftUI
import RevenueCat

// MARK: - StoreManager

@MainActor
@Observable
class StoreManager {

    // MARK: - Published State

    var customerInfo: CustomerInfo?
    var currentOffering: Offering?
    var isLoading = false
    var errorMessage: String?

    /// Products fetched directly by ID when no Offering is available (fallback paywall),
    /// ordered weekly → monthly → yearly.
    var fallbackProducts: [StoreProduct] = []

    // MARK: - Constants

    /// The RevenueCat entitlement identifier configured in the dashboard.
    static let entitlementID = "XVisionBoardAI Pro"

    /// Pro is sold as three durations; all map to the single entitlement above.
    /// These MUST match the product IDs in App Store Connect + RevenueCat.
    static let weeklyProductID  = "com.xvisionboardai.pro.weekly"
    static let monthlyProductID = "com.xvisionboardai.pro.monthly"
    static let yearlyProductID  = "com.xvisionboardai.pro.yearly"
    static let allProductIDs = [weeklyProductID, monthlyProductID, yearlyProductID]

    private static let apiKey = "appl_mJajGcFwBUCbnMHNmzkWYhdRDcR"

    // MARK: - SDK Configuration (call once at app launch, before init)

    static func configure() {
        Purchases.configure(withAPIKey: apiKey)
#if DEBUG
        Purchases.logLevel = .debug
#else
        Purchases.logLevel = .error
#endif
    }

    // MARK: - Init

    init() {
        Task {
            await refreshCustomerInfo()
            await fetchCurrentOffering()
        }
    }

    // MARK: - Customer Info

    /// Fetches the latest CustomerInfo from RevenueCat.
    func refreshCustomerInfo() async {
        do {
            customerInfo = try await Purchases.shared.customerInfo()
        } catch {
            print("[RevenueCat] refreshCustomerInfo: \(error.localizedDescription)")
        }
    }

    /// Fetches the current Offering from RevenueCat (used by PaywallView and manual UIs).
    func fetchCurrentOffering() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            currentOffering = offerings.current
        } catch {
            print("[RevenueCat] fetchCurrentOffering: \(error.localizedDescription)")
        }
    }

    /// Fetches all Pro products directly, for the fallback paywall when no Offering loads.
    /// Ordered weekly → monthly → yearly regardless of the order RevenueCat returns them.
    func fetchFallbackProducts() async {
        guard fallbackProducts.isEmpty else { return }
        let products = await Purchases.shared.products(Self.allProductIDs)
        let order = Self.allProductIDs
        fallbackProducts = products.sorted {
            (order.firstIndex(of: $0.productIdentifier) ?? .max) <
            (order.firstIndex(of: $1.productIdentifier) ?? .max)
        }
    }

    // MARK: - Entitlement Status

    /// `true` when the user has an active "XVisionBoardAI Pro" entitlement.
    var hasActiveSubscription: Bool {
        customerInfo?.entitlements[Self.entitlementID]?.isActive == true
    }

    /// The active `EntitlementInfo` for "XVisionBoardAI Pro", or `nil` if inactive.
    var activeEntitlement: EntitlementInfo? {
        customerInfo?.entitlements[Self.entitlementID]
    }

    /// The product identifier of the active subscription (e.g. "yearly"), or `nil`.
    var activeProductID: String? {
        customerInfo?.activeSubscriptions.first
    }

    /// Maps the entitlement to our internal `SubscriptionType` for display purposes.
    var currentSubscription: SubscriptionType {
        hasActiveSubscription ? .pro : .free
    }

    var subscriptionDisplayName: String { currentSubscription.displayName }
    var isProUser: Bool { hasActiveSubscription }

    // MARK: - Purchasing

    /// Purchases a RevenueCat `Package` (obtained from `currentOffering`).
    /// Returns `true` on successful purchase, `false` on cancellation or error.
    func purchase(package: Package) async -> Bool {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await Purchases.shared.purchase(package: package)
            customerInfo = result.customerInfo
            isLoading = false
            return !result.userCancelled
        } catch {
            // Don't surface cancellation as an error
            let isCancel = (error as NSError).domain == "RevenueCat.ErrorCode" &&
                           (error as NSError).code == 1 // purchaseCancelledError
            if !isCancel {
                errorMessage = error.localizedDescription
            }
            isLoading = false
            return false
        }
    }

    /// Purchases a `StoreProduct` directly (fallback paywall path, no Offering needed).
    /// Returns `true` on successful purchase, `false` on cancellation or error.
    func purchase(product: StoreProduct) async -> Bool {
        isLoading = true
        errorMessage = nil
        do {
            let result = try await Purchases.shared.purchase(product: product)
            customerInfo = result.customerInfo
            isLoading = false
            return !result.userCancelled
        } catch {
            let isCancel = (error as NSError).domain == "RevenueCat.ErrorCode" &&
                           (error as NSError).code == 1 // purchaseCancelledError
            if !isCancel {
                errorMessage = error.localizedDescription
            }
            isLoading = false
            return false
        }
    }

    /// Restores previous purchases. Returns `true` when an active entitlement was restored.
    @discardableResult
    func restorePurchases() async -> Bool {
        isLoading = true
        errorMessage = nil
        do {
            customerInfo = try await Purchases.shared.restorePurchases()
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
        isLoading = false
        return hasActiveSubscription
    }

    // MARK: - User Identity

    /// ⚠️ BOTH METHODS BELOW ARE INTENTIONALLY UNUSED. Do not wire them up
    /// without reading this.
    ///
    /// RevenueCat runs with an anonymous app user ID and that is correct here.
    /// Entitlement is derived from the buyer's **Apple Account** receipt, not
    /// from our app account — which is just as well, because our accounts are
    /// device-local with no backend, and users can now enter as guests with no
    /// account at all (`UserManager.isGuest`).
    ///
    /// Calling `logOut()` without ever calling `logIn` is actively harmful: it
    /// rotates to a *new* anonymous ID, so a paying user can show as non-Pro
    /// until `customerInfo()` refreshes or they tap Restore. That was happening
    /// on every sign-out until it was removed from `ProfileView`.
    ///
    /// These become useful only if a real backend with stable server-side user
    /// IDs is introduced — at which point call `login(userID:)` on sign-in *and*
    /// `logout()` on sign-out, as a matched pair, never one alone.

    /// Associates RevenueCat with a specific app user. Call after login.
    func login(userID: String) async {
        do {
            let (info, _) = try await Purchases.shared.logIn(userID)
            customerInfo = info
        } catch {
            print("[RevenueCat] logIn error: \(error.localizedDescription)")
        }
    }

    /// Resets RevenueCat to an anonymous ID. Call on sign-out.
    func logout() async {
        do {
            customerInfo = try await Purchases.shared.logOut()
        } catch {
            print("[RevenueCat] logOut error: \(error.localizedDescription)")
        }
    }

    // MARK: - Feature Gating

    func canCreateVisionBoard(currentCount: Int) -> Bool {
        hasActiveSubscription || currentCount < 1
    }

    /// Pro exports render at HD width with no watermark; free exports are
    /// standard resolution and watermarked. Enforced in
    /// `VisionBoardDetailView.renderBoardImage()`.
    func canExportHD() -> Bool { hasActiveSubscription }

    /// Spoken affirmations ("Read Aloud"). Enforced in `VisionBoardDetailView`.
    func canUseAudioAffirmations() -> Bool { hasActiveSubscription }

    func maxVisionBoards() -> Int {
        hasActiveSubscription ? -1 : 1
    }
}
