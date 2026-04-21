import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @EnvironmentObject private var appState: AppState
    @State private var animatedProgress: Double = 0
    @State private var appear = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                headerSection
                    .fadeIn(delay: 0)

                if viewModel.isLoading {
                    LoadingView(message: "Loading your dashboard...")
                } else {
                    statsSection
                        .fadeIn(delay: 0.1)

                    dailyGoalSection
                        .fadeIn(delay: 0.2)

                    recentLessonsSection
                        .fadeIn(delay: 0.3)

                    learningPathsSection
                        .fadeIn(delay: 0.4)
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("Dashboard")
        .task {
            await viewModel.loadData()
            withAnimation(.easeInOut(duration: 1.0)) {
                animatedProgress = viewModel.progressPercentage
            }
            appear = true
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    GradientText("Welcome to SwiftMentor", font: .system(size: 32, weight: .bold, design: .rounded))
                    Text("Your command center for mastering Apple development")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                Spacer()

                // Animated overall progress ring
                ZStack {
                    ProgressRing(progress: animatedProgress, size: 64)
                    Text("\(Int(animatedProgress * 100))%")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(.accentColor)
                }
            }
        }
    }

    // MARK: - Stats

    private var statsSection: some View {
        HStack(spacing: Theme.Spacing.md) {
            StatGlassCard(
                title: "Completed",
                value: "\(viewModel.completedLessonsCount)",
                subtitle: "of \(viewModel.totalLessonsCount) lessons",
                icon: "checkmark.circle.fill",
                gradient: Theme.greenGradient
            )

            StatGlassCard(
                title: "Progress",
                value: "\(Int(viewModel.progressPercentage * 100))%",
                subtitle: "overall mastery",
                icon: "chart.bar.fill",
                gradient: Theme.blueGradient
            )

            StatGlassCard(
                title: "Streak",
                value: "\(viewModel.streakDays)",
                subtitle: viewModel.streakDays == 1 ? "day" : "days",
                icon: "flame.fill",
                gradient: Theme.fireGradient
            )

            StatGlassCard(
                title: "Time",
                value: timeString(from: viewModel.totalTimeSpent),
                subtitle: "total invested",
                icon: "clock.fill",
                gradient: Theme.purpleGradient
            )
        }
    }

    // MARK: - Daily Goal

    private var dailyGoalSection: some View {
        GlassCard {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack {
                    Image(systemName: "target")
                        .font(.title2)
                        .foregroundStyle(Theme.orangeGradient)

                    Text("Daily Goal")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Spacer()

                    Text("\(dailyLessonsCompleted)/1 lesson")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                ProgressView(value: min(Double(dailyLessonsCompleted), 1.0))
                    .tint(dailyLessonsCompleted >= 1 ? .green : .orange)
                    .scaleEffect(y: 2)

                HStack(spacing: 12) {
                    ForEach(0..<7, id: \.self) { dayOffset in
                        let date = Calendar.current.date(byAdding: .day, value: -(6 - dayOffset), to: Date())!
                        let dayLetter = Formatter.veryShortDaySymbol(from: date)
                        let isToday = Calendar.current.isDateInToday(date)
                        let completed = dayOffset == 0 ? dailyLessonsCompleted > 0 : Bool.random() // Placeholder for real data

                        VStack(spacing: 4) {
                            Text(dayLetter)
                                .font(.caption2)
                                .foregroundColor(isToday ? .primary : .secondary)
                                .fontWeight(isToday ? .bold : .regular)

                            Circle()
                                .fill(completed ? Color.green : Color.gray.opacity(0.2))
                                .frame(width: 12, height: 12)
                                .overlay {
                                    if completed {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 8, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .if(isToday) { view in
                                    view.overlay(
                                        Circle()
                                            .stroke(Color.accentColor, lineWidth: 2)
                                    )
                                }
                        }
                    }

                    Spacer()

                    if dailyLessonsCompleted >= 1 {
                        Label("Goal met!", systemImage: "checkmark.seal.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    } else {
                        Button("Start a Lesson") {
                            appState.selectedSection = .learningPaths
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
            }
        }
    }

    // MARK: - Recent Lessons ("Jump Back In")

    private var recentLessonsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .foregroundStyle(Theme.blueGradient)
                Text("Jump Back In")
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            if viewModel.recentLessons.isEmpty {
                GlassCard {
                    VStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "book")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No lessons started yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Begin a learning path to see your recent activity here")
                            .font(.subheadline)
                            .foregroundColor(Color.secondary.opacity(0.6))
                        Button("Browse Learning Paths") {
                            appState.selectedSection = .learningPaths
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.xl)
                }
            } else {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.md) {
                    ForEach(viewModel.recentLessons.prefix(4)) { lesson in
                        RecentLessonCard(lesson: lesson)
                    }
                }
            }
        }
    }

    // MARK: - Learning Paths

    private var learningPathsSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "map")
                    .foregroundStyle(Theme.purpleGradient)
                Text("Learning Paths")
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            ForEach(viewModel.learningPaths) { path in
                GlassPathCard(path: path)
                    .onTapGesture {
                        appState.selectedPath = path
                        appState.selectedSection = .learningPaths
                    }
            }
        }
    }

    // MARK: - Helpers

    private var dailyLessonsCompleted: Int {
        // Check if user completed any lessons today
        let today = Calendar.current.startOfDay(for: Date())
        return appState.userProgress.lessonProgress.values.filter { progress in
            guard let date = progress.lastAccessedDate, progress.completed else { return false }
            return Calendar.current.isDate(date, inSameDayAs: today)
        }.count
    }

    private func timeString(from seconds: TimeInterval) -> String {
        let hours = Int(seconds / 3600)
        let minutes = Int((seconds.truncatingRemainder(dividingBy: 3600)) / 60)
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}

// MARK: - Recent Lesson Card

struct RecentLessonCard: View {
    let lesson: Lesson
    @EnvironmentObject private var appState: AppState
    @State private var isHovered = false

    private var progress: LessonProgress {
        appState.userProgress.lessonProgress[lesson.id] ?? LessonProgress()
    }

    var body: some View {
        GlassCard(isHovered: isHovered) {
            HStack(spacing: Theme.Spacing.md) {
                VStack(alignment: .leading, spacing: 4) {
                    Image(systemName: lesson.icon)
                        .font(.title2)
                        .foregroundStyle(Theme.blueGradient)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(lesson.title)
                        .font(.headline)
                        .lineLimit(1)

                    Text(lesson.description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)

                    HStack(spacing: Theme.Spacing.sm) {
                        DifficultyBadge(difficulty: lesson.difficulty)
                        Text("\(lesson.estimatedMinutes) min")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                ProgressRing(progress: progress.progress, size: 36)
            }
        }
        .onTapGesture {
            Task { @MainActor in
                await AppState.shared.loadLessonsForPath(lesson.pathId)
                AppState.shared.navigateToLesson(lesson)
                AppState.shared.selectedSection = .playground
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Glass Path Card

struct GlassPathCard: View {
    let path: LearningPath
    @EnvironmentObject private var appState: AppState
    @State private var isHovered = false

    private var progress: PathProgress {
        appState.userProgress.pathProgress[path.id] ?? PathProgress()
    }

    private var progressValue: Double {
        let completed = progress.completedLessons.count
        guard path.lessons.count > 0 else { return 0 }
        return Double(completed) / Double(path.lessons.count)
    }

    var body: some View {
        GlassCard(isHovered: isHovered) {
            HStack(spacing: Theme.Spacing.md) {
                // Path icon with gradient
                Image(systemName: path.icon)
                    .font(.title)
                    .foregroundStyle(Theme.pathGradient(for: path.color))
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: path.color).opacity(0.15))
                    )

                VStack(alignment: .leading, spacing: 4) {
                    Text(path.title)
                        .font(.headline)
                    HStack(spacing: Theme.Spacing.sm) {
                        Text("\(path.lessons.count) lessons")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        DifficultyBadge(difficulty: path.difficulty)
                    }

                    // Progress bar
                    if progressValue > 0 {
                        ProgressView(value: progressValue)
                            .tint(Color(hex: path.color))
                            .scaleEffect(y: 1.5)
                    }
                }

                Spacer()

                ProgressRing(progress: progressValue, size: 44)

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

// MARK: - Formatter Helper

private extension Formatter {
    static func veryShortDaySymbol(from date: Date) -> String {
        let symbols = Calendar.current.veryShortWeekdaySymbols
        let index = Calendar.current.component(.weekday, from: date) - 1
        return symbols[index]
    }
}

#Preview {
    DashboardView()
        .environmentObject(AppState.shared)
}
