//
//  CosmicTheme.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import SwiftUI

// MARK: - Cosmic Color Palette

extension Color {
    static let cosmicPurple = Color(red: 0.4, green: 0.3, blue: 0.8)
    static let cosmicBlue   = Color(red: 0.2, green: 0.4, blue: 0.9)
    static let cosmicPink   = Color(red: 0.8, green: 0.3, blue: 0.6)
    static let cosmicGold   = Color(red: 1.0, green: 0.8, blue: 0.2)
    static let cosmicBlack  = Color(red: 0.05, green: 0.05, blue: 0.1)
    static let cosmicGray   = Color(red: 0.15, green: 0.15, blue: 0.2)
    static let cosmicWhite  = Color(red: 0.95, green: 0.95, blue: 1.0)
    
    static let cosmicGradient = LinearGradient(
        colors: [.cosmicPurple, .cosmicBlue, .cosmicPink],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    static let goldGradient = LinearGradient(
        colors: [.cosmicGold, Color.orange],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    static let manifestationPrimary     = cosmicPurple
    static let manifestationSecondary   = cosmicPink
    static let manifestationAccent      = cosmicGold
    static let manifestationBackground  = cosmicBlack
    static let manifestationSurface     = cosmicGray

    // MARK: - Adaptive (light/dark)
    static let adaptiveBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.05, green: 0.05, blue: 0.1, alpha: 1)
            : .white
    })
    static let adaptiveSurface = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1)
            : UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1)
    })
    static let adaptiveText = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(red: 0.95, green: 0.95, blue: 1.0, alpha: 1)
            : .black
    })
    static let adaptiveCTA = Color(UIColor.systemBlue)
}

// MARK: - Custom View Modifiers

struct CosmicCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(red: 0.11, green: 0.11, blue: 0.17))
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.cosmicPurple.opacity(0.10),
                                    Color.cosmicBlue.opacity(0.06),
                                    Color.cosmicPink.opacity(0.04)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.cosmicGradient, lineWidth: 1)
                }
            )
            .shadow(color: Color.cosmicPurple.opacity(0.25), radius: 8, x: 0, y: 4)
            .shadow(color: Color.black.opacity(0.4), radius: 20, x: 0, y: 10)
    }
}

struct CosmicGlowCardModifier: ViewModifier {
    var glowColor: Color = .cosmicPurple

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(red: 0.10, green: 0.10, blue: 0.16))
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                colors: [glowColor.opacity(0.18), Color.cosmicBlue.opacity(0.10)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(
                            LinearGradient(
                                colors: [glowColor.opacity(0.8), Color.cosmicBlue.opacity(0.5), Color.cosmicPink.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                }
            )
            .shadow(color: glowColor.opacity(0.45), radius: 16, x: 0, y: 6)
            .shadow(color: Color.black.opacity(0.5), radius: 24, x: 0, y: 12)
    }
}

struct CosmicButtonModifier: ViewModifier {
    let isEnabled: Bool
    @State private var isPressed = false

    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }

    func body(content: Content) -> some View {
        content
            .foregroundColor(.white)
            .font(.headline)
            .padding(.horizontal, 28)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(
                        isEnabled
                        ? LinearGradient(
                            colors: [.cosmicPurple, .cosmicBlue, .cosmicPink.opacity(0.7)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        : LinearGradient(
                            colors: [Color.gray.opacity(0.5), Color.gray.opacity(0.5)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .shadow(color: isEnabled ? Color.cosmicPurple.opacity(0.5) : .clear, radius: 12, x: 0, y: 6)
            .scaleEffect(isEnabled ? (isPressed ? 0.97 : 1.0) : 0.95)
            .opacity(isEnabled ? 1.0 : 0.5)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: isPressed)
            .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

struct PulsingModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.04 : 1.0)
            .opacity(isPulsing ? 0.85 : 1.0)
            .animation(
                .easeInOut(duration: 1.8)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear { isPulsing = true }
    }
}

// MARK: - View Extensions

extension View {
    func cosmicCard() -> some View {
        modifier(CosmicCardModifier())
    }

    func cosmicGlowCard(color: Color = .cosmicPurple) -> some View {
        modifier(CosmicGlowCardModifier(glowColor: color))
    }

    func cosmicButton(isEnabled: Bool = true) -> some View {
        modifier(CosmicButtonModifier(isEnabled: isEnabled))
    }

    func pulsing() -> some View {
        modifier(PulsingModifier())
    }

    func manifestationTitle() -> some View {
        self
            .font(.system(.largeTitle, design: .rounded, weight: .bold))
            .foregroundStyle(Color.cosmicGradient)
    }

    func manifestationSubtitle() -> some View {
        self
            .font(.system(.title2, design: .rounded, weight: .semibold))
            .foregroundColor(.cosmicWhite)
    }

    func manifestationBody() -> some View {
        self
            .font(.system(.body, design: .rounded))
            .foregroundColor(.cosmicWhite.opacity(0.82))
    }
}
