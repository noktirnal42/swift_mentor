import SwiftUI
import AppKit

// MARK: - Theme Design System

enum Theme {
    // MARK: - Gradient Presets
    static let blueGradient = LinearGradient(
        colors: [Color(hex: "007AFF"), Color(hex: "5856D6")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let orangeGradient = LinearGradient(
        colors: [Color(hex: "FF9500"), Color(hex: "FF6B35")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let greenGradient = LinearGradient(
        colors: [Color(hex: "34C759"), Color(hex: "30D158")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let purpleGradient = LinearGradient(
        colors: [Color(hex: "9B5DE5"), Color(hex: "5856D6")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let pinkGradient = LinearGradient(
        colors: [Color(hex: "F72585"), Color(hex: "FF2D55")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let tealGradient = LinearGradient(
        colors: [Color(hex: "4ECDC4"), Color(hex: "5AC8FA")],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let textGradient = LinearGradient(
        colors: [Color(hex: "667EEA"), Color(hex: "764BA2")],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let fireGradient = LinearGradient(
        colors: [Color(hex: "FF6B35"), Color(hex: "FF2D55"), Color(hex: "FF9500")],
        startPoint: .leading,
        endPoint: .trailing
    )

    // MARK: - Path Gradients
    static func pathGradient(for colorHex: String) -> LinearGradient {
        let base = Color(hex: colorHex)
        return LinearGradient(
            colors: [base, base.opacity(0.7)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    // MARK: - Spacing (8pt grid)
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius
    enum CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xl: CGFloat = 20
    }

    // MARK: - Shadow
    static func shadow(opacity: Double = 0.15, radius: CGFloat = 8, y: CGFloat = 4) -> Shadow {
        Shadow(color: .black.opacity(opacity), radius: radius, x: 0, y: y)
    }
}

struct Shadow {
    let color: Color
    let radius: CGFloat
    let x: CGFloat
    let y: CGFloat
}

// MARK: - Color Extensions

extension Color {
    // MARK: - Primary Colors
    static let smPrimary = Color.accentColor

    // MARK: - Semantic Colors
    static let smSuccess = Color(hex: "34C759")
    static let smWarning = Color(hex: "FF9500")
    static let smError = Color(hex: "FF3B30")

    // MARK: - Background Colors
    static var smCodeBackground: Color {
        Color(nsColor: NSColor.textBackgroundColor)
    }
    static var smSidebarBackground: Color {
        Color(nsColor: NSColor.windowBackgroundColor)
    }

    // MARK: - Text Colors
    static var smTextPrimary: Color {
        Color(nsColor: NSColor.labelColor)
    }

    static var smTextSecondary: Color {
        Color(nsColor: NSColor.secondaryLabelColor)
    }

    // MARK: - Hex Initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Theme Colors (fallback when assets not loaded)
extension Color {
    static var themePrimary: Color {
        Color(nsColor: NSColor.controlAccentColor)
    }
}
