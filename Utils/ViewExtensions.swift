//
//  ViewExtensions.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import SwiftUI

// MARK: - Dynamic Type

/// Applies a system font at a fixed point size that still scales with Dynamic Type.
///
/// `Font.system(size:)` is pixel-locked: at the Accessibility text sizes the app's
/// headlines grow (they use semantic styles) while badges, dates and counts stay
/// put, which breaks hierarchy and leaves meta text unreadable — WCAG 1.4.4.
/// Anchoring the size to a text style via `@ScaledMetric` keeps the design identical
/// at the default setting while letting it scale from there.
private struct ScaledSystemFont: ViewModifier {
    @ScaledMetric private var size: CGFloat
    private let weight: Font.Weight
    private let design: Font.Design

    init(size: CGFloat, relativeTo style: Font.TextStyle, weight: Font.Weight, design: Font.Design) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: style)
        self.weight = weight
        self.design = design
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight, design: design))
    }
}

extension View {
    /// Drop-in replacement for `.font(.system(size:weight:design:))` that scales.
    /// Pick `relativeTo` to match the role: `.caption2` for ~10-11pt meta text,
    /// `.caption` for ~12-13pt, `.footnote` for ~14-15pt.
    func scaledFont(
        size: CGFloat,
        relativeTo style: Font.TextStyle = .body,
        weight: Font.Weight = .regular,
        design: Font.Design = .default
    ) -> some View {
        modifier(ScaledSystemFont(size: size, relativeTo: style, weight: weight, design: design))
    }
}

// MARK: - View Extensions

extension View {
    // MARK: - Cosmic Styling


    
    // MARK: - Animations
    

    
    func floating() -> some View {
        modifier(FloatingModifier())
    }

}

// Both modifiers below use repeatForever. Their counterparts in ColorScheme.swift
// (AstralShimmerModifier / AstralPulsingModifier) already gate on Reduce Motion;
// these did not, so reaching for .shimmer()/.floating() instead of .astralShimmer()/
// .pulsing() would silently ship an unstoppable animation. Now guarded to match.
private struct ShimmerModifier: ViewModifier {
    @State private var offset: CGFloat = -200
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(
                        colors: [.clear, Color.astralText.opacity(0.3), .clear],
                        startPoint: .leading, endPoint: .trailing
                    ))
                    .rotationEffect(.degrees(-45))
                    .offset(x: offset)
                    .animation(
                        reduceMotion ? nil : .linear(duration: 1.5).repeatForever(autoreverses: false),
                        value: offset
                    )
                    .onAppear { if !reduceMotion { offset = 200 } }
            )
            .clipped()
    }
}

private struct FloatingModifier: ViewModifier {
    @State private var isUp = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .offset(y: isUp ? -6 : 0)
            .animation(
                reduceMotion ? nil : .easeInOut(duration: 2.0).repeatForever(autoreverses: true),
                value: isUp
            )
            .onAppear { if !reduceMotion { isUp = true } }
    }
}

extension View {
    
    func shimmer() -> some View {
        modifier(ShimmerModifier())
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
    
    func hapticFeedback() -> some View { self }
    
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

// MARK: - Array safe subscript

extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
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
    
    /// Scales image down so its longest edge ≤ maxDimension. Returns self if already smaller.
    func resized(maxDimension: CGFloat) -> UIImage {
        let longest = max(size.width, size.height)
        guard longest > maxDimension else { return self }
        let scale = maxDimension / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in draw(in: CGRect(origin: .zero, size: newSize)) }
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

