// Import models for UserProgress and LessonProgress types
import Foundation
import SQLite

final class ProgressService {
    static let shared = ProgressService()
    private let database = DatabaseManager.shared

    private init() {}

    func loadProgress() -> UserProgress {
        var progress = UserProgress()

        // Load lesson progress from database
        progress.lessonProgress = loadAllLessonProgress()

        // Load other data from database
        progress.bookmarkedLessons = database.getBookmarkedLessons()
        progress.notes = loadAllNotes()
        progress.quizScores = loadAllQuizScores()

        // Streak and time data from database
        progress.streakDays = database.getCurrentStreak()
        progress.lastActiveDate = loadLastActiveDate()
        progress.totalTimeSpent = loadTotalTimeSpent()

        // Achievements would be loaded separately if implemented
        progress.achievements = loadAchievements()

        return progress
    }

    func saveProgress(_ progress: UserProgress) {
        // Individual components are saved separately as needed
        #if DEBUG
        print("Progress save called - individual saves handle persistence")
        #endif
    }

    func updateLessonProgress(lessonId: String, progress: LessonProgress) {
        // Update last accessed time
        updateLessonAccessed(lessonId: lessonId)

        // Update progress percentage if provided
        if progress.progress > 0 {
            updateLessonProgressPercentage(lessonId: lessonId, progress: progress.progress)
        }

        // Update time spent if provided
        if progress.timeSpent > 0 {
            updateLessonTimeSpent(lessonId: lessonId, timeSpent: Int(progress.timeSpent))
        }

        // Update attempts
        updateLessonAttempts(lessonId: lessonId, attempts: progress.attempts)
    }

    func markLessonCompleted(lessonId: String, pathId: String = "", timeSpent: Int = 0) {
        do {
            try database.markLessonCompleted(lessonId: lessonId, pathId: pathId, timeSpent: timeSpent)
        } catch {
            print("Error marking lesson completed: \(error)")
        }
        updateStreak()
    }

    func saveQuizScore(lessonId: String, score: Int, total: Int = 1) {
        do {
            try database.saveQuizScore(lessonId: lessonId, score: score, total: total)
        } catch {
            print("Error saving quiz score: \(error)")
        }
    }

    func loadQuizScore(lessonId: String) -> Int? {
        return database.getBestQuizScore(lessonId: lessonId)
    }

    func addBookmark(lessonId: String) {
        let _ = database.toggleBookmark(lessonId: lessonId)
    }

    func removeBookmark(lessonId: String) {
        let _ = database.toggleBookmark(lessonId: lessonId)
    }

    func isBookmarked(lessonId: String) -> Bool {
        return database.isBookmarked(lessonId: lessonId)
    }

    func loadNote(lessonId: String) -> String? {
        return database.getNote(lessonId: lessonId)
    }

    func saveNote(lessonId: String, note: String) {
        do {
            try database.saveNote(lessonId: lessonId, content: note)
        } catch {
            print("Error saving note: \(error)")
        }
    }

    private func updateStreak() {
        database.updateStreak()
    }

    func getCompletedLessonsCount() -> Int {
        return database.getOverallStats().lessonsCompleted
    }

    func getTotalLessonsCount() -> Int {
        // This should come from the actual lesson count in the content service
        // For now, return a reasonable default that can be overridden
        return 40
    }

    func getProgressPercentage() -> Double {
        let completed = getCompletedLessonsCount()
        let total = getTotalLessonsCount()
        guard total > 0 else { return 0 }
        return Double(completed) / Double(total)
    }

    // MARK: - Private Helper Methods

    private func loadAllLessonProgress() -> [String: LessonProgress] {
        var progressMap = [String: LessonProgress]()

        guard let db = database.db else { return progressMap }

        do {
            let query = database.userProgress
            for row in try db.prepare(query) {
                let lessonId = row[database.lessonId]
                let completed = row[database.completed]
                let timeSpent = TimeInterval(row[database.timeSpentSeconds])
                let lastAccessed = row[database.lastAccessedDate]

                var lessonProgress = LessonProgress()
                lessonProgress.completed = completed
                lessonProgress.timeSpent = timeSpent
                lessonProgress.lastAccessedDate = lastAccessed
                lessonProgress.progress = completed ? 1.0 : 0.0
                // Attempts would need to be tracked separately

                progressMap[lessonId] = lessonProgress
            }
        } catch {
            print("Error loading lesson progress: \(error)")
        }

        return progressMap
    }

    private func loadAllNotes() -> [String: String] {
        var notesMap = [String: String]()

        guard let db = database.db else { return notesMap }

        do {
            let query = database.notes
            for row in try db.prepare(query) {
                let lessonId = row[database.noteLessonId]
                let content = row[database.noteContent]
                notesMap[lessonId] = content
            }
        } catch {
            print("Error loading notes: \(error)")
        }

        return notesMap
    }

    private func loadAllQuizScores() -> [String: Int] {
        var scoresMap = [String: Int]()

        guard let db = database.db else { return scoresMap }

        do {
            let query = database.quizScores
                .select(database.quizLessonId, database.score.max)
                .group(database.quizLessonId)

            for row in try db.prepare(query) {
                let lessonId = row[database.quizLessonId]
                let bestScore = row[database.score.max]
                scoresMap[lessonId] = bestScore
            }
        } catch {
            print("Error loading quiz scores: \(error)")
        }

        return scoresMap
    }

    private func loadLastActiveDate() -> Date? {
        // This would need to be tracked in the database
        // For now, return a reasonable default
        return UserDefaults.standard.object(forKey: "lastActiveDate") as? Date ?? Date()
    }

    private func loadTotalTimeSpent() -> TimeInterval {
        do {
            guard let db = database.db else { return 0 }
            let totalSeconds = try db.scalar(
                database.userProgress.select(database.timeSpentSeconds.sum)
            ) ?? 0
            return TimeInterval(totalSeconds)
        } catch {
            print("Error loading total time spent: \(error)")
            return 0
        }
    }

    private func loadAchievements() -> [String] {
        // Achievements system would be implemented separately
        return []
    }

    private func updateLessonAccessed(lessonId: String) {
        guard let db = database.db else { return }

        do {
            let lesson = database.userProgress.filter(database.lessonId == lessonId)
            if try db.pluck(lesson) != nil {
                let lastAccessed = database.lastAccessedDate
                try db.run(lesson.update(lastAccessed <- Date()))
            }
        } catch {
            print("Error updating lesson accessed date: \(error)")
        }
    }

    private func updateLessonProgressPercentage(lessonId: String, progress: Double) {
        // This would require adding a progress column to the user_progress table
        // For now, we infer progress from completion status
        if progress >= 1.0 {
            // Treat as completed
            do {
                guard let db = database.db else { return }
                let lesson = database.userProgress.filter(database.lessonId == lessonId)
                if try db.pluck(lesson) == nil {
                    // Insert as completed
                    try db.run(database.userProgress.insert(
                        database.lessonId <- lessonId,
                        database.pathId <- "", // Would need to get this from content service
                        database.completed <- true,
                        database.completionDate <- Date(),
                        database.timeSpentSeconds <- 0,
                        database.lastAccessedDate <- Date()
                    ))
                }
            } catch {
                print("Error marking lesson as completed: \(error)")
            }
        }
    }

    private func updateLessonTimeSpent(lessonId: String, timeSpent: Int) {
        guard let db = database.db else { return }

        do {
            let lesson = database.userProgress.filter(database.lessonId == lessonId)
            if let current = try db.pluck(lesson) {
                let currentTime = current[database.timeSpentSeconds]
                try db.run(lesson.update(
                    database.timeSpentSeconds <- currentTime + timeSpent,
                    database.lastAccessedDate <- Date()
                ))
            }
        } catch {
            print("Error updating lesson time spent: \(error)")
        }
    }

    private func updateLessonAttempts(lessonId: String, attempts: Int) {
        // This would require adding an attempts column to the user_progress table
        // For simplicity, we're not tracking attempts in detail for now
        #if DEBUG
        print("Lesson \(lessonId) attempted \(attempts) times")
        #endif
    }
}