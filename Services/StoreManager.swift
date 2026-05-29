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

    // MARK: - Constants

    /// The RevenueCat entitlement identifier configured in the dashboard.
    static let entitlementID = "XVisionBoardAI Pro"

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
    var isPremiumUser: Bool { hasActiveSubscription }

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

    /// Restores previous purchases.
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        do {
            customerInfo = try await Purchases.shared.restorePurchases()
        } catch {
            errorMessage = "Restore failed: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - User Identity

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

    func canExportHD() -> Bool { hasActiveSubscription }
    func canUseAdvancedAI() -> Bool { hasActiveSubscription }

    func maxVisionBoards() -> Int {
        hasActiveSubscription ? -1 : 1
    }
}
