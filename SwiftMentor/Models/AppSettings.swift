import Foundation

struct AppSettings: Codable, Equatable {
    var appearance: AppearanceMode
    var codeEditorFontSize: Int
    var codeEditorFontName: String
    var showLineNumbers: Bool
    var enableAutocomplete: Bool
    var enableInlineAI: Bool
    var enableSoundEffects: Bool
    var showPreviewPanel: Bool
    var autoSaveProgress: Bool
    var aiConfiguration: AIConfiguration

    init() {
        appearance = .system
        codeEditorFontSize = 14
        codeEditorFontName = "SF Mono"
        showLineNumbers = true
        enableAutocomplete = true
        enableInlineAI = true
        enableSoundEffects = true
        showPreviewPanel = true
        autoSaveProgress = true
        aiConfiguration = AIConfiguration()
    }

    enum AppearanceMode: String, Codable, CaseIterable {
        case light
        case dark
        case system

        var displayName: String {
            rawValue.capitalized
        }
    }
}

enum AppSection: String, CaseIterable, Identifiable {
    case dashboard
    case learningPaths
    case playground
    case progress
    case snippets
    case settings
    case aiAssistant

    var id: String { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Dashboard"
        case .learningPaths: return "Learning Paths"
        case .playground: return "Playground"
        case .progress: return "Progress"
        case .snippets: return "Snippets"
        case .settings: return "Settings"
        case .aiAssistant: return "AI Assistant"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "house.fill"
        case .learningPaths: return "book.fill"
        case .playground: return "terminal.fill"
        case .progress: return "chart.bar.fill"
        case .snippets: return "doc.text.fill"
        case .settings: return "gearshape.fill"
        case .aiAssistant: return "brain"
        }
    }
}