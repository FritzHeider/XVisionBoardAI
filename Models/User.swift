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
    var profileImageData: Data?
    var subscriptionType: SubscriptionType
    var createdAt: Date
    var lastLoginAt: Date
    var visionBoardCount: Int
    var manifestationGoals: [String]
    var preferences: UserPreferences
    
    init(
        email: String,
        username: String,
        profileImageData: Data? = nil,
        subscriptionType: SubscriptionType = .free
    ) {
        self.id = UUID()
        self.email = email
        self.username = username
        self.profileImageData = profileImageData
        self.subscriptionType = subscriptionType
        self.createdAt = Date()
        self.lastLoginAt = Date()
        self.visionBoardCount = 0
        self.manifestationGoals = []
        self.preferences = UserPreferences()
    }
    
    var profileImage: UIImage? {
        guard let data = profileImageData else { return nil }
        return UIImage(data: data)
    }
    
    var canCreateVisionBoard: Bool {
        switch subscriptionType {
        case .free:
            return visionBoardCount < 1
        case .pro, .premium:
            return true
        }
    }
    
    var maxVisionBoards: Int {
        switch subscriptionType {
        case .free: return 1
        case .pro: return 50
        case .premium: return -1 // Unlimited
        }
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

