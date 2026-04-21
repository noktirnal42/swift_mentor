import Foundation
import AppKit

extension String {
    // MARK: - Sanitization for File Names
    var sanitizedFileName: String {
        let invalidCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|")
            .union(.controlCharacters)
            .union(.newlines)
        return components(separatedBy: invalidCharacters).joined(separator: "_")
    }

    // MARK: - Code Trimming
    var trimmedCode: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Line Count
    var lineCount: Int {
        var count = 0
        enumerateLines { _, _ in count += 1 }
        return count
    }

    // MARK: - Indent Level
    var indentLevel: Int {
        var level = 0
        for char in self {
            if char == " " {
                level += 1
            } else if char == "\t" {
                level += 4
            } else {
                break
            }
        }
        return level
    }

    // MARK: - Extract Code Blocks (multiple)
    func extractCodeBlocks() -> [String] {
        let pattern = "```[a-z]*\\n?([\\s\\S]*?)```"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let matches = regex.matches(in: self, range: NSRange(startIndex..., in: self))
        return matches.compactMap { match in
            guard let range = Range(match.range(at: 1), in: self) else { return nil }
            return String(self[range])
        }
    }

    // MARK: - Extract Code Block
    func extractCodeBlock(language: String = "swift") -> String? {
        let pattern = "```\\(language)\\n([\\s\\S]*?)```"
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: self, range: NSRange(startIndex..., in: self)),
              let range = Range(match.range(at: 1), in: self) else {
            return nil
        }
        return String(self[range])
    }

    // MARK: - Highlight Pattern
    func highlightPattern(_ pattern: String, with color: String = "red") -> NSAttributedString {
        let attributedString = NSMutableAttributedString(string: self)
        guard let regex = try? NSRegularExpression(pattern: pattern) else {
            return attributedString
        }
        let range = NSRange(startIndex..., in: self)
        regex.enumerateMatches(in: self, range: range) { match, _, _ in
            if let matchRange = match?.range {
                attributedString.addAttribute(.foregroundColor, value: NSColor.systemRed, range: matchRange)
            }
        }
        return attributedString
    }

    // MARK: - Base64 Encoding
    var base64Encoded: String? {
        data(using: .utf8)?.base64EncodedString()
    }

    var base64Decoded: String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

    // MARK: - JSON Validation
    var isValidJSON: Bool {
        guard let data = self.data(using: .utf8) else { return false }
        return (try? JSONSerialization.jsonObject(with: data)) != nil
    }

    // MARK: - URL Validation
    var isValidURL: Bool {
        URL(string: self) != nil
    }

    // MARK: - Highlight as Markdown (placeholder - returns self as plain text)
    var highlightedAsMarkdown: String {
        return self
    }
}