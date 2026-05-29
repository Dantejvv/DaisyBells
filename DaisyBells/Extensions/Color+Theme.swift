import SwiftUI
// UIKit is used solely for UIColor's trait-based initializer to create adaptive light/dark colors.
// SwiftUI's Color has no equivalent API for programmatic adaptive color definitions.
import UIKit

// MARK: - Adaptive Color Initializer

extension Color {
    /// Creates a color that adapts between light and dark mode.
    init(light: Color, dark: Color) {
        self.init(UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}

// MARK: - Design System Colors

extension Color {

    // MARK: Accent — Electric Amber

    /// Primary accent color (#F0A830)
    static let accent = Color(red: 240/255, green: 168/255, blue: 48/255)

    /// Brighter accent for hover/highlight states (#FFD166)
    static let accentBright = Color(red: 255/255, green: 209/255, blue: 102/255)

    /// Dimmed accent for subtle treatments (#B87D1A)
    static let accentDim = Color(red: 184/255, green: 125/255, blue: 26/255)

    // MARK: Backgrounds

    /// Main app background. Dark = pure black so the iOS keyboard window's
    /// black backdrop strips at the bottom corners blend in seamlessly.
    static let bgPrimary = Color(
        light: Color(red: 245/255, green: 245/255, blue: 247/255),
        dark: Color(red: 0/255, green: 0/255, blue: 0/255)
    )

    /// Elevated surface — nav bars, tab bars
    static let bgElevated = Color(
        light: Color(red: 255/255, green: 255/255, blue: 255/255),
        dark: Color(red: 22/255, green: 22/255, blue: 24/255)
    )

    /// Card / grouped list background
    static let bgCard = Color(
        light: Color(red: 255/255, green: 255/255, blue: 255/255),
        dark: Color(red: 28/255, green: 28/255, blue: 31/255)
    )

    /// Card hover / pressed state
    static let bgCardHover = Color(
        light: Color(red: 235/255, green: 235/255, blue: 240/255),
        dark: Color(red: 36/255, green: 36/255, blue: 40/255)
    )

    /// Input field background
    static let bgInput = Color(
        light: Color(red: 240/255, green: 240/255, blue: 243/255),
        dark: Color(red: 26/255, green: 26/255, blue: 29/255)
    )

    /// Sheet background. Dark = pure black to match bgPrimary so the iOS
    /// keyboard's host-window backdrop blends with sheet content (no visible
    /// dark strips at the bottom corners when the keyboard is up).
    static let bgSheet = Color(
        light: Color(red: 242/255, green: 242/255, blue: 247/255),
        dark: Color(red: 0/255, green: 0/255, blue: 0/255)
    )

    // MARK: Text

    /// Primary text
    static let textPrimary = Color(
        light: Color(red: 28/255, green: 28/255, blue: 30/255),
        dark: Color(red: 245/255, green: 245/255, blue: 247/255)
    )

    /// Secondary text — labels, descriptions
    static let textSecondary = Color(
        light: Color(red: 108/255, green: 108/255, blue: 112/255),
        dark: Color(red: 142/255, green: 142/255, blue: 147/255)
    )

    /// Tertiary text — placeholders, captions
    static let textTertiary = Color(
        light: Color(red: 160/255, green: 160/255, blue: 168/255),
        dark: Color(red: 90/255, green: 90/255, blue: 94/255)
    )

    // MARK: Semantic

    /// Success state (#34C759)
    static let success = Color(red: 52/255, green: 199/255, blue: 89/255)

    /// Warning state (#FF9F0A)
    static let warning = Color(red: 255/255, green: 159/255, blue: 10/255)

    /// Destructive / error state (#FF453A)
    static let destructive = Color(red: 255/255, green: 69/255, blue: 58/255)

    /// Informational state (#5AC8FA)
    static let info = Color(red: 90/255, green: 200/255, blue: 250/255)

    // MARK: Semantic Backgrounds (low-opacity tints)

    static let accentBg = Color.accent.opacity(0.10)
    static let accentBgStrong = Color.accent.opacity(0.18)
    static let successBg = Color.success.opacity(0.12)
    static let warningBg = Color.warning.opacity(0.12)
    static let destructiveBg = Color.destructive.opacity(0.12)
    static let infoBg = Color.info.opacity(0.12)

    // MARK: Borders

    /// Subtle border — card edges, dividers
    static let borderSubtle = Color(
        light: Color.black.opacity(0.06),
        dark: Color.white.opacity(0.06)
    )

    /// Default border — inputs, interactive elements
    static let borderDefault = Color(
        light: Color.black.opacity(0.10),
        dark: Color.white.opacity(0.10)
    )

    /// Strong border — focused inputs, hover states
    static let borderStrong = Color(
        light: Color.black.opacity(0.16),
        dark: Color.white.opacity(0.16)
    )
}
