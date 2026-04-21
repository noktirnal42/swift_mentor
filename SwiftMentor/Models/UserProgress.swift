import Foundation

struct UserProgress: Codable {
    var lessonProgress: [String: LessonProgress]
    var pathProgress: [String: PathProgress]
    var quizScores: [String: Int]
    var streakDays: Int
    var lastActiveDate: Date?
    var totalTimeSpent: TimeInterval
    var achievements: [String]
    var bookmarkedLessons: [String]
    var notes: [String: String]

    init() {
        lessonProgress = [:]
        pathProgress = [:]
        quizScores = [:]
        streakDays = 0
        lastActiveDate = nil
        totalTimeSpent = 0
        achievements = []
        bookmarkedLessons = []
        notes = [:]
    }

    var overallProgress: Double {
        guard !lessonProgress.isEmpty else { return 0 }
        let total = lessonProgress.values.reduce(0) { $0 + $1.progress }
        return total / Double(lessonProgress.count)
    }
}

struct LessonProgress: Codable {
    var completed: Bool
    var progress: Double
    var lastAccessedDate: Date?
    var timeSpent: TimeInterval
    var attempts: Int

    init() {
        completed = false
        progress = 0
        lastAccessedDate = nil
        timeSpent = 0
        attempts = 0
    }
}

struct PathProgress: Codable {
    var completedLessons: [String]
    var currentLessonIndex: Int
    var startedDate: Date?
    var completedDate: Date?

    var progress: Double {
        guard !completedLessons.isEmpty else { return 0 }
        return Double(completedLessons.count)
    }

    init() {
        completedLessons = []
        currentLessonIndex = 0
        startedDate = nil
        completedDate = nil
    }
}

struct Achievement: Codable, Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let requirement: AchievementRequirement
    let unlockedDate: Date?

    enum AchievementRequirement: Codable {
        case lessonsCompleted(count: Int)
        case quizPerfectScore(lessonId: String)
        case streakDays(count: Int)
        case pathCompleted(pathId: String)
        case totalTimeSpent(minutes: Int)
    }
}

struct DailyStreak {
    let date: Date
    let completedLessons: Int

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var isYesterday: Bool {
        Calendar.current.isDateInYesterday(date)
    }
}