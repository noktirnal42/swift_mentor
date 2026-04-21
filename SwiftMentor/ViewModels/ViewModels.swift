import SwiftUI
import Foundation
import Combine
import AppKit
import os.log

let playgroundLog = Logger(subsystem: "com.swiftmentor.macos", category: "Playground")

// MARK: - AppState (Singleton ObservableObject for app-wide state)

final class AppState: ObservableObject {
    static let shared = AppState()
    
    // Navigation state
    @Published var selectedSection: Section = .dashboard
    @Published var showingSearch: Bool = false
    @Published var showAIAssistant: Bool = false
    @Published var showSidebar: Bool = true
    
    // Learning paths state
    @Published var learningPaths: [LearningPath] = []
    @Published var selectedPath: LearningPath?
    @Published var currentLesson: Lesson?
    
    // User progress
    @Published var userProgress = UserProgress()
    
    // Selection state for UI
    @Published var selectedPathId: String?
    @Published var selectedLessonId: String?
    
    enum Section: String, CaseIterable, Identifiable {
        case dashboard = "Dashboard"
        case learningPaths = "Learning Paths"
        case playground = "Playground"
        case snippets = "Snippets"
        case playgroundDetail = "PlaygroundDetail"
        case progress = "Progress"
        case aiAssistant = "AI Assistant"
        case settings = "Settings"
        case help = "Help"
        case debug = "Debug"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .dashboard: return "house.fill"
            case .learningPaths: return "road.lane.fill"
            case .playground: return "terminal.fill"
            case .snippets: return "doc.text.fill"
            case .playgroundDetail: return "terminal.fill"
            case .progress: return "chart.line.uptrend.xyaxis"
            case .aiAssistant: return "brain.head.profile"
            case .settings: return "gearshape.fill"
            case .help: return "questionmark.circle.fill"
            case .debug: return "ant.fill"
            }
        }
    }
    
    // Computed overall progress
    var overallProgress: Double {
        let completed = ProgressService.shared.getCompletedLessonsCount()
        let total = ProgressService.shared.getTotalLessonsCount()
        return total > 0 ? Double(completed) / Double(total) : 0
    }
    
    var completedLessonsCount: Int {
        ProgressService.shared.getCompletedLessonsCount()
    }
    
    var streakDays: Int {
        userProgress.streakDays
    }
    
    var totalLessonsCount: Int {
        learningPaths.reduce(0) { $0 + $1.lessonCount }
    }
    
    func navigateToLesson(_ lesson: Lesson) {
        currentLesson = lesson
        selectedLessonId = lesson.id
    }
    
    func selectLearningPath(_ path: LearningPath) {
        selectedPath = path
        selectedPathId = path.id
    }
    
    func loadLearningPaths() async {
        do {
            learningPaths = try await ContentService.shared.loadLearningPaths()
        } catch {
            print("Failed to load learning paths: \(error)")
        }
    }
    
    func loadLessonsForPath(_ pathId: String) async {
        do {
            _ = try await ContentService.shared.loadAllLessonsForPath(pathId)
            // Lessons are now stored in ContentService, not in LearningPath struct
        } catch {
            print("Failed to load lessons for path: \(error)")
        }
    }
}

// MARK: - Dashboard ViewModel

@MainActor
final class DashboardViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    @Published var totalLessonsCount: Int = 0
    @Published var completedLessonsCount: Int = 0
    @Published var totalTimeSpent: TimeInterval = 0
    @Published var overallProgress: Double = 0.0
    @Published var currentStreak: Int = 0
    @Published var recentLessons: [Lesson] = []
    @Published var learningPaths: [LearningPath] = []
    
    var progressPercentage: Double {
        totalLessonsCount > 0 ? Double(completedLessonsCount) / Double(totalLessonsCount) : 0
    }
    
    var streakDays: Int {
        currentStreak
    }
    
    func loadData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Load learning paths
            learningPaths = try await ContentService.shared.loadLearningPaths()
            
            // Load recent lessons
            recentLessons = try await ContentService.shared.getRecentLessons(limit: 5)
            
            // Load progress stats
            totalLessonsCount = ProgressService.shared.getTotalLessonsCount()
            completedLessonsCount = ProgressService.shared.getCompletedLessonsCount()
            overallProgress = ProgressService.shared.getProgressPercentage()
            totalTimeSpent = ProgressService.shared.loadProgress().totalTimeSpent
            
            // Load streak
            currentStreak = ProgressService.shared.loadProgress().streakDays
            
        } catch {
            errorMessage = "Failed to load data: \(error.localizedDescription)"
            print("Dashboard load error: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - Learning Path ViewModel

@MainActor
final class LearningPathViewModel: ObservableObject {
    @Published var paths: [LearningPath] = []
    @Published var selectedPath: LearningPath?
    @Published var lessonsForPath: [Lesson] = []
    @Published var isLoading: Bool = true
    @Published var errorMessage: String?
    @Published var loadingStep: String = "Starting..."
    
    init() {
        Task { await reloadPaths() }
    }
    
    func reloadPaths() async {
        isLoading = true
        loadingStep = "Loading..."
        errorMessage = nil
        
        // Use synchronous preload for immediate data
        paths = ContentService.shared.loadLearningPathsSync()
        print("✅ Loaded \(paths.count) paths")
        loadingStep = "\(paths.count) paths"
        
        if let first = paths.first {
            selectedPath = first
        }
        isLoading = false
    }
    
    func selectPath(_ path: LearningPath) async {
        selectedPath = path
        isLoading = true
        loadingStep = "Loading lessons for \(path.title)..."
        do {
            lessonsForPath = try await ContentService.shared.loadAllLessonsForPath(path.id)
            loadingStep = "Loaded \(lessonsForPath.count) lessons"
        } catch {
            errorMessage = "Failed to load lessons: \(error.localizedDescription)"
            loadingStep = "Error loading lessons"
        }
        isLoading = false
    }
}

// MARK: - Playground ViewModel

@MainActor
final class PlaygroundViewModel: ObservableObject {
    @Published var code: String = ""
    @Published var output: String = ""
    @Published var errors: [CodeExecutionService.ExecutionError] = []
    @Published var isExecuting: Bool = false
    @Published var executionTime: TimeInterval = 0
    @Published var cursorPosition: Int = 0
    @Published var showAutocomplete: Bool = false
    @Published var autocompleteCompletions: [AutocompleteCompletion] = []
    @Published var showPreview: Bool = true
    @Published var previewImage: NSImage?  = nil
    @Published var currentSnippet: CodeSnippet?
    @Published var statusText: String = "Ready"
    #if DEBUG
    @Published var debugLog: String = "Debug log started.\n"
    #endif

    // Starter codes for different lesson types
    private var starterCodes: [String: String] = [:]

    init() {
        Task { await loadStarterCodes() }
    }

    private func loadStarterCodes() async {
        // Load starter codes from snippets
        await AutocompleteService.shared.loadSnippets()
        let snippets = AutocompleteService.shared.getSnippets()
        for snippet in snippets {
            starterCodes[snippet.topic] = snippet.code
        }
    }

    func executeCode() async {
        guard !code.isEmpty else {
            output = "No code to execute."
            return
        }

        isExecuting = true
        statusText = "Executing..."
        errors = []
        output = ""

        #if DEBUG
        let logMsg = "▶️ [PlaygroundVM] executeCode() called with \(code.count) chars"
        debugLog += logMsg + "\n"
        writeDebugToFile(logMsg)
        #endif

        let result = await CodeExecutionService.shared.execute(code: code)

        #if DEBUG
        let resultMsg = "▶️ [PlaygroundVM] Result: success=\(result.success), output=\(result.output.prefix(200)), errors=\(result.errors.count), time=\(result.executionTime)s"
        debugLog += resultMsg + "\n"
        writeDebugToFile(resultMsg)
        #endif

        executionTime = result.executionTime
        output = result.output
        errors = result.errors
        statusText = result.success ? "Completed in \(String(format: "%.2f", executionTime))s" : "Failed"

        // If there's no output and no errors, show something so the user knows it ran
        if output.isEmpty && errors.isEmpty && result.success {
            output = "✅ Code executed successfully with no output."
        }

        // If execution failed with no errors, add a visible message
        if !result.success && errors.isEmpty {
            output = "❌ Execution failed.\n\(output)"
        }

        isExecuting = false
    }
    
    /// Direct test: bypasses CodeExecutionService entirely to verify UI updates work
    #if DEBUG
    func testOutput() {
        output = "🧪 TEST OUTPUT: If you see this, the UI is working correctly!\nTimestamp: \(Date())\nCode length was: \(code.count) chars"
        statusText = "Test OK"
        debugLog += "🧪 testOutput() called directly — UI update should be visible\n"
        writeDebugToFile("🧪 testOutput() called")
    }

    private func writeDebugToFile(_ message: String) {
        let logPath = "/tmp/SwiftMentor_debug.log"
        let timestamped = "\(Date()): \(message)\n"
        if let data = timestamped.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logPath) {
                if let fileHandle = try? FileHandle(forWritingTo: URL(fileURLWithPath: logPath)) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: URL(fileURLWithPath: logPath))
            }
        }
    }
    #endif

    func resetCode() {
        code = ""
        output = ""
        errors = []
        statusText = "Ready"
        showAutocomplete = false
    }
    
    func loadSnippet(_ snippet: CodeSnippet) {
        code = snippet.code
        currentSnippet = snippet
        statusText = "Loaded: \(snippet.title)"
    }
    
    func setCode(_ newCode: String) {
        code = newCode
    }
    
    func selectAutocomplete(_ completion: AutocompleteCompletion) {
        // Insert completion text at cursor position
        let prefix = String(code.prefix(cursorPosition))
        let suffix = String(code.suffix(code.count - cursorPosition))
        code = prefix + completion.text + suffix
        cursorPosition += completion.text.count
        showAutocomplete = false
    }
    
    func updateAutocompleteCompletions(_ completions: [AutocompleteCompletion]) {
        autocompleteCompletions = completions
        showAutocomplete = !completions.isEmpty
    }
    
    func getStarterCode(for topic: String) -> String {
        starterCodes[topic] ?? getDefaultStarterCode(for: topic)
    }
    
    private func getDefaultStarterCode(for topic: String) -> String {
        switch topic.lowercased() {
        case "swiftui":
            return """
            import SwiftUI

            struct ContentView: View {
                var body: some View {
                    Text("Hello, SwiftUI!")
                        .padding()
                }
            }
            """
        case "uikit":
            return """
            import UIKit

            class ViewController: UIViewController {
                override func viewDidLoad() {
                    super.viewDidLoad()
                    view.backgroundColor = .systemBlue
                }
            }
            """
        case "metal":
            return """
            #include <metal_stdlib>
            using namespace metal;

            struct VertexOut {
                float4 position [[position]];
                float3 color;
            };

            vertex VertexOut vertexShader(uint vertexID [[vertex_id]]) {
                // Metal shader placeholder
                return VertexOut();
            }

            fragment float4 fragmentShader(VertexOut in [[stage_in]]) {
                return float4(1.0, 0.0, 0.0, 1.0);
            }
            """
        case "coreml":
            return """
            // CoreML model placeholder
            // Add your CoreML model code here
            """
        default:
            return "// Start coding here\nprint(\"Hello, Swift!\")"
        }
    }
}

// MARK: - Snippet Library ViewModel

@MainActor
final class SnippetLibraryViewModel: ObservableObject {
    @Published var allSnippets: [CodeSnippet] = []
    @Published var filteredSnippets: [CodeSnippet] = []
    @Published var selectedSnippet: CodeSnippet?
    @Published var searchText: String = ""
    @Published var selectedCategory: String? = nil
    @Published var isLoading: Bool = false
    
    var categories: [String] {
        Array(Set(allSnippets.map { $0.topic })).sorted()
    }
    
    var filteredByCategory: [CodeSnippet] {
        if let category = selectedCategory {
            return allSnippets.filter { $0.topic == category }
        }
        return allSnippets
    }
    
    init() {
        Task { await loadSnippets() }
    }
    
    func loadSnippets() async {
        isLoading = true
        await AutocompleteService.shared.loadSnippets()
        allSnippets = AutocompleteService.shared.getSnippets()
        filteredSnippets = allSnippets
        isLoading = false
    }
    
    func searchSnippets(_ query: String) {
        searchText = query
        if query.isEmpty {
            filteredSnippets = filteredByCategory
        } else {
            filteredSnippets = filteredByCategory.filter {
                $0.title.localizedCaseInsensitiveContains(query) ||
                $0.code.localizedCaseInsensitiveContains(query) ||
                $0.topic.localizedCaseInsensitiveContains(query)
            }
        }
    }
    
    func selectCategory(_ category: String?) {
        selectedCategory = category
        filteredSnippets = filteredByCategory
        if !searchText.isEmpty {
            searchSnippets(searchText)
        }
    }
    
    func selectSnippet(_ snippet: CodeSnippet) {
        selectedSnippet = snippet
    }
}

// MARK: - Settings ViewModel

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published var settings: AppSettings
    @Published var aiConfiguration: AIConfiguration
    @Published var isTestingConnection: Bool = false
    @Published var connectionTestResult: String? = nil
    @Published var availableModels: [String] = []
    
    private let userDefaultsKey = "appSettings"
    
    var appearanceModes: [AppSettings.AppearanceMode] {
        AppSettings.AppearanceMode.allCases
    }
    
    init() {
        settings = AppSettings()
        aiConfiguration = AIConfiguration()
        loadSettings()
    }
    
    func loadSettings() {
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey),
           let saved = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = saved
        }
        aiConfiguration = AIService.shared.getConfiguration()
    }
    
    func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
        }
        AIService.shared.saveConfiguration(aiConfiguration)
    }
    
    func resetToDefaults() {
        settings = AppSettings()
        saveSettings()
    }
    
    func saveAIConfiguration() {
        AIService.shared.saveConfiguration(aiConfiguration)
    }
    
    func testAIConnection() async {
        isTestingConnection = true
        connectionTestResult = "Testing..."
        
        await AIService.shared.checkConnection()
        
        // Give it a moment to complete
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        
        let config = AIService.shared.getConfiguration()
        if config.isConnected {
            connectionTestResult = "✅ Connected!"
        } else {
            connectionTestResult = "⚠️ Check configuration"
        }
        
        isTestingConnection = false
    }
    
    func loadAvailableModels() async {
        let config = AIService.shared.getConfiguration()
        availableModels = config.availableModels
    }
}

// MARK: - AI Assistant ViewModel

@MainActor
final class AIAssistantViewModel: ObservableObject {
    @Published var isLoading: Bool = false
    @Published var isConnected: Bool = false
    @Published var messages: [AIMessage] = []
    @Published var inputText: String = ""
    @Published var availableModels: [String] = []
    @Published var selectedSession: AIChatSession? = nil
    @Published var sessions: [AIChatSession] = []
    
    var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isLoading
    }
    
    init() {
        loadSessions()
    }
    
    func loadSessions() {
        sessions = AIService.shared.getSavedSessions()
    }
    
    func sendMessage() async {
        guard canSend else { return }
        
        let userMessage = AIMessage(
            role: .user,
            content: inputText
        )
        messages.append(userMessage)
        
        isLoading = true
        _ = inputText
        inputText = ""
        
        do {
            let response = try await AIService.shared.sendMessage(userMessage)
            messages.append(response)
        } catch {
            let errorMsg = AIMessage(
                role: .assistant,
                content: "Error: \(error.localizedDescription)"
            )
            messages.append(errorMsg)
        }
        
        isLoading = false
    }
    
    func clearChat() {
        messages.removeAll()
    }
    
    func selectSuggestion(_ suggestion: String) {
        inputText = suggestion
    }
}

// MARK: - Progress ViewModel

@MainActor
final class ProgressViewModel: ObservableObject {
    @Published var userProgress: UserProgress = UserProgress()
    @Published var completedLessons: [Lesson] = []
    @Published var bookmarkedLessons: [Lesson] = []
    @Published var quizScores: [String: Int] = [:]
    @Published var overallProgress: Double = 0.0
    
    @Published var isLoading: Bool = false
    
    var streakDays: Int {
        userProgress.streakDays
    }
    
    var totalTimeSpentFormatted: String {
        let hours = Int(userProgress.totalTimeSpent / 3600)
        let minutes = Int((userProgress.totalTimeSpent.truncatingRemainder(dividingBy: 3600)) / 60)
        return "\(hours)h \(minutes)m"
    }
    
    func loadProgress() {
        isLoading = true
        
        userProgress = ProgressService.shared.loadProgress()
        overallProgress = ProgressService.shared.getProgressPercentage()
        
        // Load completed lessons
        _ = userProgress.lessonProgress.keys
        // Filter from learning paths
        
        isLoading = false
    }
    
    func markLessonComplete(lessonId: String, pathId: String = "", timeSpent: Int = 0) {
        ProgressService.shared.markLessonCompleted(lessonId: lessonId, pathId: pathId, timeSpent: timeSpent)
        loadProgress()
    }
    
    func toggleBookmark(lessonId: String) {
        if ProgressService.shared.isBookmarked(lessonId: lessonId) {
            ProgressService.shared.removeBookmark(lessonId: lessonId)
        } else {
            ProgressService.shared.addBookmark(lessonId: lessonId)
        }
    }
}
