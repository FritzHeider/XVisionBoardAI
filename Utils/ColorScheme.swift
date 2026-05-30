import SwiftUI

// MARK: - Astral Color Palette

extension Color {
    // Backgrounds — deep navy-black space
    static let astralBlack    = Color(red: 0.024, green: 0.024, blue: 0.071)   // #060612
    static let astralSurface  = Color(red: 0.051, green: 0.051, blue: 0.125)   // #0D0D20
    static let astralSurface2 = Color(red: 0.075, green: 0.075, blue: 0.188)   // #131330

    // Brand
    static let astralViolet = Color(red: 0.655, green: 0.545, blue: 0.980)     // #A78BFA
    static let astralRose   = Color(red: 0.957, green: 0.443, blue: 0.714)     // #F472B6
    static let astralGold   = Color(red: 0.984, green: 0.690, blue: 0.251)     // #FBB040
    static let astralIndigo = Color(red: 0.506, green: 0.549, blue: 0.973)     // #818CF8
    static let astralMint   = Color(red: 0.204, green: 0.827, blue: 0.600)     // #34D399

    // Text
    static let astralText        = Color(red: 0.941, green: 0.941, blue: 1.000) // #F0F0FF
    static let astralTextMuted   = Color(red: 0.565, green: 0.565, blue: 0.722) // #9090B8
    static let astralTextDim     = Color(red: 0.314, green: 0.314, blue: 0.471) // #505078

    // Semantic
    static let astralError   = Color(red: 0.973, green: 0.529, blue: 0.529)    // #F87171
    static let astralSuccess = Color.astralMint

    // Backward-compat aliases — existing views keep compiling
    static let cosmicPurple  = astralViolet
    static let cosmicBlue    = astralIndigo
    static let cosmicPink    = astralRose
    static let cosmicGold    = astralGold
    static let cosmicBlack   = astralBlack
    static let cosmicGray    = astralSurface
    static let cosmicWhite   = astralText
    static let cosmicGradient = auroraGradient
    static let goldGradient  = LinearGradient(
        colors: [.astralGold, Color(red: 1.0, green: 0.85, blue: 0.50)],
        startPoint: .leading, endPoint: .trailing
    )
    static let manifestationPrimary    = astralViolet
    static let manifestationSecondary  = astralRose
    static let manifestationAccent     = astralGold
    static let manifestationBackground = astralBlack
    static let manifestationSurface    = astralSurface
    static let adaptiveCTA = astralViolet

    // Gradients
    static let auroraGradient = LinearGradient(
        colors: [.astralViolet, .astralIndigo, .astralRose],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )

    static let auroraHeroGradient = LinearGradient(
        colors: [
            Color(red: 0.10, green: 0.06, blue: 0.22),
            Color(red: 0.05, green: 0.05, blue: 0.16),
            Color.astralBlack
        ],
        startPoint: .top, endPoint: .bottom
    )
}

// MARK: - Spacing & Radius Tokens

enum AstralTheme {
    enum Spacing {
        static let xs:  CGFloat = 4
        static let sm:  CGFloat = 8
        static let md:  CGFloat = 16
        static let lg:  CGFloat = 24
        static let xl:  CGFloat = 32
        static let xxl: CGFloat = 48
    }

    enum Radius {
        static let sm:   CGFloat = 10
        static let md:   CGFloat = 14
        static let lg:   CGFloat = 20
        static let xl:   CGFloat = 26
        static let full: CGFloat = 999
    }

    enum Motion {
        static let micro  = Animation.spring(response: 0.2, dampingFraction: 0.7)
        static let quick  = Animation.spring(response: 0.3, dampingFraction: 0.8)
        static let smooth = Animation.spring(response: 0.5, dampingFraction: 0.85)
        static let breathe = Animation.easeInOut(duration: 1.8)
    }
}

// MARK: - Glass Card

struct AstralGlassModifier: ViewModifier {
    var tint: Color = .astralViolet
    var radius: CGFloat = AstralTheme.Radius.xl

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .background {
                    RoundedRectangle(cornerRadius: radius)
                        .fill(tint.opacity(0.08))
                        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: radius))
                }
                .shadow(color: tint.opacity(0.18), radius: 14, x: 0, y: 6)
        } else {
            content
                .background {
                    ZStack {
                        RoundedRectangle(cornerRadius: radius)
                            .fill(.ultraThinMaterial)
                        RoundedRectangle(cornerRadius: radius)
                            .fill(tint.opacity(0.07))
                        RoundedRectangle(cornerRadius: radius)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [tint.opacity(0.55), Color.white.opacity(0.08), tint.opacity(0.18)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                }
                .shadow(color: tint.opacity(0.22), radius: 18, x: 0, y: 8)
                .shadow(color: .black.opacity(0.50), radius: 32, x: 0, y: 16)
        }
    }
}

// MARK: - Solid Card

struct AstralCardModifier: ViewModifier {
    var radius: CGFloat = AstralTheme.Radius.lg

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: radius)
                    .fill(Color.astralSurface)
                    .overlay {
                        RoundedRectangle(cornerRadius: radius)
                            .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
                    }
            }
            .shadow(color: .black.opacity(0.40), radius: 16, x: 0, y: 8)
    }
}

// MARK: - Button

struct AstralButtonModifier: ViewModifier {
    enum ButtonStyle { case primary, gold, secondary, ghost }

    let style: ButtonStyle
    let isEnabled: Bool
    @State private var pressed = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(style: ButtonStyle = .primary, isEnabled: Bool = true) {
        self.style = style
        self.isEnabled = isEnabled
    }

    private var fill: AnyShapeStyle {
        guard isEnabled else {
            return AnyShapeStyle(Color.astralSurface)
        }
        switch style {
        case .primary:
            return AnyShapeStyle(LinearGradient(
                colors: [.astralViolet, .astralIndigo],
                startPoint: .leading, endPoint: .trailing
            ))
        case .gold:
            return AnyShapeStyle(LinearGradient(
                colors: [.astralGold, Color(red: 1.0, green: 0.82, blue: 0.40)],
                startPoint: .leading, endPoint: .trailing
            ))
        case .secondary:
            return AnyShapeStyle(Color.astralSurface2)
        case .ghost:
            return AnyShapeStyle(Color.clear)
        }
    }

    private var glowColor: Color {
        guard isEnabled else { return .clear }
        switch style {
        case .primary: return .astralViolet
        case .gold:    return .astralGold
        default:       return .clear
        }
    }

    func body(content: Content) -> some View {
        content
            .foregroundStyle(isEnabled ? Color.astralText : Color.astralTextDim)
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .padding(.horizontal, AstralTheme.Spacing.xl)
            .padding(.vertical, AstralTheme.Spacing.md)
            .background {
                if #available(iOS 26, *), style == .primary || style == .gold {
                    Capsule()
                        .fill(fill)
                        .glassEffect(.regular.interactive(), in: Capsule())
                } else {
                    Capsule().fill(fill)
                        .overlay {
                            if style == .ghost || style == .secondary {
                                Capsule().strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                            }
                        }
                }
            }
            .shadow(color: glowColor.opacity(0.40), radius: 14, x: 0, y: 6)
            .scaleEffect(isEnabled ? (pressed ? 0.97 : 1.0) : 0.95)
            .opacity(isEnabled ? 1.0 : 0.45)
            .animation(reduceMotion ? .none : AstralTheme.Motion.micro, value: pressed)
    }
}

// MARK: - Pulsing

struct AstralPulsingModifier: ViewModifier {
    @State private var active = false
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content
            .scaleEffect(active ? 1.05 : 1.0)
            .opacity(active ? 0.85 : 1.0)
            .animation(
                reduceMotion ? .none : AstralTheme.Motion.breathe.repeatForever(autoreverses: true),
                value: active
            )
            .onAppear { if !reduceMotion { active = true } }
    }
}

// MARK: - Shimmer (loading skeleton)

struct AstralShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func body(content: Content) -> some View {
        content.overlay {
            if !reduceMotion {
                GeometryReader { geo in
                    LinearGradient(
                        colors: [.clear, Color.white.opacity(0.08), .clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .offset(x: phase * geo.size.width * 2)
                    .animation(
                        .linear(duration: 1.4).repeatForever(autoreverses: false),
                        value: phase
                    )
                    .onAppear { phase = 1 }
                }
                .clipShape(.rect(cornerRadius: AstralTheme.Radius.md))
            }
        }
    }
}

// MARK: - View Extensions

extension View {
    func astralGlass(tint: Color = .astralViolet, radius: CGFloat = AstralTheme.Radius.xl) -> some View {
        modifier(AstralGlassModifier(tint: tint, radius: radius))
    }

    func astralCard(radius: CGFloat = AstralTheme.Radius.lg) -> some View {
        modifier(AstralCardModifier(radius: radius))
    }

    func astralButton(_ style: AstralButtonModifier.ButtonStyle = .primary, isEnabled: Bool = true) -> some View {
        modifier(AstralButtonModifier(style: style, isEnabled: isEnabled))
    }

    func astralPulsing() -> some View {
        modifier(AstralPulsingModifier())
    }

    func astralShimmer() -> some View {
        modifier(AstralShimmerModifier())
    }

    // Backward-compat aliases
    func cosmicCard() -> some View              { astralCard() }
    func cosmicGlowCard(color: Color = .astralViolet) -> some View { astralGlass(tint: color) }
    func cosmicButton(isEnabled: Bool = true) -> some View { astralButton(.primary, isEnabled: isEnabled) }
    func pulsing() -> some View                 { astralPulsing() }
}

// MARK: - Typography

extension View {
    func manifestationTitle() -> some View {
        self
            .font(.system(.largeTitle, design: .rounded, weight: .bold))
            .foregroundStyle(Color.auroraGradient)
    }

    func manifestationSubtitle() -> some View {
        self
            .font(.system(.title2, design: .rounded, weight: .semibold))
            .foregroundStyle(Color.astralText)
    }

    func manifestationBody() -> some View {
        self
            .font(.system(.body, design: .rounded))
            .foregroundStyle(Color.astralTextMuted)
    }
}
