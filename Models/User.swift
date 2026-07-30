//
//  User.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import Foundation
import SwiftUI

// MARK: - Manifestation Domain Types

enum LifeArea: String, Codable, CaseIterable, Identifiable {
    case career, relationships, health, wealth, creativity, travel, family

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .career:        return "Career"
        case .relationships: return "Love & Relationships"
        case .health:        return "Health & Vitality"
        case .wealth:        return "Wealth & Abundance"
        case .creativity:    return "Creativity & Expression"
        case .travel:        return "Travel & Adventure"
        case .family:        return "Family & Home"
        }
    }

    var icon: String {
        switch self {
        case .career:        return "briefcase.fill"
        case .relationships: return "heart.fill"
        case .health:        return "heart.circle.fill"
        case .wealth:        return "dollarsign.circle.fill"
        case .creativity:    return "paintpalette.fill"
        case .travel:        return "airplane"
        case .family:        return "house.fill"
        }
    }

    var color: Color {
        switch self {
        case .career:        return .astralIndigo
        case .relationships: return .astralRose
        case .health:        return .astralMint
        case .wealth:        return .astralGold
        case .creativity:    return .astralViolet
        case .travel:        return .astralIndigo
        case .family:        return .astralGold
        }
    }
}

enum ManifestationTimeline: String, Codable, CaseIterable, Identifiable {
    case thisMonth = "this_month"
    case thisYear  = "this_year"
    case fiveYears = "five_years"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .thisMonth: return "This Month"
        case .thisYear:  return "This Year"
        case .fiveYears: return "5 Years"
        }
    }

    var icon: String {
        switch self {
        case .thisMonth: return "calendar"
        case .thisYear:  return "calendar.badge.checkmark"
        case .fiveYears: return "star.fill"
        }
    }
}

struct OnboardingAnswers: Codable {
    var lifeAreas: [LifeArea]
    var primaryDream: String
    var timeline: ManifestationTimeline
    var completedAt: Date
}

struct UserInsight: Codable, Identifiable {
    var id: UUID
    var question: String
    var answer: String
    var answeredAt: Date

    init(question: String, answer: String) {
        self.id = UUID()
        self.question = question
        self.answer = answer
        self.answeredAt = Date()
    }
}

// MARK: - User

struct User: Codable, Identifiable {
    let id: UUID
    var email: String
    var username: String
    var profileImageFilename: String?
    var createdAt: Date
    var lastLoginAt: Date
    var visionBoardCount: Int
    var manifestationGoals: [String]
    var preferences: UserPreferences
    var onboardingAnswers: OnboardingAnswers?
    var insights: [UserInsight]

    init(email: String, username: String, profileImageFilename: String? = nil) {
        self.id = UUID()
        self.email = email
        self.username = username
        self.profileImageFilename = profileImageFilename
        self.createdAt = Date()
        self.lastLoginAt = Date()
        self.visionBoardCount = 0
        self.manifestationGoals = []
        self.preferences = UserPreferences()
        self.onboardingAnswers = nil
        self.insights = []
    }

    var profileImage: UIImage? {
        guard let filename = profileImageFilename else { return nil }
        return ImageStore.load(filename)
    }
}

enum SubscriptionType: String, Codable, CaseIterable {
    case free = "free"
    case pro = "pro"

    /// Decodes unknown/legacy raw values (e.g. a retired "premium") as .free
    /// rather than throwing and losing the surrounding payload.
    init(from decoder: Decoder) throws {
        let raw = try decoder.singleValueContainer().decode(String.self)
        self = SubscriptionType(rawValue: raw) ?? .free
    }

    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        }
    }

    /// Only list what the app actually enforces. Every entry here must map to a
    /// real gate (see `StoreManager` "Feature Gating"), because App Review
    /// buys the subscription in sandbox and checks that the promised
    /// differences appear. Claims that were listed but never implemented
    /// ("Advanced AI personalization", "Priority processing", "Offline image
    /// caching", "Priority support") were removed rather than faked.
    var features: [String] {
        switch self {
        case .free:
            return [
                "1 personalized vision board",
                "AI-written affirmations",
                "Standard resolution exports",
                "Watermarked exports"
            ]
        case .pro:
            return [
                "Unlimited vision boards",
                "HD exports without watermarks",
                "Audio affirmations (Read Aloud)"
            ]
        }
    }
}

struct UserPreferences: Codable {
    var notificationsEnabled: Bool = true
    var dailyAffirmationsEnabled: Bool = true
    var preferredVisionBoardStyle: VisionBoardStyle = .cinematic
    var preferredLayout: VisionBoardLayout = .grid3x3
    var manifestationReminders: Bool = true
    var shareAnalytics: Bool = false
    
    init() {}
}

