import SwiftUI

struct CodePlaygroundView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = PlaygroundViewModel()
    @State private var showSnippetLibrary = false
    @State private var showLessonContent = false
    @State private var executionHistory: [ExecutionRecord] = []
    #if DEBUG
    @State private var showDebugLog = false
    #endif

    private var lesson: Lesson? { appState.currentLesson }

    var body: some View {
        HSplitView {
            lessonContentPanel
                .frame(minWidth: 250, idealWidth: 350, maxWidth: 500)

            editorPanel
                .frame(minWidth: 400)
        }
        .navigationTitle(lesson?.title ?? "Playground")
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                if lesson != nil {
                    Button(action: { showLessonContent = true }) {
                        Image(systemName: "book")
                    }
                    .help("Show Lesson Content")
                }

                Button(action: { showSnippetLibrary = true }) {
                    Image(systemName: "doc.text")
                }
                .help("Snippet Library")

                Divider()

                Button(action: { Task { await executeAndRecord() } }) {
                    Label("Run", systemImage: "play.fill")
                }
                .disabled(viewModel.isExecuting)
                .keyboardShortcut("R", modifiers: .command)

                Button(action: { viewModel.resetCode() }) {
                    Image(systemName: "arrow.counterclockwise")
                }
                .help("Reset Code")

                #if DEBUG
                Button(action: { viewModel.testOutput() }) {
                    Label("Test UI", systemImage: "flask")
                }
                .help("Test if UI output works (bypasses code execution)")

                Button(action: { showDebugLog.toggle() }) {
                    Image(systemName: "ladybug")
                }
                .help("Toggle Debug Log")
                .foregroundColor(showDebugLog ? .yellow : nil)
                #endif
            }
        }
        .sheet(isPresented: $showSnippetLibrary) {
            SnippetPickerView { snippet in
                viewModel.loadSnippet(snippet)
                showSnippetLibrary = false
            }
        }
        .sheet(isPresented: $showLessonContent) {
            if let lesson = lesson {
                LessonContentSheet(lesson: lesson)
            }
        }
        .task(id: appState.currentLesson?.id) {
            if let lesson = lesson {
                loadLessonCode(lesson)
            }
        }
    }

    // MARK: - Lesson Content Panel

    private var lessonContentPanel: some View {
        ScrollView {
            if let lesson = lesson {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    // Lesson title with gradient
                    GradientText(lesson.title, font: .title2.bold(), gradient: Theme.pathGradient(for: lesson.difficulty.color == "green" ? "34C759" : lesson.difficulty.color == "orange" ? "FF9500" : "FF3B30"))

                    Text(lesson.description)
                        .foregroundColor(.secondary)

                    Divider()

                    ForEach(Array(lesson.sections.enumerated()), id: \.offset) { index, section in
                        sectionView(section, index: index)
                    }
                }
                .padding()
            } else {
                ContentUnavailableView(
                    "No Lesson Selected",
                    systemImage: "book",
                    description: Text("Select a lesson from a learning path or start writing code")
                )
            }
        }
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private func sectionView(_ section: LessonSection, index: Int) -> some View {
        switch section {
        case .text(let content):
            Text(content)
                .font(.body)
                .fadeIn(delay: Double(index) * 0.05)
        case .code(_, let title, let starterCode, _, _):
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text(title)
                    .font(.headline)
                CodeBlockView(code: starterCode, language: "swift")
                    .onTapGesture { viewModel.setCode(starterCode) }
            }
        case .interactive(let title, let instructions, let starterCode, _):
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                Text(title)
                    .font(.headline)
                Text(instructions)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Button("Try This") { viewModel.setCode(starterCode) }
                    .buttonStyle(.borderedProminent)
            }
        case .quiz(let quiz):
            QuizView(quiz: quiz)
        case .image(let url, _):
            AsyncImage(url: URL(string: url)) { image in
                image.resizable().aspectRatio(contentMode: .fit)
            } placeholder: {
                Rectangle().fill(Color.gray.opacity(0.2))
            }
            .frame(maxHeight: 200)
        }
    }

    // MARK: - Editor Panel

    private var editorPanel: some View {
        VSplitView {
            // Code editor area
            VStack(spacing: 0) {
                // Quick-insert snippet bar
                snippetBar

                CodeEditorView(
                    code: $viewModel.code,
                    cursorPosition: $viewModel.cursorPosition,
                    showAutocomplete: viewModel.showAutocomplete,
                    completions: viewModel.autocompleteCompletions,
                    onCompletionSelect: { completion in
                        viewModel.selectAutocomplete(completion)
                    },
                    onRunCode: {
                        Task { await executeAndRecord() }
                    }
                )
            }
            .frame(minHeight: 200)

            // Output panel
            outputPanel
                .frame(minHeight: 150, idealHeight: 200)
        }
    }

    // MARK: - Snippet Bar

    private var snippetBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                SnippetBarButton(title: "print()", icon: "text.insert") {
                    viewModel.setCode(viewModel.code + "\nprint()")
                }
                SnippetBarButton(title: "func", icon: "f.cursive") {
                    viewModel.setCode(viewModel.code + "\nfunc myFunc() {\n    \n}")
                }
                SnippetBarButton(title: "var", icon: "v.square") {
                    viewModel.setCode(viewModel.code + "\nvar myVar = ")
                }
                SnippetBarButton(title: "for", icon: "repeat") {
                    viewModel.setCode(viewModel.code + "\nfor item in items {\n    \n}")
                }
                SnippetBarButton(title: "if", icon: "arrow.branch") {
                    viewModel.setCode(viewModel.code + "\nif condition {\n    \n}")
                }
                SnippetBarButton(title: "guard", icon: "shield") {
                    viewModel.setCode(viewModel.code + "\nguard let value = optional else { return }")
                }
                SnippetBarButton(title: "struct", icon: "square.stack.3d.up") {
                    viewModel.setCode(viewModel.code + "\nstruct MyStruct {\n    \n}")
                }
                SnippetBarButton(title: "class", icon: "rectangle.stack") {
                    viewModel.setCode(viewModel.code + "\nclass MyClass {\n    \n}")
                }

                Divider()
                    .frame(height: 20)

                SnippetBarButton(title: "More...", icon: "ellipsis") {
                    showSnippetLibrary = true
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .background(.ultraThinMaterial)
    }

    // MARK: - Output Panel

    private var outputPanel: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Output")
                    .font(.headline)
                Spacer()

                // Execution time badge
                if viewModel.executionTime > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.caption2)
                        Text(String(format: "%.2fs", viewModel.executionTime))
                            .font(.caption2)
                            .monospacedDigit()
                    }
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
                }

                Text(viewModel.statusText)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if !viewModel.output.isEmpty {
                    Button(action: { viewModel.output = "" }) {
                        Image(systemName: "trash")
                    }
                    .buttonStyle(.plain)
                    .help("Clear Output")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    if viewModel.isExecuting {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.8)
                            Text("Running...")
                                .foregroundColor(.secondary)
                        }
                    }

                    if !viewModel.errors.isEmpty {
                        ForEach(viewModel.errors) { error in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.red)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Line \(error.line ?? 0): \(error.message)")
                                        .font(.system(.caption, design: .monospaced))
                                    if let column = error.column {
                                        Text("Column \(column)")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                    }

                    if !viewModel.output.isEmpty {
                        Text(viewModel.output)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                    }

                    // Execution history
                    if !executionHistory.isEmpty {
                        Divider()
                        executionHistorySection
                    }

                    #if DEBUG
                    if showDebugLog {
                        Divider()
                        HStack {
                            Text("Debug Log")
                                .font(.caption)
                                .foregroundColor(.yellow)
                            Spacer()
                            Button("Clear") { viewModel.debugLog = "" }
                                .font(.caption2)
                                .buttonStyle(.plain)
                        }
                        ScrollView {
                            Text(viewModel.debugLog)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.yellow)
                                .textSelection(.enabled)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .frame(maxHeight: 120)
                    }
                    #endif
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
            }
            .background(Color(nsColor: .textBackgroundColor))
        }
    }

    // MARK: - Execution History

    private var executionHistorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("History")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }

            ForEach(executionHistory.prefix(5)) { record in
                HStack(spacing: 8) {
                    Image(systemName: record.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(record.success ? .green : .red)
                        .font(.caption)

                    Text(String(format: "%.2fs", record.executionTime))
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.secondary)

                    Text(record.timestamp, style: .time)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("Replay") {
                        viewModel.setCode(record.code)
                    }
                    .font(.caption2)
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                }
            }
        }
    }

    // MARK: - Helpers

    private func loadLessonCode(_ lesson: Lesson) {
        for section in lesson.sections {
            if case .code(_, _, let starterCode, _, _) = section {
                viewModel.setCode(starterCode)
                break
            }
            if case .interactive(_, _, let starterCode, _) = section {
                viewModel.setCode(starterCode)
                break
            }
        }
    }

    private func executeAndRecord() async {
        let code = viewModel.code
        await viewModel.executeCode()

        let record = ExecutionRecord(
            code: code,
            output: viewModel.output,
            success: viewModel.errors.isEmpty && !viewModel.output.contains("❌"),
            executionTime: viewModel.executionTime,
            timestamp: Date()
        )
        executionHistory.insert(record, at: 0)
        if executionHistory.count > 20 {
            executionHistory = Array(executionHistory.prefix(20))
        }
    }
}

// MARK: - Execution Record

struct ExecutionRecord: Identifiable {
    let id = UUID()
    let code: String
    let output: String
    let success: Bool
    let executionTime: TimeInterval
    let timestamp: Date
}

// MARK: - Snippet Bar Button

struct SnippetBarButton: View {
    let title: String
    let icon: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 10))
                Text(title)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(isHovered ? Color.accentColor.opacity(0.15) : Color.primary.opacity(0.05))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(Color.primary.opacity(isHovered ? 0.2 : 0.08), lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Lesson Content Sheet

struct LessonContentSheet: View {
    let lesson: Lesson
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                GradientText(lesson.title, font: .title2.bold())
                Spacer()
                Button("Done") { dismiss() }
            }
            .padding()

            Divider()

            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(lesson.description)
                        .foregroundColor(.secondary)

                    ForEach(Array(lesson.sections.enumerated()), id: \.offset) { _, section in
                        sectionContent(section)
                    }
                }
                .padding()
            }
        }
        .frame(width: 600, height: 500)
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private func sectionContent(_ section: LessonSection) -> some View {
        switch section {
        case .text(let content):
            Text(content)
        case .code(_, let title, let starterCode, _, _):
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(.headline)
                CodeBlockView(code: starterCode, language: "swift")
            }
        case .interactive(let title, let instructions, let starterCode, _):
            VStack(alignment: .leading, spacing: 8) {
                Text(title).font(.headline)
                Text(instructions).foregroundColor(.secondary)
                CodeBlockView(code: starterCode, language: "swift")
            }
        case .quiz(let quiz):
            QuizView(quiz: quiz)
        case .image(let url, _):
            AsyncImage(url: URL(string: url)) { image in
                image.resizable()
            } placeholder: {
                Rectangle().fill(Color.gray.opacity(0.2))
            }
            .frame(maxHeight: 200)
        }
    }
}

// MARK: - Snippet Picker View

struct SnippetPickerView: View {
    let onSelect: (CodeSnippet) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @StateObject private var viewModel = SnippetLibraryViewModel()

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.secondary)
                TextField("Search snippets...", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()

            Divider()

            List(viewModel.filteredSnippets) { snippet in
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(snippet.title)
                                .font(.headline)
                            Text(snippet.shortcut)
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor.opacity(0.15))
                                .cornerRadius(4)
                        }
                        Text(snippet.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button("Insert") { onSelect(snippet) }
                        .buttonStyle(.bordered)
                }
                .padding(.vertical, 4)
                .contentShape(Rectangle())
                .onTapGesture { onSelect(snippet) }
            }
            .listStyle(.inset)
        }
        .frame(width: 500, height: 400)
        .background(.ultraThinMaterial)
        .task { await viewModel.loadSnippets() }
        .onChange(of: searchText) { _, newValue in
            viewModel.searchSnippets(newValue)
        }
    }
}

#Preview {
    CodePlaygroundView()
        .environmentObject(AppState.shared)
}
