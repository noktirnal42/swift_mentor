import Foundation

struct AIMessage: Codable, Identifiable, Hashable {
    let id: String
    let role: AIRole
    let content: String
    let timestamp: Date
    let codeBlocks: [String]
    let isPartial: Bool

    init(id: String = UUID().uuidString, role: AIRole, content: String, timestamp: Date = Date(), codeBlocks: [String] = [], isPartial: Bool = false) {
        self.id = id
        self.role = role
        self.content = content
        self.timestamp = timestamp
        self.codeBlocks = codeBlocks
        self.isPartial = isPartial
    }

    enum AIRole: String, Codable {
        case user
        case assistant
        case system
    }
}

enum AIProvider: String, Codable, CaseIterable {
    case ollama
    case lmStudio
    case both

    var displayName: String {
        switch self {
        case .ollama: return "Ollama"
        case .lmStudio: return "LM Studio"
        case .both: return "Both (Auto-detect)"
        }
    }

    var defaultEndpoint: String {
        switch self {
        case .ollama: return "http://localhost:11434"
        case .lmStudio: return "http://localhost:1234"
        case .both: return "http://localhost:11434"
        }
    }
}

struct AIConfiguration: Codable, Equatable {
    var provider: AIProvider
    var ollamaEndpoint: String
    var lmStudioEndpoint: String
    var selectedModel: String
    var availableModels: [String]
    var temperature: Double
    var maxTokens: Int
    var systemPrompt: String
    var isConnected: Bool

    init() {
        provider = .ollama
        ollamaEndpoint = "http://localhost:11434"
        lmStudioEndpoint = "http://localhost:1234"
        selectedModel = "llama3"
        availableModels = ["llama3", "codellama", "mistral", "phi3"]
        temperature = 0.7
        maxTokens = 2048
        systemPrompt = "You are an expert Apple development educator helping users learn Swift, SwiftUI, Metal, CoreML, and iOS/macOS development. Provide clear, concise explanations with code examples when helpful. Format code blocks with proper syntax highlighting."
        isConnected = false
    }

    var activeEndpoint: String {
        switch provider {
        case .ollama, .both:
            return ollamaEndpoint
        case .lmStudio:
            return lmStudioEndpoint
        }
    }
}

struct AIChatSession: Identifiable, Codable {
    let id: String
    var title: String
    var messages: [AIMessage]
    let createdAt: Date
    var lastMessageAt: Date

    init(id: String = UUID().uuidString, title: String = "New Chat") {
        self.id = id
        self.title = title
        self.messages = []
        self.createdAt = Date()
        self.lastMessageAt = Date()
    }

    mutating func addMessage(_ message: AIMessage) {
        messages.append(message)
        lastMessageAt = Date()
        if messages.count == 1 {
            title = String(message.content.prefix(50))
        }
    }
}

struct AISuggestion: Identifiable {
    let id: String
    let type: SuggestionType
    let content: String
    let line: Int?
    let confidence: Double

enum SuggestionType: String {
    case completion
    case errorFix
    case refactor
    case explanation
}
}