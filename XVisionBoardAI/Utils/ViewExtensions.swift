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
    
    func cosmicButton(isEnabled: Bool = true) -> some View {
        self
            .font(.headline)
            .foregroundColor(isEnabled ? .black : .cosmicWhite.opacity(0.5))
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        isEnabled ?
                        LinearGradient(
                            colors: [.cosmicPurple, .cosmicBlue],
                            startPoint: .leading,
                            endPoint: .trailing
                        ) :
                        LinearGradient(
                            colors: [.gray, .gray],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .disabled(!isEnabled)
    }
    
    func cosmicCard() -> some View {
        self
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cosmicGray)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [.cosmicPurple.opacity(0.3), .cosmicBlue.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
            )
    }
    
    func manifestationTitle() -> some View {
        self
            .font(.title)
            .fontWeight(.bold)
            .foregroundStyle(
                LinearGradient(
                    colors: [.cosmicPurple, .cosmicBlue, .cosmicPink],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
    }
    
    func manifestationBody() -> some View {
        self
            .font(.body)
            .foregroundColor(.cosmicWhite.opacity(0.9))
    }
    
    // MARK: - Animations
    
    func pulsing() -> some View {
        self
            .scaleEffect(1.0)
            .animation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                value: UUID()
            )
            .onAppear {
                withAnimation {
                    // Trigger animation
                }
            }
    }
    
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
    // MARK: - Cosmic Color Palette
    
    static let cosmicBlack = Color(red: 0.05, green: 0.05, blue: 0.1)
    static let cosmicGray = Color(red: 0.15, green: 0.15, blue: 0.2)
    static let cosmicWhite = Color(red: 0.95, green: 0.95, blue: 1.0)
    
    static let cosmicPurple = Color(red: 0.6, green: 0.3, blue: 0.9)
    static let cosmicBlue = Color(red: 0.2, green: 0.5, blue: 1.0)
    static let cosmicPink = Color(red: 1.0, green: 0.3, blue: 0.7)
    static let cosmicGold = Color(red: 1.0, green: 0.8, blue: 0.2)
    
    // MARK: - Gradient Colors
    
    static let cosmicGradient = LinearGradient(
        colors: [
            Color(red: 0.1, green: 0.05, blue: 0.2),
            Color(red: 0.2, green: 0.1, blue: 0.3),
            Color(red: 0.15, green: 0.1, blue: 0.25)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let manifestationGradient = LinearGradient(
        colors: [cosmicPurple, cosmicBlue, cosmicPink],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    // MARK: - Utility Methods
    
    func opacity(_ opacity: Double) -> Color {
        self.opacity(opacity)
    }
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

