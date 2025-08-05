//
//  SubscriptionView.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var storeManager: StoreManager
    @EnvironmentObject var userManager: UserManager
    
    @State private var selectedPlan: SubscriptionPlan?
    @State private var showingPurchaseSuccess = false
    @State private var showingRestoreAlert = false
    
    enum SubscriptionPlan: CaseIterable {
        case proMonthly, proYearly, premiumMonthly, premiumYearly
        
        var productId: String {
            switch self {
            case .proMonthly: return "com.xvisionboardai.pro.monthly"
            case .proYearly: return "com.xvisionboardai.pro.yearly"
            case .premiumMonthly: return "com.xvisionboardai.premium.monthly"
            case .premiumYearly: return "com.xvisionboardai.premium.yearly"
            }
        }
        
        var subscriptionType: SubscriptionType {
            switch self {
            case .proMonthly, .proYearly: return .pro
            case .premiumMonthly, .premiumYearly: return .premium
            }
        }
        
        var isYearly: Bool {
            switch self {
            case .proYearly, .premiumYearly: return true
            case .proMonthly, .premiumMonthly: return false
            }
        }
        
        var savingsPercentage: Int? {
            switch self {
            case .proYearly: return 20
            case .premiumYearly: return 25
            default: return nil
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.cosmicBlack.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        headerSection
                        
                        // Current plan
                        if storeManager.hasActiveSubscription {
                            currentPlanSection
                        }
                        
                        // Subscription plans
                        subscriptionPlansSection
                        
                        // Features comparison
                        featuresComparisonSection
                        
                        // Purchase button
                        if !storeManager.hasActiveSubscription {
                            purchaseSection
                        }
                        
                        // Restore purchases
                        restoreSection
                        
                        // Terms and privacy
                        legalSection
                        
                        Spacer(minLength: 100)
                    }
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.cosmicWhite)
                }
                
                ToolbarItem(placement: .principal) {
                    Text("Upgrade to Pro")
                        .font(.headline)
                        .foregroundColor(.cosmicWhite)
                }
            }
        }
        .alert("Purchase Successful!", isPresented: $showingPurchaseSuccess) {
            Button("Continue") {
                dismiss()
            }
        } message: {
            Text("Welcome to XVisionBoard AI Pro! You now have access to unlimited personalized vision boards.")
        }
        .alert("Restore Purchases", isPresented: $showingRestoreAlert) {
            Button("OK") { }
        } message: {
            Text(storeManager.errorMessage ?? "Purchases restored successfully!")
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        VStack(spacing: 20) {
            Image(systemName: "crown.fill")
                .font(.system(size: 60))
                .foregroundColor(.cosmicGold)
                .pulsing()
            
            VStack(spacing: 12) {
                Text("Unlock Your Full Potential")
                    .manifestationTitle()
                    .multilineTextAlignment(.center)
                
                Text("Create unlimited personalized vision boards and accelerate your manifestation journey")
                    .manifestationBody()
                    .multilineTextAlignment(.center)
            }
            
            // Value proposition badges
            HStack(spacing: 16) {
                ValueBadge(icon: "infinity", text: "Unlimited")
                ValueBadge(icon: "4k.tv", text: "HD Quality")
                ValueBadge(icon: "brain.head.profile", text: "Advanced AI")
            }
        }
    }
    
    // MARK: - Current Plan Section
    
    private var currentPlanSection: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                
                Text("Current Plan: \(userManager.subscriptionDisplayName)")
                    .font(.headline)
                    .foregroundColor(.cosmicWhite)
                
                Spacer()
            }
            
            Text("You're already enjoying the full XVisionBoard AI experience!")
                .font(.subheadline)
                .foregroundColor(.cosmicWhite.opacity(0.8))
        }
        .padding()
        .cosmicCard()
    }
    
    // MARK: - Subscription Plans Section
    
    private var subscriptionPlansSection: some View {
        VStack(spacing: 16) {
            Text("Choose Your Plan")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.cosmicWhite)
            
            VStack(spacing: 12) {
                // Pro plans
                SubscriptionTier(
                    type: .pro,
                    monthlyPlan: .proMonthly,
                    yearlyPlan: .proYearly,
                    selectedPlan: $selectedPlan,
                    storeManager: storeManager
                )
                
                // Premium plans
                SubscriptionTier(
                    type: .premium,
                    monthlyPlan: .premiumMonthly,
                    yearlyPlan: .premiumYearly,
                    selectedPlan: $selectedPlan,
                    storeManager: storeManager
                )
            }
        }
    }
    
    // MARK: - Features Comparison Section
    
    private var featuresComparisonSection: some View {
        VStack(spacing: 16) {
            Text("What's Included")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.cosmicWhite)
            
            VStack(spacing: 12) {
                FeatureRow(
                    feature: "Personalized Vision Boards",
                    free: "1",
                    pro: "50",
                    premium: "Unlimited"
                )
                
                FeatureRow(
                    feature: "HD Exports",
                    free: false,
                    pro: true,
                    premium: true
                )
                
                FeatureRow(
                    feature: "Watermark Removal",
                    free: false,
                    pro: true,
                    premium: true
                )
                
                FeatureRow(
                    feature: "Advanced AI Features",
                    free: false,
                    pro: true,
                    premium: true
                )
                
                FeatureRow(
                    feature: "Audio Affirmations",
                    free: false,
                    pro: true,
                    premium: true
                )
                
                FeatureRow(
                    feature: "Video Manifestations",
                    free: false,
                    pro: false,
                    premium: true
                )
                
                FeatureRow(
                    feature: "Personal AI Coach",
                    free: false,
                    pro: false,
                    premium: true
                )
                
                FeatureRow(
                    feature: "Priority Support",
                    free: false,
                    pro: true,
                    premium: true
                )
            }
            .padding()
            .cosmicCard()
        }
    }
    
    // MARK: - Purchase Section
    
    private var purchaseSection: some View {
        VStack(spacing: 16) {
            if let plan = selectedPlan,
               let product = storeManager.product(for: plan.productId) {
                
                Button("Start \(plan.subscriptionType.displayName) - \(storeManager.formattedPrice(for: product))") {
                    purchaseSubscription(product)
                }
                .cosmicButton()
                .font(.headline)
                .disabled(storeManager.isLoading)
                
                if plan.isYearly, let savings = plan.savingsPercentage {
                    Text("Save \(savings)% with yearly billing")
                        .font(.subheadline)
                        .foregroundColor(.cosmicGold)
                }
                
                if storeManager.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .cosmicPurple))
                }
            } else {
                Text("Select a plan above to continue")
                    .font(.subheadline)
                    .foregroundColor(.cosmicWhite.opacity(0.7))
            }
        }
    }
    
    // MARK: - Restore Section
    
    private var restoreSection: some View {
        VStack(spacing: 12) {
            Button("Restore Purchases") {
                restorePurchases()
            }
            .foregroundColor(.cosmicPurple)
            .font(.subheadline)
            
            Text("Already purchased? Restore your subscription")
                .font(.caption)
                .foregroundColor(.cosmicWhite.opacity(0.6))
        }
    }
    
    // MARK: - Legal Section
    
    private var legalSection: some View {
        VStack(spacing: 8) {
            Text("By subscribing, you agree to our Terms of Service and Privacy Policy. Subscriptions auto-renew unless cancelled 24 hours before the end of the current period.")
                .font(.caption)
                .foregroundColor(.cosmicWhite.opacity(0.6))
                .multilineTextAlignment(.center)
            
            HStack(spacing: 20) {
                Button("Terms of Service") {
                    // Open terms
                }
                .foregroundColor(.cosmicPurple)
                .font(.caption)
                
                Button("Privacy Policy") {
                    // Open privacy policy
                }
                .foregroundColor(.cosmicPurple)
                .font(.caption)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func purchaseSubscription(_ product: Product) {
        Task {
            let success = await storeManager.purchase(product)
            if success {
                userManager.updateSubscription(selectedPlan?.subscriptionType ?? .free)
                showingPurchaseSuccess = true
            }
        }
    }
    
    private func restorePurchases() {
        Task {
            await storeManager.restorePurchases()
            showingRestoreAlert = true
        }
    }
}

// MARK: - Supporting Views

struct ValueBadge: View {
    let icon: String
    let text: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.cosmicGold)
            
            Text(text)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.cosmicWhite)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cosmicGray)
        )
    }
}

struct SubscriptionTier: View {
    let type: SubscriptionType
    let monthlyPlan: SubscriptionView.SubscriptionPlan
    let yearlyPlan: SubscriptionView.SubscriptionPlan
    @Binding var selectedPlan: SubscriptionView.SubscriptionPlan?
    let storeManager: StoreManager
    
    var body: some View {
        VStack(spacing: 16) {
            // Tier header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(type.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.cosmicWhite)
                    
                    Text("Perfect for \(type == .pro ? "regular users" : "power users")")
                        .font(.caption)
                        .foregroundColor(.cosmicWhite.opacity(0.7))
                }
                
                Spacer()
                
                if type == .premium {
                    Text("MOST POPULAR")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.cosmicGold)
                        .clipShape(Capsule())
                }
            }
            
            // Plan options
            VStack(spacing: 8) {
                PlanOption(
                    plan: monthlyPlan,
                    isSelected: selectedPlan == monthlyPlan,
                    storeManager: storeManager
                ) {
                    selectedPlan = monthlyPlan
                }
                
                PlanOption(
                    plan: yearlyPlan,
                    isSelected: selectedPlan == yearlyPlan,
                    storeManager: storeManager
                ) {
                    selectedPlan = yearlyPlan
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(type == .premium ? Color.cosmicPurple.opacity(0.2) : Color.cosmicGray)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(type == .premium ? Color.cosmicGold : Color.clear, lineWidth: 2)
                )
        )
    }
}

struct PlanOption: View {
    let plan: SubscriptionView.SubscriptionPlan
    let isSelected: Bool
    let storeManager: StoreManager
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(plan.isYearly ? "Yearly" : "Monthly")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.cosmicWhite)
                        
                        if let savings = plan.savingsPercentage {
                            Text("Save \(savings)%")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(.black)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.cosmicGold)
                                .clipShape(Capsule())
                        }
                    }
                    
                    if let product = storeManager.product(for: plan.productId) {
                        HStack {
                            Text(storeManager.formattedPrice(for: product))
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.cosmicWhite)
                            
                            if plan.isYearly {
                                Text("(\(storeManager.monthlyPrice(for: product))/month)")
                                    .font(.caption)
                                    .foregroundColor(.cosmicWhite.opacity(0.7))
                            }
                        }
                    }
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.cosmicGold)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.cosmicPurple.opacity(0.3) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.cosmicGold : Color.gray.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }
}

struct FeatureRow: View {
    let feature: String
    let free: Any
    let pro: Any
    let premium: Any
    
    var body: some View {
        HStack {
            Text(feature)
                .font(.subheadline)
                .foregroundColor(.cosmicWhite)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            FeatureCell(value: free, tier: .free)
            FeatureCell(value: pro, tier: .pro)
            FeatureCell(value: premium, tier: .premium)
        }
    }
}

struct FeatureCell: View {
    let value: Any
    let tier: SubscriptionType
    
    var body: some View {
        Group {
            if let boolValue = value as? Bool {
                Image(systemName: boolValue ? "checkmark" : "xmark")
                    .foregroundColor(boolValue ? .green : .red)
            } else if let stringValue = value as? String {
                Text(stringValue)
                    .font(.caption)
                    .foregroundColor(.cosmicWhite)
            }
        }
        .frame(width: 60)
    }
}

#Preview {
    SubscriptionView()
        .environmentObject(StoreManager())
        .environmentObject(UserManager())
}

