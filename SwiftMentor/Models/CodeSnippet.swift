import Foundation

struct CodeSnippet: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let shortcut: String
    let topic: String
    let description: String
    let code: String
    let tags: [String]
    let isBuiltIn: Bool

    init(id: String, title: String, shortcut: String, topic: String, description: String, code: String, tags: [String], isBuiltIn: Bool = true) {
        self.id = id
        self.title = title
        self.shortcut = shortcut
        self.topic = topic
        self.description = description
        self.code = code
        self.tags = tags
        self.isBuiltIn = isBuiltIn
    }

    var placeholderRanges: [(index: Int, placeholder: String)] {
        var ranges: [(Int, String)] = []
        let pattern = #"\$\{(\d+):([^}]+)\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        let nsCode = code as NSString
        let matches = regex.matches(in: code, range: NSRange(location: 0, length: nsCode.length))

        for match in matches {
            if match.numberOfRanges >= 3 {
                let indexRange = match.range(at: 1)
                let placeholderRange = match.range(at: 2)
                let index = Int(nsCode.substring(with: indexRange)) ?? 0
                let placeholder = nsCode.substring(with: placeholderRange)
                ranges.append((index, placeholder))
            }
        }
        return ranges.sorted { (a, b) in a.0 < b.0 }
    }

    var displayCode: String {
        code.replacingOccurrences(of: #"\$\{\d+:"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\$\{\d+\}"#, with: "", options: .regularExpression)
    }
}

struct SnippetCategory: Identifiable {
    let id: String
    let name: String
    let icon: String
    var snippets: [CodeSnippet]

    static let builtInTopics: [String] = [
        "swift-fundamentals",
        "swiftui",
        "metal",
        "coreml",
        "concurrency"
    ]
}

struct SnippetLibrary: Codable {
    let snippets: [CodeSnippet]
}