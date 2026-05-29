//
//  UserManager.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import Foundation
import SwiftUI

@MainActor
@Observable
class UserManager {
    var currentUser: User?
    var isLoggedIn = false {
        didSet { UserDefaults.standard.set(isLoggedIn, forKey: "isLoggedIn") }
    }
    var hasCompletedOnboarding = false
    var isLoading = false
    var errorMessage: String?

    private(set) var authToken: String?

    private let userDefaults = UserDefaults.standard
    private let onboardingKey = "hasCompletedOnboarding"
    private let userKey = "currentUser"
    private let tokenStore: TokenStore

    init(tokenStore: TokenStore? = nil) {
#if DEBUG
        if ProcessInfo.processInfo.environment["DEBUG_AUTO_LOGIN"] == "1" {
            self.tokenStore = tokenStore ?? InMemoryTokenStore()
            let user = User(email: "debug@example.com", username: "DebugUser")
            currentUser = user
            isLoggedIn = true
            hasCompletedOnboarding = true
            let token = UUID().uuidString
            authToken = token
            self.tokenStore.save(token)
            return
        }
#endif

        self.tokenStore = tokenStore ?? KeychainTokenStore()
        isLoggedIn = UserDefaults.standard.bool(forKey: "isLoggedIn")
        loadUserData()
        hasCompletedOnboarding = userDefaults.bool(forKey: onboardingKey)
    }
    
    // MARK: - User Authentication
    
    func signUp(email: String, username: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        guard email.isValidEmail else {
            errorMessage = "Please enter a valid email address"
            isLoading = false
            return false
        }
        guard password.isValidPassword else {
            errorMessage = "Password must be at least 6 characters"
            isLoading = false
            return false
        }
        guard !username.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Username cannot be empty"
            isLoading = false
            return false
        }

        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Create new user
        let newUser = User(email: email, username: username)
        currentUser = newUser
        isLoggedIn = true

        let token = UUID().uuidString
        authToken = token
        tokenStore.save(token)

        saveUserData()
        isLoading = false
        return true
    }
    
    func signIn(email: String, password: String) async -> Bool {
        isLoading = true
        errorMessage = nil

        guard email.isValidEmail else {
            errorMessage = "Please enter a valid email address"
            isLoading = false
            return false
        }
        guard password.isValidPassword else {
            errorMessage = "Password must be at least 6 characters"
            isLoading = false
            return false
        }

        // Simulate API call
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        // Mock successful login
        let user = User(email: email, username: email.components(separatedBy: "@").first ?? "User")
        currentUser = user
        isLoggedIn = true

        let token = UUID().uuidString
        authToken = token
        tokenStore.save(token)

        saveUserData()
        isLoading = false
        return true
    }

    func signOut() {
        currentUser = nil
        isLoggedIn = false
        authToken = nil
        tokenStore.clear()
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
    
    func updateProfile(username: String? = nil, profileImage: UIImage? = nil) {
        guard var user = currentUser else { return }

        if let username = username {
            user.username = username
        }

        if let image = profileImage {
            if let old = user.profileImageFilename { ImageStore.delete(old) }
            user.profileImageFilename = try? ImageStore.save(image, filename: user.id.uuidString + "_profile")
        }

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
        guard let token = tokenStore.load(),
              let userData = userDefaults.data(forKey: userKey) else { return }

        do {
            let user = try JSONDecoder().decode(User.self, from: userData)
            currentUser = user
            isLoggedIn = true
            authToken = token
        } catch {
            print("Failed to load user data: \(error)")
        }
    }
    
    private func clearUserData() {
        userDefaults.removeObject(forKey: userKey)
    }
    
    var visionBoardCount: Int { currentUser?.visionBoardCount ?? 0 }
}

