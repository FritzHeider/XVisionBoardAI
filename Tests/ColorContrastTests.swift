//
//  ColorContrastTests.swift
//  XVisionBoardAITests
//
//  Locks in the WCAG AA contrast fix. These ratios were measured and corrected
//  after an audit found astralTextDim at 1.78:1 and astralTextMuted at 3.87:1 on
//  card surfaces — both below the 4.5:1 floor for body text, on real content
//  (card dates, "Coming soon" pills, unachieved-goal icons).
//
//  If someone retunes the palette and drops a token below AA, these fail.
//

import Testing
import SwiftUI
import UIKit
@testable import XVisionBoardAI

/// WCAG 2.1 relative luminance and contrast, per
/// https://www.w3.org/TR/WCAG21/#dfn-relative-luminance
private enum WCAG {
    static func relativeLuminance(_ color: Color) -> Double {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        UIColor(color).getRed(&r, green: &g, blue: &b, alpha: &a)

        func channel(_ c: CGFloat) -> Double {
            let v = Double(c)
            return v <= 0.03928 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * channel(r) + 0.7152 * channel(g) + 0.0722 * channel(b)
    }

    static func contrastRatio(_ a: Color, _ b: Color) -> Double {
        let la = relativeLuminance(a)
        let lb = relativeLuminance(b)
        let hi = max(la, lb)
        let lo = min(la, lb)
        return (hi + 0.05) / (lo + 0.05)
    }

    /// WCAG AA minimum for normal-size body text.
    static let bodyTextMinimum = 4.5
}

@Suite("Text colour contrast meets WCAG AA")
struct ColorContrastTests {

    /// Every surface a text token can sit on. astralSurface2 is the lightest and
    /// therefore the worst case for light-on-dark text, so it governs.
    private static let surfaces: [(name: String, color: Color)] = [
        ("astralBlack", .astralBlack),
        ("astralSurface", .astralSurface),
        ("astralSurface2", .astralSurface2),
    ]

    private static let textTokens: [(name: String, color: Color)] = [
        ("astralText", .astralText),
        ("astralTextMuted", .astralTextMuted),
        ("astralTextDim", .astralTextDim),
    ]

    @Test(
        "Each text token clears 4.5:1 on every surface",
        arguments: textTokens, surfaces
    )
    func textTokenClearsAAOnSurface(
        token: (name: String, color: Color),
        surface: (name: String, color: Color)
    ) {
        let ratio = WCAG.contrastRatio(token.color, surface.color)
        #expect(
            ratio >= WCAG.bodyTextMinimum,
            """
            \(token.name) on \(surface.name) is \(String(format: "%.2f", ratio)):1, \
            below the WCAG AA body-text floor of \(WCAG.bodyTextMinimum):1.
            """
        )
    }

    @Test("Text tiers stay visually distinguishable")
    func textTiersRemainOrdered() {
        // If a future contrast fix flattens these to the same luminance, the
        // primary/muted/dim hierarchy stops reading even though AA still passes.
        let text = WCAG.relativeLuminance(.astralText)
        let muted = WCAG.relativeLuminance(.astralTextMuted)
        let dim = WCAG.relativeLuminance(.astralTextDim)

        #expect(text > muted, "astralText must be brighter than astralTextMuted")
        #expect(muted > dim, "astralTextMuted must be brighter than astralTextDim")
    }

    @Test("Error colour is legible on the app background")
    func errorColourIsLegible() {
        let ratio = WCAG.contrastRatio(.astralError, .astralBlack)
        #expect(
            ratio >= 3.0,
            "astralError on astralBlack is \(String(format: "%.2f", ratio)):1; error text must stand out."
        )
    }
}
