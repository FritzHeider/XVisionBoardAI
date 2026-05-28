//
//  SharedCards.swift
//  XVisionBoardAI
//
//  Created by AI Assistant
//  Copyright © 2025 XVisionBoard AI. All rights reserved.
//

import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)

            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.cosmicWhite)

            Text(title)
                .font(.caption)
                .foregroundColor(.cosmicWhite.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .cosmicCard()
    }
}
