import SwiftUI

// MARK: - Lesson Detail View (Enhanced with Bookmarks & Notes)

struct LessonDetailView: View {
    let lesson: Lesson
    @EnvironmentObject private var appState: AppState
    @State private var isBookmarked: Bool = false
    @State private var noteText: String = ""
    @State private var showNotes: Bool = false
    @State private var showBookmarkToast: Bool = false
    @State private var toastMessage: String = ""
    @State private var completedSections: Set<Int> = []

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                // Lesson Header
                lessonHeader
                    .fadeIn()

                // Action Bar (Bookmark + Notes + Open in Playground)
                actionBar
                    .fadeIn(delay: 0.05)

                // Lesson Sections
                ForEach(Array(lesson.sections.enumerated()), id: \.offset) { index, section in
                    sectionView(for: section, index: index)
                        .fadeIn(delay: Double(index) * 0.05)
                }

                // Notes Panel (collapsible)
                if showNotes {
                    notesPanel
                        .fadeIn(delay: 0.1)
                }

                // Bottom spacing
                Spacer(minLength: 60)
            }
            .padding(Theme.Spacing.lg)
        }
        .navigationTitle(lesson.title)
        .onAppear {
            loadBookmarkState()
            loadNoteText()
        }
    }

    // MARK: - Lesson Header

    private var lessonHeader: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: lesson.icon)
                        .font(.system(size: 40))
                        .foregroundStyle(Theme.blueGradient)
                        .frame(width: 64, height: 64)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.blue.opacity(0.1))
                        )

                    VStack(alignment: .leading, spacing: 6) {
                        GradientText(lesson.title, font: .title2.bold())

                        Text(lesson.description)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineLimit(3)

                        HStack(spacing: Theme.Spacing.md) {
                            DifficultyBadge(difficulty: lesson.difficulty)
                            Label("\(lesson.estimatedMinutes) min", systemImage: "clock")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            Label("Lesson \(lesson.order)", systemImage: "number.circle")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Action Bar

    private var actionBar: some View {
        HStack(spacing: Theme.Spacing.md) {
            // Bookmark Button
            Button(action: toggleBookmark) {
                Label(
                    isBookmarked ? "Bookmarked" : "Bookmark",
                    systemImage: isBookmarked ? "bookmark.fill" : "bookmark"
                )
                .foregroundColor(isBookmarked ? .yellow : .secondary)
            }
            .buttonStyle(.bordered)
            .help("Bookmark this lesson")

            // Notes Toggle
            Button(action: { withAnimation { showNotes.toggle() } }) {
                Label(
                    noteText.isEmpty ? "Add Note" : "View Note",
                    systemImage: showNotes ? "note.text" : "note.text.badge.plus"
                )
                .foregroundColor(showNotes ? .blue : .secondary)
            }
            .buttonStyle(.bordered)
            .help("Add a personal note")

            Spacer()

            // Open in Playground
            Button(action: openInPlayground) {
                Label("Open in Playground", systemImage: "play.fill")
                    .font(.body.bold())
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.regular)
        }
    }

    // MARK: - Section Views

    @ViewBuilder
    private func sectionView(for section: LessonSection, index: Int) -> some View {
        switch section {
        case .text(let content):
            textSection(content: content, index: index)
        case .code(let language, let title, let starterCode, let expectedOutput, let solution):
            codeSection(language: language, title: title, starterCode: starterCode, expectedOutput: expectedOutput, solution: solution, index: index)
        case .interactive(let title, let instructions, let starterCode, let validation):
            interactiveSection(title: title, instructions: instructions, starterCode: starterCode, validation: validation, index: index)
        case .quiz(let quiz):
            quizSection(quiz: quiz, index: index)
        case .image(let url, let alt):
            imageSection(url: url, alt: alt, index: index)
        }
    }

    private func textSection(content: String, index: Int) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Image(systemName: "doc.text")
                        .foregroundColor(.blue)
                        .font(.caption)
                    Text("Reading")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    sectionCompleteButton(index: index)
                }

                Text(content)
                    .font(.body)
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func codeSection(language: String, title: String, starterCode: String, expectedOutput: String?, solution: String?, index: Int) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Image(systemName: "chevron.left.forwardslash.chevron.right")
                        .foregroundColor(.green)
                        .font(.caption)
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(language.uppercased())
                        .font(.system(.caption2, design: .monospaced))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.green.opacity(0.15))
                        .cornerRadius(4)
                    Spacer()
                    sectionCompleteButton(index: index)
                }

                // Code block
                CodeBlockView(code: starterCode, language: language)

                if let output = expectedOutput {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: "terminal")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("Expected Output")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Text(output)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.green)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.black.opacity(0.05))
                            .cornerRadius(6)
                    }
                }

                if let solution = solution {
                    DisclosureGroup("Show Solution") {
                        CodeBlockView(code: solution, language: language)
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
    }

    private func interactiveSection(title: String, instructions: String, starterCode: String, validation: Validation, index: Int) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Image(systemName: "wand.and.stars")
                        .foregroundColor(.purple)
                        .font(.caption)
                    Text(title)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    sectionCompleteButton(index: index)
                }

                Text(instructions)
                    .font(.body)
                    .foregroundColor(.secondary)

                CodeBlockView(code: starterCode, language: "swift")

                HStack {
                    Image(systemName: "checkmark.shield")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text("Validation: \(validation.type)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    private func quizSection(quiz: Quiz, index: Int) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.orange)
                        .font(.caption)
                    Text("Quiz")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    sectionCompleteButton(index: index)
                }

                SMQuizView(quiz: quiz)
            }
        }
    }

    private func imageSection(url: String, alt: String, index: Int) -> some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
                HStack {
                    Image(systemName: "photo")
                        .foregroundColor(.cyan)
                        .font(.caption)
                    Text("Figure")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    sectionCompleteButton(index: index)
                }

                // Placeholder for image (URL-based images would need async loading)
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.gray.opacity(0.1))
                    .frame(height: 200)
                    .overlay(
                        VStack(spacing: 8) {
                            Image(systemName: "photo")
                                .font(.title)
                                .foregroundColor(.secondary)
                            Text(alt)
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    )

                Text(alt)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Section Complete Button

    private func sectionCompleteButton(index: Int) -> some View {
        Button(action: { toggleSectionComplete(index) }) {
            Image(systemName: completedSections.contains(index) ? "checkmark.circle.fill" : "circle")
                .foregroundColor(completedSections.contains(index) ? .green : .gray.opacity(0.4))
                .font(.body)
        }
        .buttonStyle(.plain)
        .help("Mark as read")
    }

    // MARK: - Notes Panel

    private var notesPanel: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack {
                    Image(systemName: "note.text")
                        .foregroundColor(.blue)
                    Text("Your Notes")
                        .font(.headline)
                    Spacer()
                    if !noteText.isEmpty {
                        Button("Save") {
                            saveNote()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                }

                TextEditor(text: $noteText)
                    .font(.body)
                    .frame(minHeight: 120, maxHeight: 300)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(nsColor: .textBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )

                if noteText.isEmpty {
                    Text("Write notes to help you remember key concepts from this lesson.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    HStack {
                        Text("\(noteText.count) characters")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Delete Note", role: .destructive) {
                            noteText = ""
                            deleteNote()
                        }
                        .font(.caption)
                        .controlSize(.small)
                    }
                }
            }
        }
    }

    // MARK: - Toast Overlay

    private var toastOverlay: some View {
        Group {
            if showBookmarkToast {
                HStack(spacing: 8) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                    Text(toastMessage)
                }
                .font(.subheadline.bold())
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.2), radius: 8, y: 4)
                )
                .transition(.move(edge: .top).combined(with: .opacity))
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation { showBookmarkToast = false }
                    }
                }
            }
        }
    }

    // MARK: - Actions

    private func toggleBookmark() {
        isBookmarked.toggle()
        let _ = DatabaseManager.shared.toggleBookmark(lessonId: lesson.id)
        toastMessage = isBookmarked ? "Lesson bookmarked" : "Bookmark removed"
        withAnimation { showBookmarkToast = true }
    }

    private func loadBookmarkState() {
        isBookmarked = DatabaseManager.shared.isBookmarked(lessonId: lesson.id)
    }

    private func loadNoteText() {
        noteText = DatabaseManager.shared.getNote(lessonId: lesson.id) ?? ""
    }

    private func saveNote() {
        do {
            try DatabaseManager.shared.saveNote(lessonId: lesson.id, content: noteText)
            toastMessage = "Note saved"
            withAnimation { showBookmarkToast = true }
        } catch {
            print("Error saving note: \(error)")
        }
    }

    private func deleteNote() {
        do {
            try DatabaseManager.shared.saveNote(lessonId: lesson.id, content: "")
            toastMessage = "Note deleted"
            withAnimation { showBookmarkToast = true }
        } catch {
            print("Error deleting note: \(error)")
        }
    }

    private func toggleSectionComplete(_ index: Int) {
        withAnimation {
            if completedSections.contains(index) {
                completedSections.remove(index)
            } else {
                completedSections.insert(index)
            }
        }

        // If all sections are complete, mark the lesson as completed
        if completedSections.count == lesson.sections.count {
            ProgressService.shared.markLessonCompleted(lessonId: lesson.id, pathId: lesson.pathId)
        }
    }

    private func openInPlayground() {
        appState.navigateToLesson(lesson)
        appState.selectedSection = .playground
    }
}

// MARK: - Preview

#Preview("Lesson Detail") {
    LessonDetailView(
        lesson: Lesson(
            id: "swift-fundamentals-1",
            pathId: "swift-fundamentals",
            title: "Variables & Constants",
            description: "Learn the difference between var and let in Swift",
            difficulty: .beginner,
            estimatedMinutes: 15,
            order: 1,
            sections: [
                .text(content: "In Swift, you use `var` to declare a variable and `let` to declare a constant."),
                .code(language: "swift", title: "Variable Example", starterCode: "var greeting = \"Hello\"", expectedOutput: "Hello", solution: nil),
                .quiz(Quiz(question: "Which keyword declares a constant?", options: ["var", "let", "const", "define"], correctIndex: 1, explanation: "let declares a constant in Swift."))
            ],
            xcodeProject: nil
        )
    )
    .environmentObject(AppState.shared)
}
