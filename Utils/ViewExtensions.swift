//
//  ViewExtensions.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import SwiftUI

// MARK: - View Extensions

extension View {
    // MARK: - Cosmic Styling
    

    
    // MARK: - Animations
    

    
    func floating() -> some View {
        self
            .offset(y: 0)
            .animation(
                Animation.easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true),
                value: UUID()
            )
            .onAppear {
                withAnimation {
                    // Trigger floating animation
                }
            }
    }
    
    func shimmer() -> some View {
        self
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                .cosmicWhite.opacity(0.3),
                                .clear
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .rotationEffect(.degrees(-45))
                    .offset(x: -200)
                    .animation(
                        Animation.linear(duration: 1.5)
                            .repeatForever(autoreverses: false),
                        value: UUID()
                    )
            )
            .clipped()
    }
    
    // MARK: - Conditional Modifiers
    
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
    
    // MARK: - Haptic Feedback
    
    func hapticFeedback(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) -> some View {
        self.onTapGesture {
            let impactFeedback = UIImpactFeedbackGenerator(style: style)
            impactFeedback.impactOccurred()
        }
    }
    
    // MARK: - Safe Area
    
    func safeAreaPadding() -> some View {
        self.padding(.horizontal)
            .padding(.top, 1)
            .padding(.bottom, 1)
    }
}

// MARK: - Color Extensions

extension Color {

    
    // MARK: - Gradient Colors
    
 
    
    // MARK: - Utility Methods
   
}

// MARK: - Font Extensions

extension Font {
    // MARK: - Custom Fonts
    
    static let manifestationTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    static let manifestationSubtitle = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let manifestationBody = Font.system(size: 16, weight: .medium, design: .rounded)
    static let manifestationCaption = Font.system(size: 12, weight: .regular, design: .rounded)
    
    // MARK: - Dynamic Type Support
    
    static func manifestationTitle(size: CGFloat) -> Font {
        Font.system(size: size, weight: .bold, design: .rounded)
    }
    
    static func manifestationBody(size: CGFloat) -> Font {
        Font.system(size: size, weight: .medium, design: .rounded)
    }
}

// MARK: - String Extensions

extension String {
    // MARK: - Validation
    
    var isValidEmail: Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: self)
    }
    
    var isValidPassword: Bool {
        return self.count >= 6
    }
    
    // MARK: - Formatting
    
    func truncated(to length: Int) -> String {
        if self.count > length {
            return String(self.prefix(length)) + "..."
        }
        return self
    }
    
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }
}

// MARK: - Date Extensions

extension Date {
    // MARK: - Formatting
    
    var manifestationDateString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: self)
    }
    
    var relativeTimeString: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: self, relativeTo: Date())
    }
    
    // MARK: - Calculations
    
    var isToday: Bool {
        Calendar.current.isDateInToday(self)
    }
    
    var isThisWeek: Bool {
        Calendar.current.isDate(self, equalTo: Date(), toGranularity: .weekOfYear)
    }
}

// MARK: - UIImage Extensions

extension UIImage {
    // MARK: - Resizing
    
    func resized(to size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    func aspectFittedToSize(_ size: CGSize) -> UIImage? {
        let aspectRatio = self.size.width / self.size.height
        let targetAspectRatio = size.width / size.height
        
        var targetSize: CGSize
        if aspectRatio > targetAspectRatio {
            targetSize = CGSize(width: size.width, height: size.width / aspectRatio)
        } else {
            targetSize = CGSize(width: size.height * aspectRatio, height: size.height)
        }
        
        return resized(to: targetSize)
    }
    
    // MARK: - Effects
    
    func withTint(_ color: UIColor) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        defer { UIGraphicsEndImageContext() }
        
        color.set()
        withRenderingMode(.alwaysTemplate).draw(in: CGRect(origin: .zero, size: size))
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

// MARK: - Array Extensions

extension Array where Element: Identifiable {
    // MARK: - Utility Methods
    
    func element(with id: Element.ID) -> Element? {
        return first { $0.id == id }
    }
    
    mutating func remove(with id: Element.ID) {
        removeAll { $0.id == id }
    }
    
    mutating func update(_ element: Element) {
        if let index = firstIndex(where: { $0.id == element.id }) {
            self[index] = element
        }
    }
}

// MARK: - UserDefaults Extensions

extension UserDefaults {
    // MARK: - Custom Keys
    
    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let userSubscriptionType = "userSubscriptionType"
        static let visionBoardCount = "visionBoardCount"
        static let lastAppVersion = "lastAppVersion"
    }
    
    var hasCompletedOnboarding: Bool {
        get { bool(forKey: Keys.hasCompletedOnboarding) }
        set { set(newValue, forKey: Keys.hasCompletedOnboarding) }
    }
    
    var userSubscriptionType: String {
        get { string(forKey: Keys.userSubscriptionType) ?? "free" }
        set { set(newValue, forKey: Keys.userSubscriptionType) }
    }
    
    var visionBoardCount: Int {
        get { integer(forKey: Keys.visionBoardCount) }
        set { set(newValue, forKey: Keys.visionBoardCount) }
    }
    
    var lastAppVersion: String? {
        get { string(forKey: Keys.lastAppVersion) }
        set { set(newValue, forKey: Keys.lastAppVersion) }
    }
}

