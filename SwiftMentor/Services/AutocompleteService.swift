import Foundation

final class AutocompleteService {
    static let shared = AutocompleteService()
    private init() {}

    private var cachedSnippets: [CodeSnippet] = []
    private var swiftKeywords: [String] = [
        "actor", "any", "as", "associatedtype", "async", "await", "break", "case", "catch",
        "class", "continue", "default", "defer", "deinit", "do", "else", "enum", "extension",
        "fallthrough", "false", "fileprivate", "final", "for", "func", "get", "guard", "if",
        "import", "in", "indirect", "infix", "init", "inout", "internal", "is", "lazy", "let",
        "mutating", "nil", "nonisolated", "nonmutating", "open", "operator", "optional", "override",
        "postfix", "precedencegroup", "prefix", "private", "protocol", "public", "repeat", "required",
        "rethrows", "return", "self", "Self", "set", "some", "static", "struct", "subscript",
        "super", "switch", "throw", "throws", "true", "try", "typealias", "unowned", "var",
        "weak", "where", "while", "willSet", "didSet"
    ]

    private var swiftTypes: [String] = [
        "Any", "Array", "Bool", "Character", "Dictionary", "Double", "Float", "Int", "Int8",
        "Int16", "Int32", "Int64", "Never", "Optional", "Set", "String", "UInt", "UInt8",
        "UInt16", "UInt32", "UInt64", "Void", "Void"
    ]

    private var foundationTypes: [String] = [
        "NSObject", "NSString", "NSArray", "NSDictionary", "NSNumber", "NSDate", "NSURL",
        "Data", "Date", "DateFormatter", "FileManager", "JSONEncoder", "JSONDecoder",
        "PropertyListEncoder", "PropertyListDecoder", "URL", "URLSession", "UserDefaults"
    ]

    private var swiftuiTypes: [String] = [
        "View", "Text", "Button", "VStack", "HStack", "ZStack", "Spacer", "Image", "Icon",
        "List", "NavigationStack", "NavigationLink", "TabView", "TextField", "TextEditor",
        "Toggle", "Slider", "Stepper", "Picker", "DatePicker", "ColorPicker", "ProgressView",
        "Divider", "Rectangle", "Circle", "RoundedRectangle", "ScrollView", "LazyVStack",
        "LazyHStack", "ForEach", "Group", "TupleView", "EmptyView", "AnyView", "Alert",
        "Sheet", "Popover", "Menu", "ContextMenu"
    ]

    private var swiftuiModifiers: [String] = [
        "padding", "frame", "foregroundColor", "background", "foregroundStyle", "font",
        "bold", "italic", "strikethrough", "underline", "shadow", "blur", "opacity",
        "rotationEffect", "scaleEffect", "offset", "animation", "transition", "onTapGesture",
        "onLongPressGesture", "onAppear", "onDisappear", "onChange", "task", "alert",
        "sheet", "popover", "navigationTitle", "toolbar", "disabled", "hidden", "zIndex"
    ]

    private var swiftuiStateTypes: [String] = [
        "@State", "@Binding", "@Published", "@ObservedObject", "@StateObject",
        "@EnvironmentObject", "@Environment", "@FocusedValue", "@FocusedBinding"
    ]

    func loadSnippets() async {
        if !cachedSnippets.isEmpty { return }

        let topics = ["swift-fundamentals", "swiftui", "metal", "coreml", "concurrency"]

        for topic in topics {
            if let url = Bundle.main.url(forResource: topic, withExtension: "json", subdirectory: "Snippets"),
               let data = try? Data(contentsOf: url),
               let library = try? JSONDecoder().decode(SnippetLibrary.self, from: data) {
                cachedSnippets.append(contentsOf: library.snippets)
            }
        }
    }

    func getSnippets(for topic: String? = nil) -> [CodeSnippet] {
        if let topic = topic {
            return cachedSnippets.filter { $0.topic == topic }
        }
        return cachedSnippets
    }

    func searchSnippets(query: String) -> [CodeSnippet] {
        let lowercased = query.lowercased()
        return cachedSnippets.filter { snippet in
            snippet.title.lowercased().contains(lowercased) ||
            snippet.shortcut.lowercased().contains(lowercased) ||
            snippet.tags.contains { $0.lowercased().contains(lowercased) }
        }
    }

    func getCompletions(for prefix: String, context: AutocompleteContext) -> [AutocompleteCompletion] {
        var completions: [AutocompleteCompletion] = []

        let lowercasedPrefix = prefix.lowercased()

        if context.isInsideSwiftUIModifier {
            completions.append(contentsOf: swiftuiModifiers
                .filter { $0.lowercased().hasPrefix(lowercasedPrefix) }
                .map { AutocompleteCompletion(text: $0, type: .modifier, detail: "SwiftUI modifier") })
        } else if context.isAfterStateAnnotation {
            completions.append(contentsOf: swiftTypes
                .filter { $0.lowercased().hasPrefix(lowercasedPrefix) }
                .map { AutocompleteCompletion(text: $0, type: .type, detail: "Swift type") })
        } else if context.isSwiftUIContext {
            completions.append(contentsOf: swiftuiTypes
                .filter { $0.lowercased().hasPrefix(lowercasedPrefix) }
                .map { AutocompleteCompletion(text: $0, type: .type, detail: "SwiftUI type") })
            completions.append(contentsOf: swiftuiStateTypes
                .filter { $0.lowercased().hasPrefix(lowercasedPrefix) }
                .map { AutocompleteCompletion(text: $0, type: .keyword, detail: "SwiftUI property wrapper") })
        } else {
            completions.append(contentsOf: swiftKeywords
                .filter { $0.lowercased().hasPrefix(lowercasedPrefix) }
                .map { AutocompleteCompletion(text: $0, type: .keyword, detail: "Swift keyword") })

            completions.append(contentsOf: swiftTypes
                .filter { $0.lowercased().hasPrefix(lowercasedPrefix) }
                .map { AutocompleteCompletion(text: $0, type: .type, detail: "Swift type") })

            completions.append(contentsOf: foundationTypes
                .filter { $0.lowercased().hasPrefix(lowercasedPrefix) }
                .map { AutocompleteCompletion(text: $0, type: .type, detail: "Foundation type") })
        }

        let matchingSnippets = cachedSnippets.filter { snippet in
            snippet.shortcut.lowercased().hasPrefix(lowercasedPrefix) ||
            snippet.title.lowercased().hasPrefix(lowercasedPrefix)
        }
        completions.append(contentsOf: matchingSnippets.map {
            AutocompleteCompletion(text: $0.shortcut, type: .snippet, detail: $0.title, snippet: $0)
        })

        return completions
            .sorted { $0.text.count < $1.text.count }
            .prefix(10)
            .map { $0 }
    }
}

struct AutocompleteCompletion: Identifiable {
    let id = UUID()
    let text: String
    let type: CompletionType
    let detail: String
    var snippet: CodeSnippet?

    enum CompletionType {
        case keyword
        case type
        case modifier
        case snippet
        case method
    }
}

struct AutocompleteContext {
    var currentText: String
    var cursorPosition: Int
    var isSwiftUIContext: Bool
    var isInsideSwiftUIModifier: Bool
    var isAfterStateAnnotation: Bool

    init(currentText: String, cursorPosition: Int) {
        self.currentText = currentText
        self.cursorPosition = cursorPosition

        let textBeforeCursor = String(currentText.prefix(cursorPosition))
        isSwiftUIContext = textBeforeCursor.contains("SwiftUI") ||
                          textBeforeCursor.contains("import SwiftUI") ||
                          textBeforeCursor.contains(": View")

        isInsideSwiftUIModifier = textBeforeCursor.contains(".background") ||
                                  textBeforeCursor.contains(".foreground") ||
                                  textBeforeCursor.contains(".frame") ||
                                  textBeforeCursor.contains(".padding")

        isAfterStateAnnotation = textBeforeCursor.contains("@State") ||
                                 textBeforeCursor.contains("@Binding") ||
                                 textBeforeCursor.contains("@Published")
    }
}