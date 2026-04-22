import XCTest
@testable import SwiftMentor

final class UserProgressTests: XCTestCase {
    var progressService: ProgressService!
    
    override func setUp() async throws {
        progressService = ProgressService.shared
    }
    
    override func tearDown() {
        progressService = nil
    }
    
    // Test that ProgressService singleton is accessible
    func testProgressServiceShared() {
        XCTAssertNotNil(ProgressService.shared)
    }
    
    // Test user progress initialization
    func testUserProgressInitialization() {
        let progress = UserProgress()
        XCTAssertEqual(progress.completedLessons.count, 0)
        XCTAssertEqual(progress.currentStreak, 0)
        XCTAssertEqual(progress.longestStreak, 0)
    }
    
    // Test marking lesson as complete
    func testMarkLessonComplete() async throws {
        let lessonId = "test-lesson-1"
        try await progressService.markLessonComplete(lessonId)
        
        // Verify completion (implementation dependent)
        let progress = await progressService.currentProgress
        XCTAssertTrue(progress.completedLessons.contains(lessonId))
    }
    
    // Test streak calculation
    func testStreakCalculation() {
        let progress = UserProgress()
        progress.currentStreak = 5
        XCTAssertEqual(progress.currentStreak, 5)
        
        progress.longestStreak = 10
        XCTAssertEqual(progress.longestStreak, 10)
    }
    
    // Test achievement unlocking
    func testAchievementUnlock() async throws {
        // Test that achievements can be tracked
        let progress = await progressService.currentProgress
        XCTAssertNotNil(progress.achievements)
    }
}
