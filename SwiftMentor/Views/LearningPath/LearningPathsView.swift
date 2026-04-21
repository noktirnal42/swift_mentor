import SwiftUI

struct LearningPathsView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = LearningPathViewModel()
    @State private var selectedPath: LearningPath?
    @State private var currentLesson: Lesson?

    var body: some View {
        NavigationSplitView {
            pathList
        } detail: {
            if let lesson = currentLesson {
                LessonDetailView(lesson: lesson)
            } else if let path = selectedPath {
                PathDetailView(path: path, onSelectLesson: { lesson in
                    currentLesson = lesson
                    appState.currentLesson = lesson
                })
            } else {
                ContentUnavailableView(
                    "Select a Path",
                    systemImage: "book",
                    description: Text("Choose a learning path from the sidebar")
                )
            }
        }
        .navigationSplitViewStyle(.balanced)
        .navigationTitle("Learning Paths")
    }

    private var pathList: some View {
        Group {
            if viewModel.isLoading {
                VStack(spacing: 8) {
                    ProgressView()
                    Text("Loading: \(viewModel.loadingStep)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else if viewModel.paths.isEmpty {
                ContentUnavailableView("No Paths Found", systemImage: "exclamationmark.triangle")
            } else {
                List(viewModel.paths) { path in
                    LearningPathRow(path: path)
                        .onTapGesture { selectedPath = path }
                        .listRowBackground(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedPath?.id == path.id ? Color.accentColor.opacity(0.1) : Color.clear)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 2)
                        )
                }
            }
        }
        .navigationTitle("Learning Paths")
        .task { await viewModel.reloadPaths() }
    }
}

// MARK: - Path Detail View

struct PathDetailView: View {
    let path: LearningPath
    var onSelectLesson: ((Lesson) -> Void)?
    @State private var lessons: [Lesson] = []
    @State private var isLoading = true

    var body: some View {
        Group {
            if isLoading {
                LoadingView(message: "Loading lessons...")
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                        // Path header
                        pathHeader
                            .fadeIn()

                        Divider()

                        // Lesson list
                        LazyVStack(spacing: Theme.Spacing.sm) {
                            ForEach(Array(lessons.enumerated()), id: \.element.id) { index, lesson in
                                GlassLessonRow(lesson: lesson, index: index, total: lessons.count)
                                    .onTapGesture { onSelectLesson?(lesson) }
                                    .fadeIn(delay: Double(index) * 0.05)
                            }
                        }
                    }
                    .padding(Theme.Spacing.lg)
                }
            }
        }
        .navigationTitle(path.title)
        .task { await loadLessons() }
    }

    private var pathHeader: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack(spacing: Theme.Spacing.md) {
                    Image(systemName: path.icon)
                        .font(.system(size: 36))
                        .foregroundStyle(Theme.pathGradient(for: path.color))
                        .frame(width: 60, height: 60)
                        .background(
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color(hex: path.color).opacity(0.15))
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        GradientText(path.title, font: .title.bold(), gradient: Theme.pathGradient(for: path.color))
                        Text(path.description)
                            .font(.body)
                            .foregroundColor(.secondary)

                        HStack(spacing: Theme.Spacing.sm) {
                            DifficultyBadge(difficulty: path.difficulty)
                            Text("\(path.lessons.count) lessons")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
    }

    private func loadLessons() async {
        isLoading = true
        do {
            lessons = try await ContentService.shared.loadAllLessonsForPath(path.id)
        } catch {
            print("Failed to load lessons: \(error)")
        }
        isLoading = false
    }
}

// MARK: - Learning Path Row

struct LearningPathRow: View {
    let path: LearningPath
    @State private var isHovered = false

    var body: some View {
        HStack(spacing: Theme.Spacing.md) {
            Image(systemName: path.icon)
                .font(.title3)
                .foregroundStyle(Theme.pathGradient(for: path.color))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(path.title)
                    .font(.headline)
                Text(path.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                DifficultyBadge(difficulty: path.difficulty)
                Text("\(path.lessons.count) lessons")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color.accentColor.opacity(0.05) : Color.clear)
        )
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.15)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Glass Lesson Row

struct GlassLessonRow: View {
    let lesson: Lesson
    let index: Int
    let total: Int
    @EnvironmentObject private var appState: AppState
    @State private var isHovered = false

    private var isCompleted: Bool {
        appState.userProgress.lessonProgress[lesson.id]?.completed ?? false
    }

    var body: some View {
        GlassCard(isHovered: isHovered) {
            HStack(spacing: Theme.Spacing.md) {
                // Step number or completion checkmark
                ZStack {
                    Circle()
                        .fill(isCompleted ? Color.green.opacity(0.2) : Color.gray.opacity(0.1))
                        .frame(width: 36, height: 36)

                    if isCompleted {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)
                    } else {
                        Text("\(index + 1)")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                    }
                }

                // Lesson info
                VStack(alignment: .leading, spacing: 4) {
                    Text(lesson.title)
                        .font(.headline)

                    HStack(spacing: Theme.Spacing.sm) {
                        DifficultyBadge(difficulty: lesson.difficulty)
                        Label("\(lesson.estimatedMinutes) min", systemImage: "clock")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Progress indicator
                if !isCompleted {
                    let progress = appState.userProgress.lessonProgress[lesson.id]?.progress ?? 0
                    if progress > 0 {
                        ProgressRing(progress: progress, size: 30)
                    }
                }

                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
                    .font(.caption)
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

#Preview {
    LearningPathsView()
        .environmentObject(AppState.shared)
}
