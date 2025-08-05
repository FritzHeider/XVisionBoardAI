//
//  StoreManager.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import Foundation
import StoreKit
import SwiftUI

@MainActor
class StoreManager: ObservableObject {
    @Published var products: [Product] = []
    @Published var purchasedProducts: Set<String> = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let productIdentifiers: Set<String> = [
        "com.xvisionboardai.pro.monthly",
        "com.xvisionboardai.pro.yearly",
        "com.xvisionboardai.premium.monthly",
        "com.xvisionboardai.premium.yearly",
        "com.xvisionboardai.credits.small",
        "com.xvisionboardai.credits.medium",
        "com.xvisionboardai.credits.large"
    ]
    
    init() {
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }
    
    // MARK: - Product Loading
    
    func loadProducts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let storeProducts = try await Product.products(for: productIdentifiers)
            products = storeProducts.sorted { $0.price < $1.price }
        } catch {
            errorMessage = "Failed to load products: \(error.localizedDescription)"
            print("Failed to load products: \(error)")
        }
        
        isLoading = false
    }
    
    // MARK: - Purchase Handling
    
    func purchase(_ product: Product) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await product.purchase()
            
            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await updatePurchasedProducts()
                    await transaction.finish()
                    isLoading = false
                    return true
                case .unverified:
                    errorMessage = "Purchase could not be verified"
                    isLoading = false
                    return false
                }
            case .userCancelled:
                isLoading = false
                return false
            case .pending:
                errorMessage = "Purchase is pending approval"
                isLoading = false
                return false
            @unknown default:
                errorMessage = "Unknown purchase result"
                isLoading = false
                return false
            }
        } catch {
            errorMessage = "Purchase failed: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    // MARK: - Subscription Management
    
    func updatePurchasedProducts() async {
        var newPurchasedProducts: Set<String> = []
        
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result {
                newPurchasedProducts.insert(transaction.productID)
            }
        }
        
        purchasedProducts = newPurchasedProducts
    }
    
    func restorePurchases() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await AppStore.sync()
            await updatePurchasedProducts()
        } catch {
            errorMessage = "Failed to restore purchases: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Subscription Status
    
    var currentSubscription: SubscriptionType {
        if purchasedProducts.contains("com.xvisionboardai.premium.monthly") ||
           purchasedProducts.contains("com.xvisionboardai.premium.yearly") {
            return .premium
        } else if purchasedProducts.contains("com.xvisionboardai.pro.monthly") ||
                  purchasedProducts.contains("com.xvisionboardai.pro.yearly") {
            return .pro
        } else {
            return .free
        }
    }
    
    var hasActiveSubscription: Bool {
        currentSubscription != .free
    }
    
    // MARK: - Product Helpers
    
    func product(for identifier: String) -> Product? {
        products.first { $0.id == identifier }
    }
    
    var subscriptionProducts: [Product] {
        products.filter { product in
            product.id.contains("monthly") || product.id.contains("yearly")
        }
    }
    
    var creditProducts: [Product] {
        products.filter { product in
            product.id.contains("credits")
        }
    }
    
    // MARK: - Pricing Display
    
    func formattedPrice(for product: Product) -> String {
        product.displayPrice
    }
    
    func monthlyPrice(for product: Product) -> String {
        if product.id.contains("yearly") {
            let yearlyPrice = product.price
            let monthlyEquivalent = yearlyPrice / 12
            return NumberFormatter.currency.string(from: monthlyEquivalent as NSNumber) ?? "$0.00"
        }
        return product.displayPrice
    }
    
    // MARK: - Feature Access
    
    func canCreateVisionBoard() -> Bool {
        switch currentSubscription {
        case .free:
            // Check if user has reached free limit
            return true // This would be checked against user's actual usage
        case .pro, .premium:
            return true
        }
    }
    
    func canExportHD() -> Bool {
        currentSubscription != .free
    }
    
    func canUseAdvancedAI() -> Bool {
        currentSubscription == .premium
    }
    
    func maxVisionBoards() -> Int {
        switch currentSubscription {
        case .free: return 1
        case .pro: return 50
        case .premium: return -1 // Unlimited
        }
    }
}

// MARK: - Extensions

extension NumberFormatter {
    static let currency: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        return formatter
    }()
}

