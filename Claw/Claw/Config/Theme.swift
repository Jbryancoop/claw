import SwiftUI

/// Claw app theme — modern terminal aesthetic with green/black palette
enum ClawTheme {
    // MARK: - Core Colors

    /// Near-black background
    static let background = Color(red: 0.06, green: 0.07, blue: 0.08)
    /// Slightly lighter for cards/surfaces
    static let surface = Color(red: 0.10, green: 0.11, blue: 0.13)
    /// Elevated surface (input fields, cards)
    static let surfaceElevated = Color(red: 0.14, green: 0.15, blue: 0.17)
    /// Subtle borders and dividers
    static let border = Color(red: 0.20, green: 0.22, blue: 0.24)

    // MARK: - Accent (Green)

    /// Primary green — modern, slightly teal
    static let accent = Color(red: 0.18, green: 0.85, blue: 0.60)
    /// Muted green for secondary elements
    static let accentMuted = Color(red: 0.15, green: 0.55, blue: 0.40)
    /// Dim green for subtle indicators
    static let accentDim = Color(red: 0.12, green: 0.30, blue: 0.22)
    /// Bright green for highlights
    static let accentBright = Color(red: 0.25, green: 1.0, blue: 0.70)

    // MARK: - Text

    /// Primary text — off-white with slight green tint
    static let textPrimary = Color(red: 0.88, green: 0.93, blue: 0.90)
    /// Secondary text
    static let textSecondary = Color(red: 0.50, green: 0.55, blue: 0.52)
    /// Tertiary/timestamp text
    static let textTertiary = Color(red: 0.35, green: 0.38, blue: 0.36)

    // MARK: - Semantic

    /// User message bubble
    static let userBubble = Color(red: 0.12, green: 0.50, blue: 0.35)
    /// Server message bubble
    static let serverBubble = Color(red: 0.12, green: 0.14, blue: 0.16)
    /// Destructive/error
    static let destructive = Color(red: 0.90, green: 0.30, blue: 0.30)
    /// Unread indicator
    static let unread = accent
    /// Tab bar background
    static let tabBar = Color(red: 0.05, green: 0.06, blue: 0.07)

    // MARK: - Glow Effect

    static func glow(_ color: Color = accent, radius: CGFloat = 8) -> some View {
        color.opacity(0.3).blur(radius: radius)
    }
}

// MARK: - View Modifiers

struct ClawCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(ClawTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(ClawTheme.border, lineWidth: 0.5)
            )
    }
}

extension View {
    func clawCard() -> some View {
        modifier(ClawCardStyle())
    }
}
