import SwiftUI

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

    /// Main app background (#0C0C0E)
    static let bgPrimary = Color(red: 12/255, green: 12/255, blue: 14/255)

    /// Elevated surface — nav bars, tab bars (#161618)
    static let bgElevated = Color(red: 22/255, green: 22/255, blue: 24/255)

    /// Card / grouped list background (#1C1C1F)
    static let bgCard = Color(red: 28/255, green: 28/255, blue: 31/255)

    /// Card hover / pressed state (#242428)
    static let bgCardHover = Color(red: 36/255, green: 36/255, blue: 40/255)

    /// Input field background (#1A1A1D)
    static let bgInput = Color(red: 26/255, green: 26/255, blue: 29/255)

    /// Sheet background (#131315)
    static let bgSheet = Color(red: 19/255, green: 19/255, blue: 21/255)

    // MARK: Text

    /// Primary text (#F5F5F7)
    static let textPrimary = Color(red: 245/255, green: 245/255, blue: 247/255)

    /// Secondary text — labels, descriptions (#8E8E93)
    static let textSecondary = Color(red: 142/255, green: 142/255, blue: 147/255)

    /// Tertiary text — placeholders, captions (#5A5A5E)
    static let textTertiary = Color(red: 90/255, green: 90/255, blue: 94/255)

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

    /// Subtle border — card edges, dividers (6% white)
    static let borderSubtle = Color.white.opacity(0.06)

    /// Default border — inputs, interactive elements (10% white)
    static let borderDefault = Color.white.opacity(0.10)

    /// Strong border — focused inputs, hover states (16% white)
    static let borderStrong = Color.white.opacity(0.16)
}
