//
//  User.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import Foundation
import SwiftUI

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
    }

    var profileImage: UIImage? {
        guard let filename = profileImageFilename else { return nil }
        return ImageStore.load(filename)
    }
}

enum SubscriptionType: String, Codable, CaseIterable {
    case free = "free"
    case pro = "pro"
    case premium = "premium"
    
    var displayName: String {
        switch self {
        case .free: return "Free"
        case .pro: return "Pro"
        case .premium: return "Premium"
        }
    }
    
    var monthlyPrice: String {
        switch self {
        case .free: return "$0"
        case .pro: return "$9.99"
        case .premium: return "$19.99"
        }
    }
    
    var features: [String] {
        switch self {
        case .free:
            return [
                "1 personalized vision board",
                "Basic AI affirmations",
                "Standard resolution",
                "Watermarked exports"
            ]
        case .pro:
            return [
                "50 personalized vision boards",
                "Advanced AI features",
                "HD exports without watermarks",
                "Priority processing",
                "Audio affirmations"
            ]
        case .premium:
            return [
                "Unlimited vision boards",
                "Premium AI models",
                "4K exports",
                "Advanced personalization",
                "Video manifestations",
                "Personal coach AI"
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

