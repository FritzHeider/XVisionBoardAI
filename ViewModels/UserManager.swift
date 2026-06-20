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
    var currentStreak: Int = 0
    var lastStreakDate: Date?
    var lastInsightDate: Date?

    private(set) var authToken: String?

    private let userDefaults = UserDefaults.standard
    private let onboardingKey = "hasCompletedOnboarding"
    private let userKey = "currentUser"
    private let tokenStore: TokenStore

    // Questions rotate weekly to build a richer user profile over time
    static let insightQuestions: [String] = [
        "Describe your perfect day, in as much detail as you can.",
        "What would you do if you knew you couldn't fail?",
        "What does financial freedom look like to you?",
        "Who are the three people you most want to become like, and why?",
        "What emotion do you most want to feel more of in your life?",
        "What's one thing you'd regret not having done in 10 years?",
        "Describe where you want to live and what your home feels like.",
        "What does your ideal relationship look and feel like?",
        "What would you do with your time if money weren't a concern?",
        "What's the single boldest dream you've never told anyone?",
        "How do you want to feel when you wake up each morning?",
        "What would achieving your biggest goal change about your daily life?",
        "Who do you want to become in the next 12 months?",
        "What's a small, concrete step you took toward your dream this week?",
        "What belief about yourself might be slowing you down?",
    ]

    var hasPendingInsight: Bool {
        guard isLoggedIn else { return false }
        guard let last = lastInsightDate else { return true }
        let days = Calendar.current.dateComponents([.day], from: last, to: Date()).day ?? 0
        return days >= 7
    }

    var nextInsightQuestion: String {
        let answered = currentUser?.insights.count ?? 0
        return Self.insightQuestions[answered % Self.insightQuestions.count]
    }

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
        currentStreak = userDefaults.integer(forKey: "currentStreak")
        lastStreakDate = userDefaults.object(forKey: "lastStreakDate") as? Date
        lastInsightDate = userDefaults.object(forKey: "lastInsightDate") as? Date
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
    
    func saveOnboardingAnswers(_ answers: OnboardingAnswers) {
        guard var user = currentUser else { return }
        user.onboardingAnswers = answers
        // Sync primary dream to manifestationGoals for backward compat
        if !answers.primaryDream.isEmpty, !user.manifestationGoals.contains(answers.primaryDream) {
            user.manifestationGoals.insert(answers.primaryDream, at: 0)
        }
        currentUser = user
        saveUserData()
    }

    func addInsight(question: String, answer: String) {
        guard var user = currentUser else { return }
        let insight = UserInsight(question: question, answer: answer)
        user.insights.append(insight)
        currentUser = user
        lastInsightDate = Date()
        userDefaults.set(lastInsightDate, forKey: "lastInsightDate")
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

    // MARK: - Streak

    func recordDailyVisit() {
        let today = Calendar.current.startOfDay(for: Date())
        if let last = lastStreakDate {
            let lastDay = Calendar.current.startOfDay(for: last)
            let days = Calendar.current.dateComponents([.day], from: lastDay, to: today).day ?? 0
            if days == 1 {
                currentStreak += 1
            } else if days > 1 {
                currentStreak = 1
            }
            if days >= 1 {
                lastStreakDate = Date()
                userDefaults.set(currentStreak, forKey: "currentStreak")
                userDefaults.set(lastStreakDate, forKey: "lastStreakDate")
            }
        } else {
            currentStreak = 1
            lastStreakDate = Date()
            userDefaults.set(currentStreak, forKey: "currentStreak")
            userDefaults.set(lastStreakDate, forKey: "lastStreakDate")
        }
    }
}

