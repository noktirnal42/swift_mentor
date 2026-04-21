import SwiftUI

struct ProgressView_: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = ProgressViewModel()
    @State private var selectedTab = 0

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                // Tab picker
                Picker("View", selection: $selectedTab) {
                    Text("Overview").tag(0)
                    Text("Trophy Room").tag(1)
                    Text("Activity").tag(2)
                }
                .pickerStyle(.segmented)
                .padding(.bottom, 4)

                switch selectedTab {
                case 0:
                    overviewSection
                case 1:
                    trophyRoomSection
                case 2:
                    activitySection
                default:
                    overviewSection
                }
            }
            .padding(Theme.Spacing.lg)
        }
        .navigationTitle("Progress")
        .task {
            viewModel.loadProgress()
        }
    }

    // MARK: - Overview

    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            // Stats cards
            HStack(spacing: Theme.Spacing.md) {
                StatGlassCard(
                    title: "Overall Progress",
                    value: "\(Int(viewModel.overallProgress * 100))%",
                    subtitle: "mastery",
                    icon: "chart.bar.fill",
                    gradient: Theme.blueGradient
                )
                StatGlassCard(
                    title: "Lessons Completed",
                    value: "\(appState.completedLessonsCount)",
                    subtitle: "total",
                    icon: "checkmark.circle.fill",
                    gradient: Theme.greenGradient
                )
                StatGlassCard(
                    title: "Current Streak",
                    value: "\(viewModel.streakDays)",
                    subtitle: viewModel.streakDays == 1 ? "day" : "days",
                    icon: "flame.fill",
                    gradient: Theme.fireGradient
                )
            }
            .fadeIn()

            // Paths progress
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                HStack {
                    Image(systemName: "map")
                        .foregroundStyle(Theme.purpleGradient)
                    Text("Learning Paths")
                        .font(.title2)
                        .fontWeight(.semibold)
                }

                ForEach(appState.learningPaths) { path in
                    GlassPathProgressRow(path: path)
                        .fadeIn(delay: 0.1)
                }
            }
        }
    }

    // MARK: - Trophy Room

    private var trophyRoomSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.title2)
                    .foregroundStyle(Theme.orangeGradient)
                Text("Trophy Room")
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            let earnedBadges = AchievementDefinitions.all.filter { appState.userProgress.achievements.contains($0.id) }
            let lockedBadges = AchievementDefinitions.all.filter { !appState.userProgress.achievements.contains($0.id) }

            if !earnedBadges.isEmpty {
                Text("Earned")
                    .font(.headline)
                    .foregroundColor(.secondary)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.md) {
                    ForEach(earnedBadges) { badge in
                        TrophyCard(badge: badge, isEarned: true)
                    }
                }
            }

            if !lockedBadges.isEmpty {
                Text("Locked")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .padding(.top)

                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: Theme.Spacing.md) {
                    ForEach(lockedBadges) { badge in
                        TrophyCard(badge: badge, isEarned: false)
                    }
                }
            }

            if earnedBadges.isEmpty && lockedBadges.isEmpty {
                GlassCard {
                    VStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "trophy")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)
                        Text("No achievements yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Complete lessons and maintain streaks to earn badges!")
                            .font(.subheadline)
                            .foregroundColor(Color.secondary.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.xl)
                }
            }
        }
    }

    // MARK: - Activity

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.md) {
            HStack {
                Image(systemName: "clock.arrow.circlepath")
                    .foregroundStyle(Theme.tealGradient)
                Text("Recent Activity")
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            let completedLessons = Array(appState.userProgress.lessonProgress
                .filter { $0.value.completed }
                .sorted { ($0.value.lastAccessedDate ?? .distantPast) > ($1.value.lastAccessedDate ?? .distantPast) }
                .prefix(10))

            if completedLessons.isEmpty {
                GlassCard {
                    VStack(spacing: Theme.Spacing.md) {
                        Image(systemName: "clock")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)
                        Text("No recent activity")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Start completing lessons to see your activity here")
                            .font(.subheadline)
                            .foregroundColor(Color.secondary.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Theme.Spacing.xl)
                }
            } else {
                ForEach(Array(completedLessons), id: \.key) { (lessonId: String, progress: LessonProgress) in
                    GlassCard {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.title3)
                            Text(lessonId.replacingOccurrences(of: "-", with: " ").capitalized)
                                .font(.subheadline)
                            Spacer()
                            if let date = progress.lastAccessedDate {
                                Text(date.relativeFormatted)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            if progress.timeSpent > 0 {
                                Label("\(Int(progress.timeSpent / 60))m", systemImage: "clock")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Glass Path Progress Row

struct GlassPathProgressRow: View {
    let path: LearningPath
    @EnvironmentObject private var appState: AppState
    @State private var isHovered = false

    private var progress: PathProgress {
        appState.userProgress.pathProgress[path.id] ?? PathProgress()
    }

    private var progressValue: Double {
        guard path.lessons.count > 0 else { return 0 }
        return Double(progress.completedLessons.count) / Double(path.lessons.count)
    }

    var body: some View {
        GlassCard(isHovered: isHovered) {
            HStack(spacing: Theme.Spacing.md) {
                Image(systemName: path.icon)
                    .font(.title2)
                    .foregroundStyle(Theme.pathGradient(for: path.color))
                    .frame(width: 40, height: 40)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(hex: path.color).opacity(0.15))
                    )

                VStack(alignment: .leading, spacing: 6) {
                    Text(path.title)
                        .font(.headline)

                    // Animated progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.15))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Theme.pathGradient(for: path.color))
                                .frame(width: geometry.size.width * CGFloat(progressValue), height: 8)
                                .animation(.easeInOut(duration: 0.6), value: progressValue)
                        }
                    }
                    .frame(height: 8)

                    Text("\(progress.completedLessons.count) of \(path.lessons.count) lessons completed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text("\(Int(progressValue * 100))%")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.pathGradient(for: path.color))
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Trophy Card

struct TrophyCard: View {
    let badge: AchievementDefinition
    let isEarned: Bool
    @State private var isHovered = false

    var body: some View {
        GlassCard(isHovered: isHovered) {
            VStack(spacing: Theme.Spacing.sm) {
                Image(systemName: badge.icon)
                    .font(.system(size: 32))
                    .foregroundStyle(isEarned ? Theme.orangeGradient : LinearGradient(
                        colors: [Color.gray.opacity(0.4), Color.gray.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .saturation(isEarned ? 1 : 0)

                Text(badge.title)
                    .font(.headline)
                    .foregroundColor(isEarned ? .primary : .secondary)

                Text(badge.description)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                if isEarned {
                    Text("Earned")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Spacing.sm)
        }
        .opacity(isEarned ? 1.0 : 0.5)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Achievement Definitions

struct AchievementDefinition: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
}

enum AchievementDefinitions {
    static let all: [AchievementDefinition] = [
        AchievementDefinition(id: "first-lesson", title: "First Steps", description: "Complete your first lesson", icon: "shoeprints.fill"),
        AchievementDefinition(id: "five-lessons", title: "Getting Warmer", description: "Complete 5 lessons", icon: "flame"),
        AchievementDefinition(id: "ten-lessons", title: "On Fire", description: "Complete 10 lessons", icon: "flame.fill"),
        AchievementDefinition(id: "all-fundamentals", title: "Fundamentals Done", description: "Complete the Swift Fundamentals path", icon: "swift"),
        AchievementDefinition(id: "first-quiz", title: "Quiz Whiz", description: "Score 100% on a quiz", icon: "questionmark.circle.fill"),
        AchievementDefinition(id: "streak-3", title: "Consistent", description: "Maintain a 3-day streak", icon: "calendar.badge.clock"),
        AchievementDefinition(id: "streak-7", title: "Week Warrior", description: "Maintain a 7-day streak", icon: "calendar.badge.checkmark"),
        AchievementDefinition(id: "streak-30", title: "Monthly Master", description: "Maintain a 30-day streak", icon: "calendar.badge.checkmark.fill"),
        AchievementDefinition(id: "first-code", title: "Hello World", description: "Run your first code in the playground", icon: "terminal.fill"),
        AchievementDefinition(id: "first-path", title: "Path Finder", description: "Complete an entire learning path", icon: "map.fill"),
        AchievementDefinition(id: "bookworm", title: "Bookworm", description: "Bookmark 5 lessons", icon: "bookmark.fill"),
        AchievementDefinition(id: "note-taker", title: "Note Taker", description: "Write notes on 3 lessons", icon: "note.text"),
    ]
}

#Preview {
    ProgressView_()
        .environmentObject(AppState.shared)
}
