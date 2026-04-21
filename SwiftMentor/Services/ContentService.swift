import Foundation

final class ContentService {
    static let shared = ContentService()
    private init() {}

    private var cachedPaths: [LearningPath] = []
    private var cachedLessons: [String: Lesson] = [:]
    private var lessonsLoadedForPath: [String: Bool] = [:]

    // MARK: - Learning Paths

    func loadLearningPaths() async throws -> [LearningPath] {
        if !cachedPaths.isEmpty { return cachedPaths }
        return loadLearningPathsFromBundle()
    }

    func loadLearningPathsSync() -> [LearningPath] {
        if !cachedPaths.isEmpty { return cachedPaths }
        return loadLearningPathsFromBundle()
    }

    private func loadLearningPathsFromBundle() -> [LearningPath] {
        // Xcode flattens resources into the bundle root, so try subdirectory first then root
        let url = Bundle.main.url(forResource: "paths", withExtension: "json", subdirectory: "LearningPaths")
            ?? Bundle.main.url(forResource: "paths", withExtension: "json")

        guard let url else {
            #if DEBUG
            print("⚠️ paths.json not found in bundle, using hardcoded fallback")
            #endif
            return hardcodedFallbackPaths
        }
        return decodePaths(from: url)
    }

    private func decodePaths(from url: URL) -> [LearningPath] {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let response = try decoder.decode(LearningPathsResponse.self, from: data)
            cachedPaths = response.paths
            #if DEBUG
            print("✅ Loaded \(cachedPaths.count) learning paths from JSON")
            #endif
            return cachedPaths
        } catch {
            #if DEBUG
            print("⚠️ Failed to decode paths.json: \(error)")
            print("⚠️ Falling back to hardcoded paths")
            #endif
            return hardcodedFallbackPaths
        }
    }

    // MARK: - Lessons

    func loadAllLessonsForPath(_ pathId: String) async throws -> [Lesson] {
        // If we already loaded lessons for this path, return cached
        if lessonsLoadedForPath[pathId] == true {
            let lessons = cachedLessons.values.filter { $0.pathId == pathId }
            if !lessons.isEmpty { return lessons.sorted { $0.order < $1.order } }
        }

        // Try to load lesson JSON files from the bundle
        var loadedLessons: [Lesson] = []

        // First, get the lesson IDs from the cached paths
        let pathRef = cachedPaths.first { $0.id == pathId }
        let lessonRefs = pathRef?.lessons ?? []

        for ref in lessonRefs {
            if let cached = cachedLessons[ref.id] {
                loadedLessons.append(cached)
                continue
            }

            // Try to load from bundle
            if let lesson = loadLessonFromBundle(lessonId: ref.id) {
                cachedLessons[ref.id] = lesson
                loadedLessons.append(lesson)
            } else {
                // Fallback: create a placeholder lesson from the LessonRef
                let placeholder = Lesson(
                    id: ref.id,
                    pathId: pathId,
                    title: ref.title,
                    description: "Lesson content loading...",
                    difficulty: .beginner,
                    estimatedMinutes: 30,
                    order: lessonRefs.firstIndex(where: { $0.id == ref.id }).map { $0 + 1 } ?? 1,
                    sections: [],
                    xcodeProject: nil
                )
                cachedLessons[ref.id] = placeholder
                loadedLessons.append(placeholder)
            }
        }

        lessonsLoadedForPath[pathId] = true
        let sorted = loadedLessons.sorted { $0.order < $1.order }
        print("✅ Loaded \(sorted.count) lessons for path: \(pathId)")
        return sorted
    }

    func loadLesson(id: String) async throws -> Lesson {
        if let cached = cachedLessons[id] { return cached }

        // Try to load from bundle
        if let lesson = loadLessonFromBundle(lessonId: id) {
            cachedLessons[id] = lesson
            return lesson
        }

        // Fallback placeholder
        return Lesson(
            id: id,
            pathId: "",
            title: "Lesson",
            description: "",
            difficulty: .beginner,
            estimatedMinutes: 30,
            order: 1,
            sections: [],
            xcodeProject: nil
        )
    }

    private func loadLessonFromBundle(lessonId: String) -> Lesson? {
        // Try to find the JSON file in the Lessons subdirectory
        guard let url = Bundle.main.url(forResource: lessonId, withExtension: "json", subdirectory: "Lessons") else {
            // Fallback: try without subdirectory
            guard let url = Bundle.main.url(forResource: lessonId, withExtension: "json") else {
                print("⚠️ Lesson file not found: \(lessonId).json")
                return nil
            }
            return decodeLesson(from: url, id: lessonId)
        }
        return decodeLesson(from: url, id: lessonId)
    }

    private func decodeLesson(from url: URL, id: String) -> Lesson? {
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let lesson = try decoder.decode(Lesson.self, from: data)
            return lesson
        } catch {
            print("⚠️ Failed to decode lesson \(id): \(error)")
            return nil
        }
    }

    // MARK: - Search

    func searchLessons(query: String) async throws -> [Lesson] {
        // Load all lessons first
        for path in cachedPaths {
            if lessonsLoadedForPath[path.id] != true {
                _ = try await loadAllLessonsForPath(path.id)
            }
        }

        let lowercaseQuery = query.lowercased()
        return cachedLessons.values.filter { lesson in
            // Match on title, description, or section content
            if lesson.title.lowercased().contains(lowercaseQuery) { return true }
            if lesson.description.lowercased().contains(lowercaseQuery) { return true }

            // Deep search into lesson sections
            for section in lesson.sections {
                switch section {
                case .text(let content):
                    if content.lowercased().contains(lowercaseQuery) { return true }
                case .code(let language, let title, let starterCode, _, let solution):
                    if title.lowercased().contains(lowercaseQuery) { return true }
                    if starterCode.lowercased().contains(lowercaseQuery) { return true }
                    if let solution = solution, solution.lowercased().contains(lowercaseQuery) { return true }
                    if language.lowercased().contains(lowercaseQuery) { return true }
                case .interactive(let title, let instructions, _, _):
                    if title.lowercased().contains(lowercaseQuery) { return true }
                    if instructions.lowercased().contains(lowercaseQuery) { return true }
                case .quiz(let quiz):
                    if quiz.question.lowercased().contains(lowercaseQuery) { return true }
                    if quiz.options.contains(where: { $0.lowercased().contains(lowercaseQuery) }) { return true }
                case .image(_, let alt):
                    if alt.lowercased().contains(lowercaseQuery) { return true }
                }
            }

            return false
        }
    }

    // MARK: - Recent Lessons

    func getRecentLessons(limit: Int) async throws -> [Lesson] {
        // Return the first few lessons from the first path as "recent"
        if cachedPaths.isEmpty { return [] }
        let firstPath = cachedPaths[0]
        let lessons = try await loadAllLessonsForPath(firstPath.id)
        return Array(lessons.prefix(limit))
    }

    // MARK: - Hardcoded Fallback

    private var hardcodedFallbackPaths: [LearningPath] {
        [
            LearningPath(id: "swift-fundamentals", title: "Swift Fundamentals", description: "Master the Swift programming language from scratch.", icon: "swift", color: "#FF6B35", difficulty: .beginner, lessons: [
                LessonRef(id: "swift-fundamentals-1", title: "Introduction to Swift", type: "lesson"),
                LessonRef(id: "swift-fundamentals-2", title: "Variables and Constants", type: "lesson"),
                LessonRef(id: "swift-fundamentals-3", title: "Data Types", type: "lesson"),
                LessonRef(id: "swift-fundamentals-4", title: "Control Flow", type: "lesson"),
                LessonRef(id: "swift-fundamentals-5", title: "Functions", type: "lesson")
            ], prerequisites: [], order: 1),
            LearningPath(id: "swiftui-essentials", title: "SwiftUI Essentials", description: "Learn to build beautiful, modern user interfaces with Apple's declarative UI framework.", icon: "square.stack.3d.up.fill", color: "#4ECDC4", difficulty: .beginner, lessons: [
                LessonRef(id: "swiftui-essentials-1", title: "SwiftUI Basics", type: "lesson"),
                LessonRef(id: "swiftui-essentials-2", title: "Layout System", type: "lesson"),
                LessonRef(id: "swiftui-essentials-3", title: "State and Data Flow", type: "lesson"),
                LessonRef(id: "swiftui-essentials-4", title: "User Input", type: "lesson"),
                LessonRef(id: "swiftui-essentials-5", title: "Navigation", type: "lesson")
            ], prerequisites: [], order: 2),
            LearningPath(id: "advanced-swift", title: "Advanced Swift", description: "Take your Swift skills to the next level with protocols, generics, concurrency, and more.", icon: "cpu", color: "#9B5DE5", difficulty: .advanced, lessons: [
                LessonRef(id: "advanced-swift-1", title: "Protocols", type: "lesson"),
                LessonRef(id: "advanced-swift-2", title: "Generics", type: "lesson"),
                LessonRef(id: "advanced-swift-3", title: "Error Handling", type: "lesson"),
                LessonRef(id: "advanced-swift-4", title: "Concurrency with async/await", type: "lesson"),
                LessonRef(id: "advanced-swift-5", title: "Memory Management", type: "lesson")
            ], prerequisites: [], order: 3),
            LearningPath(id: "metal-basics", title: "Metal Basics", description: "Unlock the full power of the GPU for high-performance graphics and compute.", icon: "cpu.fill", color: "#F72585", difficulty: .advanced, lessons: [
                LessonRef(id: "metal-basics-1", title: "Introduction to Metal", type: "lesson"),
                LessonRef(id: "metal-basics-2", title: "Shaders 101", type: "lesson"),
                LessonRef(id: "metal-basics-3", title: "Rendering Pipeline", type: "lesson")
            ], prerequisites: [], order: 4),
            LearningPath(id: "coreml-intro", title: "CoreML Introduction", description: "Integrate machine learning models into your apps with Apple's CoreML framework.", icon: "brain.head.profile", color: "#4361EE", difficulty: .intermediate, lessons: [
                LessonRef(id: "coreml-intro-1", title: "Getting Started with CoreML", type: "lesson"),
                LessonRef(id: "coreml-intro-2", title: "Vision Framework", type: "lesson"),
                LessonRef(id: "coreml-intro-3", title: "Natural Language Processing", type: "lesson")
            ], prerequisites: [], order: 5),
            LearningPath(id: "xcode-mastery", title: "Xcode Mastery", description: "Master Apple's IDE: debugging, instruments, build settings, and workflow optimization.", icon: "hammer.fill", color: "#007AFF", difficulty: .intermediate, lessons: [
                LessonRef(id: "xcode-mastery-1", title: "Xcode Fundamentals", type: "lesson"),
                LessonRef(id: "xcode-mastery-2", title: "Debugging & Instruments", type: "lesson"),
                LessonRef(id: "xcode-mastery-3", title: "Build Settings & Distribution", type: "lesson")
            ], prerequisites: [], order: 6),
            LearningPath(id: "swiftdata-essentials", title: "SwiftData Essentials", description: "Learn Apple's modern data persistence framework with the @Model macro.", icon: "internaldrive", color: "#5856D6", difficulty: .intermediate, lessons: [
                LessonRef(id: "swiftdata-essentials-1", title: "SwiftData Basics", type: "lesson"),
                LessonRef(id: "swiftdata-essentials-2", title: "Queries & Filtering", type: "lesson"),
                LessonRef(id: "swiftdata-essentials-3", title: "Relationships & Migrations", type: "lesson")
            ], prerequisites: [], order: 7),
            LearningPath(id: "widgetkit-basics", title: "WidgetKit Basics", description: "Build home screen and lock screen widgets for iOS and macOS.", icon: "rectangle.on.rectangle.angled", color: "#FF9500", difficulty: .intermediate, lessons: [
                LessonRef(id: "widgetkit-basics-1", title: "Widget Fundamentals", type: "lesson"),
                LessonRef(id: "widgetkit-basics-2", title: "Timeline & Configuration", type: "lesson"),
                LessonRef(id: "widgetkit-basics-3", title: "Interactive Widgets", type: "lesson")
            ], prerequisites: [], order: 8),
            LearningPath(id: "combine-framework", title: "Combine Framework", description: "Master reactive programming with Apple's Combine framework.", icon: "arrow.triangle.2.circlepath", color: "#34C759", difficulty: .advanced, lessons: [
                LessonRef(id: "combine-framework-1", title: "Publishers & Subscribers", type: "lesson"),
                LessonRef(id: "combine-framework-2", title: "Operators & Transforms", type: "lesson"),
                LessonRef(id: "combine-framework-3", title: "Error Handling & Schedulers", type: "lesson")
            ], prerequisites: [], order: 9),
            LearningPath(id: "appstore-distribution", title: "App Store Distribution", description: "From archive to App Store: provisioning, testing, notarization, and submission.", icon: "bag.fill", color: "#FF2D55", difficulty: .advanced, lessons: [
                LessonRef(id: "appstore-distribution-1", title: "Provisioning & Signing", type: "lesson"),
                LessonRef(id: "appstore-distribution-2", title: "Testing & Notarization", type: "lesson"),
                LessonRef(id: "appstore-distribution-3", title: "App Store Submission", type: "lesson")
            ], prerequisites: [], order: 10)
        ]
    }
}
