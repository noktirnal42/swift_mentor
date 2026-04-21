import Foundation
import SQLite

/// DatabaseManager handles all SQLite operations for SwiftMentor
/// Uses SQLite.swift for type-safe database access
final class DatabaseManager {
    static let shared = DatabaseManager()

    var db: Connection?
    private let dbPath: String

    // MARK: - Table Definitions
    let userProgress = Table("user_progress")
    let lessonCompletions = Table("lesson_completions")
    let quizScores = Table("quiz_scores")
    let bookmarks = Table("bookmarks")
    let notes = Table("notes")
    let codeSnippets = Table("code_snippets")
    let streakData = Table("streak_data")

    // MARK: - Column Definitions
    // UserProgress columns
    let id = Expression<Int64>("id")
    let lessonId = Expression<String>("lesson_id")
    let pathId = Expression<String>("path_id")
    let completed = Expression<Bool>("completed")
    let completionDate = Expression<Date?>("completion_date")
    let timeSpentSeconds = Expression<Int>("time_spent_seconds")
    let lastAccessedDate = Expression<Date>("last_accessed_date")

    // QuizScore columns
    let quizLessonId = Expression<String>("lesson_id")
    let score = Expression<Int>("score")
    let totalQuestions = Expression<Int>("total_questions")
    let attemptDate = Expression<Date>("attempt_date")

    // Bookmark columns
    let bookmarkLessonId = Expression<String>("lesson_id")
    let bookmarkCreatedAt = Expression<Date>("created_at")

    // Note columns
    let noteLessonId = Expression<String>("lesson_id")
    let noteContent = Expression<String>("content")
    let noteCreatedAt = Expression<Date>("created_at")
    let noteUpdatedAt = Expression<Date>("updated_at")

    // CodeSnippet columns
    let snippetTitle = Expression<String>("title")
    let snippetCode = Expression<String>("code")
    let snippetLanguage = Expression<String>("language")
    let snippetTopic = Expression<String>("topic")
    let snippetIsBuiltIn = Expression<Bool>("is_built_in")
    let snippetCreatedAt = Expression<Date>("created_at")

    // StreakData columns
    let streakDate = Expression<Date>("date")
    let streakCount = Expression<Int>("streak_count")
    let lessonsCompleted = Expression<Int>("lessons_completed")

    // MARK: - Initialization
    private init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appFolder = appSupport.appendingPathComponent("SwiftMentor", isDirectory: true)

        // Create directory if needed
        try? FileManager.default.createDirectory(at: appFolder, withIntermediateDirectories: true)

        dbPath = appFolder.appendingPathComponent("swiftmentor.sqlite3").path

        do {
            db = try Connection(dbPath)
            createTables()
        } catch {
            print("Database connection failed: \(error)")
        }
    }

    // MARK: - Table Creation
    private func createTables() {
        guard let db = db else { return }

        do {
            // User Progress Table
            try db.run(userProgress.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement)
                t.column(lessonId, unique: true)
                t.column(pathId)
                t.column(completed, defaultValue: false)
                t.column(completionDate)
                t.column(timeSpentSeconds, defaultValue: 0)
                t.column(lastAccessedDate)
            })

            // Quiz Scores Table
            try db.run(quizScores.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement)
                t.column(quizLessonId)
                t.column(score)
                t.column(totalQuestions)
                t.column(attemptDate)
            })

            // Bookmarks Table
            try db.run(bookmarks.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement)
                t.column(bookmarkLessonId, unique: true)
                t.column(bookmarkCreatedAt)
            })

            // Notes Table
            try db.run(notes.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement)
                t.column(noteLessonId, unique: true)
                t.column(noteContent)
                t.column(noteCreatedAt)
                t.column(noteUpdatedAt)
            })

            // Code Snippets Table
            try db.run(codeSnippets.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement)
                t.column(snippetTitle)
                t.column(snippetCode)
                t.column(snippetLanguage, defaultValue: "swift")
                t.column(snippetTopic)
                t.column(snippetIsBuiltIn, defaultValue: false)
                t.column(snippetCreatedAt)
            })

            // Streak Data Table
            try db.run(streakData.create(ifNotExists: true) { t in
                t.column(id, primaryKey: .autoincrement)
                t.column(streakDate, unique: true)
                t.column(streakCount, defaultValue: 0)
                t.column(lessonsCompleted, defaultValue: 0)
            })

        } catch {
            print("Table creation failed: \(error)")
        }
    }

    // MARK: - Progress Methods
    func markLessonCompleted(lessonId lessonIdValue: String, pathId pathIdValue: String, timeSpent: Int) throws {
        guard let db = db else { return }

let update = userProgress
        .filter(lessonId == lessonIdValue)
        .update(
            completed <- true,
            completionDate <- Date(),
            timeSpentSeconds <- timeSpent,
            lastAccessedDate <- Date()
        )

        if try db.run(update) == 0 {
            let insert = userProgress.insert(
                lessonId <- lessonIdValue,
                pathId <- pathIdValue,
                completed <- true,
                completionDate <- Date(),
                timeSpentSeconds <- timeSpent,
                lastAccessedDate <- Date()
            )
            try db.run(insert)
        }
    }

    func getLessonProgress(lessonId lessonIdValue: String) -> (completed: Bool, timeSpent: Int)? {
        guard let db = db else { return nil }

        do {
            let query = userProgress.filter(lessonId == lessonIdValue)
            if let row = try db.pluck(query) {
                return (row[completed], row[timeSpentSeconds])
            }
        } catch {
            print("Error fetching lesson progress: \(error)")
        }
        return nil
    }

    func getPathProgress(pathId pathIdValue: String) -> (completed: Int, total: Int) {
        guard let db = db else { return (0, 0) }

        do {
            let completedCount = try db.scalar(
                userProgress.filter(pathId == pathIdValue && completed == true).count
            )
            return (completedCount, 0) // Total would come from lesson count
        } catch {
            print("Error fetching path progress: \(error)")
            return (0, 0)
        }
    }

    func getOverallStats() -> (lessonsCompleted: Int, totalTime: Int, currentStreak: Int) {
        guard let db = db else { return (0, 0, 0) }

        do {
            let lessonsCompleted = try db.scalar(userProgress.filter(completed == true).count)
            let totalTime = try db.scalar(userProgress.select(timeSpentSeconds.sum)) ?? 0
            let currentStreak = try db.scalar(streakData.select(streakCount.max)) ?? 0
            return (lessonsCompleted, totalTime, currentStreak)
        } catch {
            print("Error fetching overall stats: \(error)")
            return (0, 0, 0)
        }
    }

    // MARK: - Quiz Methods
    func saveQuizScore(lessonId lessonIdValue: String, score scoreValue: Int, total: Int) throws {
        guard let db = db else { return }

        let insert = quizScores.insert(
            quizLessonId <- lessonIdValue,
            score <- scoreValue,
            totalQuestions <- total,
            attemptDate <- Date()
        )
        try db.run(insert)
    }

    func getBestQuizScore(lessonId lessonIdValue: String) -> Int? {
        guard let db = db else { return nil }

        do {
            let query = quizScores
                .filter(quizLessonId == lessonIdValue)
                .order(score.desc)
                .limit(1)
            if let row = try db.pluck(query) {
                return row[score]
            }
        } catch {
            print("Error fetching quiz score: \(error)")
        }
        return nil
    }

    // MARK: - Bookmark Methods
    func toggleBookmark(lessonId lessonIdValue: String) -> Bool {
        guard let db = db else { return false }

        do {
            let query = bookmarks.filter(bookmarkLessonId == lessonIdValue)
            if try db.pluck(query) != nil {
                try db.run(query.delete())
                return false
            } else {
                try db.run(bookmarks.insert(
                    bookmarkLessonId <- lessonIdValue,
                    bookmarkCreatedAt <- Date()
                ))
                return true
            }
        } catch {
            print("Error toggling bookmark: \(error)")
            return false
        }
    }

    func isBookmarked(lessonId lessonIdValue: String) -> Bool {
        guard let db = db else { return false }

        do {
            let query = bookmarks.filter(bookmarkLessonId == lessonIdValue)
            return try db.pluck(query) != nil
        } catch {
            return false
        }
    }

    func getBookmarkedLessons() -> [String] {
        guard let db = db else { return [] }

        do {
            return try db.prepare(bookmarks).map { $0[bookmarkLessonId] }
        } catch {
            return []
        }
    }

    // MARK: - Notes Methods
    func saveNote(lessonId lessonIdValue: String, content: String) throws {
        guard let db = db else { return }

        let query = notes.filter(noteLessonId == lessonIdValue)
        if try db.pluck(query) != nil {
            try db.run(query.update(
                noteContent <- content,
                noteUpdatedAt <- Date()
            ))
        } else {
            try db.run(notes.insert(
                noteLessonId <- lessonIdValue,
                noteContent <- content,
                noteCreatedAt <- Date(),
                noteUpdatedAt <- Date()
            ))
        }
    }

    func getNote(lessonId lessonIdValue: String) -> String? {
        guard let db = db else { return nil }

        do {
            let query = notes.filter(noteLessonId == lessonIdValue)
            if let row = try db.pluck(query) {
                return row[noteContent]
            }
        } catch {
            print("Error fetching note: \(error)")
        }
        return nil
    }

    // MARK: - User Snippets Methods
    func saveUserSnippet(title: String, code: String, topic: String) throws {
        guard let db = db else { return }

        try db.run(codeSnippets.insert(
            snippetTitle <- title,
            snippetCode <- code,
            snippetLanguage <- "swift",
            snippetTopic <- topic,
            snippetIsBuiltIn <- false,
            snippetCreatedAt <- Date()
        ))
    }

    func getUserSnippets() -> [(id: Int64, title: String, code: String, topic: String)] {
        guard let db = db else { return [] }

        do {
            return try db.prepare(codeSnippets.filter(snippetIsBuiltIn == false))
                .map { (id: $0[id], title: $0[snippetTitle], code: $0[snippetCode], topic: $0[snippetTopic]) }
        } catch {
            return []
        }
    }

    func deleteUserSnippet(id snippetId: Int64) throws {
        guard let db = db else { return }
        try db.run(codeSnippets.filter(id == snippetId).delete())
    }

    // MARK: - Streak Methods
    func updateStreak() {
        guard let db = db else { return }

        let today = Calendar.current.startOfDay(for: Date())

        do {
            let query = streakData.filter(streakDate == today)

            if try db.pluck(query) != nil {
                try db.run(query.update(
                    lessonsCompleted += 1,
                    streakCount += 1
                ))
            } else {
                // Check if yesterday had a streak
                let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: today)!
                let yesterdayQuery = streakData.filter(streakDate == yesterday)

                let newStreak = (try? db.pluck(yesterdayQuery))?[streakCount] ?? 0

                try db.run(streakData.insert(
                    streakDate <- today,
                    streakCount <- newStreak + 1,
                    lessonsCompleted <- 1
                ))
            }
        } catch {
            print("Error updating streak: \(error)")
        }
    }

    func getCurrentStreak() -> Int {
        guard let db = db else { return 0 }

        let today = Calendar.current.startOfDay(for: Date())
        let query = streakData.filter(streakDate == today)
        return (try? db.pluck(query))?[streakCount] ?? 0
    }
}
