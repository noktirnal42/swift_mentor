import Foundation

final class AIService: ObservableObject {
    static let shared = AIService()

    @Published var isConnected: Bool = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var availableModels: [String] = []

    private var configuration: AIConfiguration
    private let session: URLSession

    enum ConnectionStatus {
        case disconnected
        case connecting
        case connected
        case error(String)

        var displayText: String {
            switch self {
            case .disconnected: return "Disconnected"
            case .connecting: return "Connecting..."
            case .connected: return "Connected"
            case .error(let msg): return "Error: \(msg)"
            }
        }

        var color: String {
            switch self {
            case .disconnected: return "gray"
            case .connecting: return "orange"
            case .connected: return "green"
            case .error: return "red"
            }
        }
    }

    private init() {
        self.configuration = AIConfiguration()
        self.session = URLSession(configuration: .default)

        loadConfiguration()
    }

    private func loadConfiguration() {
        if let data = UserDefaults.standard.data(forKey: "aiConfiguration"),
           let config = try? JSONDecoder().decode(AIConfiguration.self, from: data) {
            self.configuration = config
        }
    }

    func saveConfiguration(_ config: AIConfiguration) {
        self.configuration = config
        if let data = try? JSONEncoder().encode(config) {
            UserDefaults.standard.set(data, forKey: "aiConfiguration")
        }
    }

    func getConfiguration() -> AIConfiguration {
        return configuration
    }

    func checkConnection() async {
        await MainActor.run {
            connectionStatus = .connecting
        }
        
        let endpoints = [configuration.ollamaEndpoint, configuration.lmStudioEndpoint]
        var connectedEndpoint: String?
        
        for endpoint in endpoints {
            do {
                let url = URL(string: "\(endpoint)/api/tags")!
                let (_, response) = try await session.data(from: url)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    connectedEndpoint = endpoint
                    break
                }
            } catch {
                continue
            }
        }
        
        let resolvedEndpoint = connectedEndpoint

        await MainActor.run {
            if resolvedEndpoint != nil {
                isConnected = true
                connectionStatus = .connected
                Task { await fetchAvailableModels() }
            } else {
                isConnected = false
                connectionStatus = .disconnected
            }
        }
    }
    
    func testConnection() async throws {
        await MainActor.run {
            connectionStatus = .connecting
        }

        let endpoints = [configuration.ollamaEndpoint, configuration.lmStudioEndpoint]
        var connectedEndpoint: String?

        for endpoint in endpoints {
            do {
                let url = URL(string: "\(endpoint)/api/tags")!
                let (_, response) = try await session.data(from: url)
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                    connectedEndpoint = endpoint
                    break
                }
            } catch {
                continue
            }
        }

        let resolvedEndpoint = connectedEndpoint

        await MainActor.run {
            if let endpoint = resolvedEndpoint {
                isConnected = true
                connectionStatus = .connected
                if endpoint == configuration.ollamaEndpoint {
                    configuration.provider = .ollama
                } else {
                    configuration.provider = .lmStudio
                }
                Task {
                    await fetchAvailableModels()
                }
            } else {
                isConnected = false
                connectionStatus = .disconnected
            }
        }
    }

    func fetchAvailableModels() async {
        let tagsUrl: URL?
        if configuration.provider == .lmStudio {
            tagsUrl = URL(string: "\(configuration.lmStudioEndpoint)/api/v0/models")
        } else {
            tagsUrl = URL(string: "\(configuration.ollamaEndpoint)/api/tags")
        }

        guard let url = tagsUrl else { return }

        do {
            let (data, _) = try await session.data(from: url)
            if configuration.provider == .lmStudio {
                if let modelsResponse = try? JSONDecoder().decode(LMStudioModelsResponse.self, from: data) {
                    await MainActor.run {
                        availableModels = modelsResponse.models.map { $0.name }
                        if availableModels.isEmpty {
                            availableModels = ["llama3", "codellama", "mistral"]
                        }
                    }
                }
            } else {
                if let modelsResponse = try? JSONDecoder().decode(OllamaModelsResponse.self, from: data) {
                    await MainActor.run {
                        availableModels = modelsResponse.models.map { $0.name }
                    }
                }
            }
        } catch {
            await MainActor.run {
                availableModels = ["llama3", "codellama", "mistral"]
            }
        }
    }

    func sendMessage(_ message: AIMessage) async throws -> AIMessage {
        guard isConnected else {
            throw AIError.notConnected
        }

        let endpoint: String
        if configuration.provider == .lmStudio {
            endpoint = "\(configuration.lmStudioEndpoint)/api/v0/chat/completions"
        } else {
            endpoint = "\(configuration.ollamaEndpoint)/api/chat"
        }

        guard let url = URL(string: endpoint) else {
            throw AIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: Any
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        if configuration.provider == .lmStudio {
            body = LMStudioChatRequest(
                model: configuration.selectedModel,
                messages: [ChatMessage(role: message.role.rawValue, content: message.content)],
                temperature: configuration.temperature,
                maxTokens: configuration.maxTokens
            )
        } else {
            body = OllamaChatRequest(
                model: configuration.selectedModel,
                messages: [OllamaMessage(role: message.role.rawValue, content: message.content)],
                stream: false
            )
        }

        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw AIError.serverError
        }

        var responseText: String
        if configuration.provider == .lmStudio {
            let lmResponse = try JSONDecoder().decode(LMStudioChatResponse.self, from: data)
            responseText = lmResponse.choices.first?.message.content ?? ""
        } else {
            let ollamaResponse = try JSONDecoder().decode(OllamaChatResponse.self, from: data)
            responseText = ollamaResponse.message.content
        }

        let codeBlocks = responseText.extractCodeBlocks()

        return AIMessage(
            role: .assistant,
            content: responseText,
            codeBlocks: codeBlocks
        )
    }

    func getSavedSessions() -> [AIChatSession] {
        return []
    }

    func saveSession(_ session: AIChatSession) {
    }

    func getSuggestions(for code: String, cursorPosition: Int) async throws -> [AISuggestion] {
        guard isConnected else { return [] }

        let prompt = """
        Analyze this Swift code and provide suggestions for improvements, error fixes, or completions.
        Return suggestions as a JSON array with objects containing: "type" (completion|errorFix|refactor|explanation), "content", "line" (optional), "confidence" (0.0-1.0).

        Code:
        \(code)
        """

        let message = AIMessage(role: .user, content: prompt)
        let response = try await sendMessage(message)

        return parseSuggestions(from: response.content)
    }

    private func parseSuggestions(from json: String) -> [AISuggestion] {
        guard let data = json.data(using: .utf8) else { return [] }

        struct SuggestionJSON: Codable {
            let type: String
            let content: String
            let line: Int?
            let confidence: Double
        }

        guard let suggestions = try? JSONDecoder().decode([SuggestionJSON].self, from: data) else {
            return []
        }

        return suggestions.compactMap { s -> AISuggestion? in
            guard let suggestionType = AISuggestion.SuggestionType(rawValue: s.type) else { return nil }
            return AISuggestion(
                id: UUID().uuidString,
                type: suggestionType,
                content: s.content,
                line: s.line,
                confidence: s.confidence
            )
        }
    }
}

enum AIError: LocalizedError {
    case notConnected
    case invalidURL
    case serverError
    case decodingError

    var errorDescription: String? {
        switch self {
        case .notConnected: return "Not connected to AI service"
        case .invalidURL: return "Invalid AI service URL"
        case .serverError: return "AI service returned an error"
        case .decodingError: return "Failed to parse AI response"
        }
    }
}

struct OllamaModelsResponse: Codable {
    let models: [OllamaModel]
}

struct OllamaModel: Codable {
    let name: String
}

struct OllamaChatRequest: Codable {
    let model: String
    let messages: [OllamaMessage]
    let stream: Bool
}

struct OllamaMessage: Codable {
    let role: String
    let content: String
}

struct OllamaChatResponse: Codable {
    let message: OllamaMessage
}

struct LMStudioModelsResponse: Codable {
    let models: [LMStudioModel]
}

struct LMStudioModel: Codable {
    let name: String
}

struct LMStudioChatRequest: Codable {
    let model: String
    let messages: [ChatMessage]
    let temperature: Double
    let maxTokens: Int
}

struct ChatMessage: Codable {
    let role: String
    let content: String
}

struct LMStudioChatResponse: Codable {
    let choices: [LMStudioChoice]
}

struct LMStudioChoice: Codable {
    let message: ChatMessage
}
