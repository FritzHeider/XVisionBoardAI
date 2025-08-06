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
}

// MARK: - Custom View Modifiers

struct CosmicCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cosmicGray)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.cosmicGradient, lineWidth: 1)
                    )
            )
            .shadow(color: Color.cosmicPurple.opacity(0.3), radius: 10, x: 0, y: 5)
    }
}

struct CosmicButtonModifier: ViewModifier {
    let isEnabled: Bool
    
    init(isEnabled: Bool = true) {
        self.isEnabled = isEnabled
    }
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(.white)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(
                        isEnabled
                        ? LinearGradient(
                            colors: [.cosmicPurple, .cosmicBlue],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        : LinearGradient(
                            colors: [.gray, .gray],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            )
            .scaleEffect(isEnabled ? 1.0 : 0.95)
            .opacity(isEnabled ? 1.0 : 0.6)
            .animation(.easeInOut(duration: 0.2), value: isEnabled)
    }
}

struct PulsingModifier: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .animation(
                .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

// MARK: - View Extensions

extension View {
    func cosmicCard() -> some View {
        modifier(CosmicCardModifier())
    }
    
    func cosmicButton(isEnabled: Bool = true) -> some View {
        modifier(CosmicButtonModifier(isEnabled: isEnabled))
    }
    
    func pulsing() -> some View {
        modifier(PulsingModifier())
    }
    
    func manifestationTitle() -> some View {
        self
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundStyle(Color.cosmicGradient)
    }
    
    func manifestationSubtitle() -> some View {
        self
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.cosmicWhite)
    }
    
    func manifestationBody() -> some View {
        self
            .font(.body)
            .foregroundColor(.cosmicWhite.opacity(0.8))
    }
}
