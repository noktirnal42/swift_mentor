import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var columnVisibility: NavigationSplitViewVisibility = .all

    var body: some View {
        ZStack {
            GlassBackground(material: .content)

            NavigationSplitView(columnVisibility: $columnVisibility) {
                SidebarView()
            } detail: {
                detailView
            }
            .navigationSplitViewStyle(.balanced)
            .sheet(isPresented: $appState.showingSearch) {
                SearchView()
            }
            .sheet(isPresented: $appState.showAIAssistant) {
                AIChatPanel()
                    .frame(minWidth: 400, idealWidth: 500, maxWidth: 600)
            }
        }
    }

    @ViewBuilder
    private var detailView: some View {
        switch appState.selectedSection {
        case .dashboard:
            DashboardView()
        case .learningPaths:
            LearningPathsView()
        case .playground, .playgroundDetail:
            CodePlaygroundView()
        case .progress:
            ProgressView_()
        case .snippets:
            SnippetLibraryView()
        case .settings:
            SettingsView()
        case .aiAssistant:
            AIChatPanel()
        case .help:
            OnboardingView()
        case .debug:
            SettingsView()
        }
    }
}

// MARK: - Search View

struct SearchView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @State private var searchText = ""
    @State private var searchResults: [SearchResultItem] = []
    @State private var isSearching = false
    @State private var recentSearches: [String] = []
    @State private var suggestions: [String] = []

    private let contentService = ContentService.shared

    var body: some View {
        VStack(spacing: 0) {
            // Search bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.accentColor)
                    .font(.title3)

                TextField("Search lessons, topics, code...", text: $searchText)
                    .textFieldStyle(.plain)
                    .font(.title3)
                    .onSubmit { performSearch() }
                    .onChange(of: searchText) { _, newValue in
                        updateSuggestions(query: newValue)
                    }

                if !searchText.isEmpty {
                    Button(action: { searchText = ""; searchResults = []; suggestions = [] }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(.ultraThinMaterial)

            Divider()

            // Content
            if isSearching {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !searchResults.isEmpty {
                resultsList
            } else if searchText.isEmpty {
                suggestionsAndRecent
            } else {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "magnifyingglass",
                    description: Text("No lessons found for \"\(searchText)\"")
                )
            }
        }
        .frame(width: 650, height: 450)
        .background(.ultraThinMaterial)
        .onAppear {
            loadRecentSearches()
        }
    }

    // MARK: - Results List

    private var resultsList: some View {
        List(searchResults) { result in
            EnhancedSearchResultRow(result: result)
                .onTapGesture { openLesson(result.lesson) }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
    }

    // MARK: - Suggestions & Recent

    private var suggestionsAndRecent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                // Quick suggestions
                if !suggestions.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        Text("Suggestions")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)

                        ForEach(suggestions, id: \.self) { suggestion in
                            Button(action: { searchText = suggestion; performSearch() }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "magnifyingglass")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(suggestion)
                                        .font(.body)
                                    Spacer()
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 6)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Recent searches
                if !recentSearches.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                        HStack {
                            Text("Recent Searches")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            Spacer()
                            Button("Clear All") {
                                recentSearches = []
                                UserDefaults.standard.removeObject(forKey: "recentSearches")
                            }
                            .font(.caption)
                            .foregroundColor(.red)
                        }
                        .padding(.horizontal)

                        ForEach(recentSearches, id: \.self) { query in
                            Button(action: { searchText = query; performSearch() }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(query)
                                        .font(.body)
                                    Spacer()
                                    Image(systemName: "arrow.up.left")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 6)
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }

                // Quick topic filters
                VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                    Text("Browse Topics")
                        .font(.headline)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.Spacing.sm) {
                            ForEach(SearchTopic.allCases) { topic in
                                Button(action: { searchText = topic.query; performSearch() }) {
                                    Label(topic.name, systemImage: topic.icon)
                                        .font(.caption)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(Color.accentColor.opacity(0.1))
                                        )
                                        .foregroundColor(.accentColor)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
    }

    // MARK: - Search Logic

    private func performSearch() {
        guard !searchText.isEmpty else { searchResults = []; return }
        isSearching = true

        // Save to recent searches
        saveRecentSearch(searchText)

        Task {
            do {
                let lessons = try await contentService.searchLessons(query: searchText)
                searchResults = lessons.map { lesson in
                    SearchResultItem(lesson: lesson, matchReason: determineMatchReason(lesson: lesson, query: searchText))
                }
            } catch {
                searchResults = []
            }
            isSearching = false
        }
    }

    private func updateSuggestions(query: String) {
        guard !query.isEmpty else { suggestions = []; return }
        let topics = ["Swift", "SwiftUI", "Variables", "Functions", "Classes", "Protocols",
                      "Concurrency", "Metal", "CoreML", "Xcode", "SwiftData", "WidgetKit"]
        suggestions = topics.filter { $0.lowercased().hasPrefix(query.lowercased()) }.prefix(5).map { $0 }
    }

    private func determineMatchReason(lesson: Lesson, query: String) -> String {
        let lower = query.lowercased()
        if lesson.title.lowercased().contains(lower) { return "Title match" }
        if lesson.description.lowercased().contains(lower) { return "Description match" }
        for section in lesson.sections {
            switch section {
            case .text(let content):
                if content.lowercased().contains(lower) { return "Content match" }
            case .code(_, let title, _, _, _):
                if title.lowercased().contains(lower) { return "Code example match" }
            case .quiz(let quiz):
                if quiz.question.lowercased().contains(lower) { return "Quiz match" }
            default: break
            }
        }
        return "Related"
    }

    private func loadRecentSearches() {
        recentSearches = UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []
    }

    private func saveRecentSearch(_ query: String) {
        var searches = UserDefaults.standard.stringArray(forKey: "recentSearches") ?? []
        searches.removeAll { $0 == query }
        searches.insert(query, at: 0)
        searches = Array(searches.prefix(10))
        UserDefaults.standard.set(searches, forKey: "recentSearches")
        recentSearches = searches
    }

    private func openLesson(_ lesson: Lesson) {
        Task { @MainActor in
            await AppState.shared.loadLessonsForPath(lesson.pathId)
            AppState.shared.navigateToLesson(lesson)
            AppState.shared.selectedSection = .playground
            dismiss()
        }
    }
}

// MARK: - Search Result Model

struct SearchResultItem: Identifiable {
    let id = UUID()
    let lesson: Lesson
    let matchReason: String
}

// MARK: - Search Topic

enum SearchTopic: String, CaseIterable, Identifiable {
    case swift = "Swift"
    case swiftui = "SwiftUI"
    case variables = "Variables"
    case functions = "Functions"
    case concurrency = "Concurrency"
    case metal = "Metal"

    var id: String { rawValue }

    var name: String { rawValue }

    var icon: String {
        switch self {
        case .swift: return "swift"
        case .swiftui: return "paintbrush"
        case .variables: return "variable"
        case .functions: return "function"
        case .concurrency: return "arrow.triangle.branch"
        case .metal: return "gpu"
        }
    }

    var query: String { rawValue.lowercased() }
}

// MARK: - Enhanced Search Result Row

struct EnhancedSearchResultRow: View {
    let result: SearchResultItem
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: result.lesson.icon)
                .foregroundColor(.accentColor)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(result.lesson.title)
                    .font(.headline)
                Text(result.lesson.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                DifficultyBadge(difficulty: result.lesson.difficulty)
                Text(result.matchReason)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.secondary.opacity(0.1)))
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor.opacity(isHovered ? 0.1 : 0))
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) { isHovered = hovering }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState.shared)
}
