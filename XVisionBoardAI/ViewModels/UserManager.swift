//
//  UserManager.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class UserManager: ObservableObject {
    @Published var currentUser: User?
    @Published var isLoggedIn = false
    @Published var hasCompletedOnboarding = false
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let userDefaults = UserDefaults.standard
    private let onboardingKey = "hasCompletedOnboarding"
    private let userKey = "currentUser"
    
    init() {
        loadUserData()
        hasCompletedOnboarding = userDefaults.bool(forKey: onboardingKey)
    }
    
    // MARK: - User Authentication
    
    func signUp(email: String, username: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Create new user
        let newUser = User(email: email, username: username)
        currentUser = newUser
        isLoggedIn = true
        
        saveUserData()
        isLoading = false
        return true
    }
    
    func signIn(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Mock successful login
        let user = User(email: email, username: email.components(separatedBy: "@").first ?? "User")
        currentUser = user
        isLoggedIn = true
        
        saveUserData()
        isLoading = false
        return true
    }
    
    func signOut() {
        currentUser = nil
        isLoggedIn = false
        clearUserData()
    }
    
    func deleteAccount() async -> Bool {
        isLoading = true
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        signOut()
        isLoading = false
        return true
    }
    
    // MARK: - User Profile Management
    
    func updateProfile(username: String? = nil, profileImageData: Data? = nil) {
        guard var user = currentUser else { return }
        
        if let username = username {
            user.username = username
        }
        
        if let imageData = profileImageData {
            user.profileImageData = imageData
        }
        
        currentUser = user
        saveUserData()
    }
    
    func updateSubscription(_ subscriptionType: SubscriptionType) {
        guard var user = currentUser else { return }
        user.subscriptionType = subscriptionType
        currentUser = user
        saveUserData()
    }
    
    func incrementVisionBoardCount() {
        guard var user = currentUser else { return }
        user.visionBoardCount += 1
        currentUser = user
        saveUserData()
    }
    
    func addManifestationGoal(_ goal: String) {
        guard var user = currentUser else { return }
        if !user.manifestationGoals.contains(goal) {
            user.manifestationGoals.append(goal)
            currentUser = user
            saveUserData()
        }
    }
    
    func removeManifestationGoal(_ goal: String) {
        guard var user = currentUser else { return }
        user.manifestationGoals.removeAll { $0 == goal }
        currentUser = user
        saveUserData()
    }
    
    // MARK: - Onboarding
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        userDefaults.set(true, forKey: onboardingKey)
    }
    
    func resetOnboarding() {
        hasCompletedOnboarding = false
        userDefaults.set(false, forKey: onboardingKey)
    }
    
    // MARK: - Data Persistence
    
    private func saveUserData() {
        guard let user = currentUser else { return }
        
        do {
            let userData = try JSONEncoder().encode(user)
            userDefaults.set(userData, forKey: userKey)
        } catch {
            print("Failed to save user data: \(error)")
        }
    }
    
    private func loadUserData() {
        guard let userData = userDefaults.data(forKey: userKey) else { return }
        
        do {
            let user = try JSONDecoder().decode(User.self, from: userData)
            currentUser = user
            isLoggedIn = true
        } catch {
            print("Failed to load user data: \(error)")
        }
    }
    
    private func clearUserData() {
        userDefaults.removeObject(forKey: userKey)
    }
    
    // MARK: - User Capabilities
    
    var canCreateVisionBoard: Bool {
        guard let user = currentUser else { return false }
        return user.canCreateVisionBoard
    }
    
    var remainingVisionBoards: Int {
        guard let user = currentUser else { return 0 }
        let max = user.maxVisionBoards
        return max == -1 ? Int.max : max(0, max - user.visionBoardCount)
    }
    
    var subscriptionDisplayName: String {
        currentUser?.subscriptionType.displayName ?? "Free"
    }
    
    var isProUser: Bool {
        currentUser?.subscriptionType == .pro || currentUser?.subscriptionType == .premium
    }
    
    var isPremiumUser: Bool {
        currentUser?.subscriptionType == .premium
    }
}

