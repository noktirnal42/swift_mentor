import Foundation
import AppKit
import Splash

// MARK: - Syntax Highlighting Service (Splash-powered)

/// Provides Swift syntax highlighting using the Splash library.
/// Used by both the code editor (NSAttributedString for NSTextView)
/// and read-only code blocks (AttributedString for SwiftUI Text).
///
/// NOTE: Splash 0.16.0 Theme+Defaults static methods (e.g. Theme.wwdc18)
/// are not visible under Xcode 26's explicit module build system due to
/// conditional compilation resolution issues. We construct Theme directly
/// using the public init(font:plainTextColor:tokenColors:backgroundColor:).
/// See GitHub Issue #6 for details.
final class SyntaxHighlightingService {

    static let shared = SyntaxHighlightingService()

    private let highlighter: SyntaxHighlighter<AttributedStringOutputFormat>

    init() {
        let splashFont = Font(size: 14)

        // Construct theme directly — WWDC18-inspired color scheme
        let theme = Splash.Theme(
            font: splashFont,
            plainTextColor: NSColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.9),
            tokenColors: [
                .keyword:          NSColor(red: 0.948, green: 0.140, blue: 0.547, alpha: 1.0),
                .string:           NSColor(red: 0.988, green: 0.273, blue: 0.317, alpha: 1.0),
                .type:             NSColor(red: 0.584, green: 0.898, blue: 0.361, alpha: 1.0),
                .call:             NSColor(red: 0.584, green: 0.898, blue: 0.361, alpha: 1.0),
                .number:           NSColor(red: 0.587, green: 0.517, blue: 0.974, alpha: 1.0),
                .comment:          NSColor(red: 0.424, green: 0.475, blue: 0.529, alpha: 1.0),
                .property:         NSColor(red: 0.584, green: 0.898, blue: 0.361, alpha: 1.0),
                .dotAccess:        NSColor(red: 0.584, green: 0.898, blue: 0.361, alpha: 1.0),
                .preprocessing:    NSColor(red: 0.952, green: 0.526, blue: 0.229, alpha: 1.0),
            ],
            backgroundColor: NSColor(red: 0.163, green: 0.163, blue: 0.182, alpha: 1.0)
        )
        self.highlighter = SyntaxHighlighter(format: AttributedStringOutputFormat(theme: theme))
    }

    // MARK: - NSAttributedString (for NSTextView)

    /// Returns a syntax-highlighted `NSAttributedString` for the given Swift code.
    func highlightedAttributedString(for code: String) -> NSAttributedString {
        guard !code.isEmpty else {
            return NSAttributedString(string: "")
        }
        return highlighter.highlight(code)
    }

    // MARK: - AttributedString (for SwiftUI Text)

    /// Returns a syntax-highlighted Swift `AttributedString` for use in SwiftUI `Text`.
    func highlightedSwiftString(for code: String) -> AttributedString {
        let nsAttr = highlightedAttributedString(for: code)
        // On macOS, use appKit attribute scope
        do {
            let attrStr = try AttributedString(nsAttr, including: \.appKit)
            return attrStr
        } catch {
            // Fallback: plain string
            return AttributedString(stringLiteral: code)
        }
    }
}
