import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: AstralTheme.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: icon)
                    .scaledFont(size: 18, relativeTo: .body, weight: .semibold)
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }

            Text(value)
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(Color.astralText)

            Text(title)
                .scaledFont(size: 11, relativeTo: .caption2, weight: .medium, design: .rounded)
                .foregroundStyle(Color.astralTextMuted)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, AstralTheme.Spacing.md)
        .padding(.horizontal, AstralTheme.Spacing.sm)
        .astralCard()
    }
}
