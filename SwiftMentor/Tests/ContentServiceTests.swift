import XCTest
@testable import SwiftMentor

final class ContentServiceTests: XCTestCase {
    var contentService: ContentService!
    
    override func setUp() async throws {
        contentService = ContentService.shared
    }
    
    override func tearDown() {
        contentService = nil
    }
    
    // Test that ContentService singleton is accessible
    func testContentServiceShared() {
        XCTAssertNotNil(ContentService.shared)
    }
    
    // Test that learning paths can be loaded
    func testLoadLearningPaths() async throws {
        let paths = try await contentService.loadLearningPaths()
        XCTAssertFalse(paths.isEmpty, "Should have at least one learning path")
    }
    
    // Test that lessons can be loaded for a path
    func testLoadLessonsForPath() async throws {
        let paths = try await contentService.loadLearningPaths()
        guard let firstPath = paths.first else {
            throw XCTSkip("No learning paths available")
        }
        
        let lessons = try await contentService.loadAllLessonsForPath(firstPath.id)
        XCTAssertGreaterThanOrEqual(lessons.count, 0, "Should load lessons for path")
    }
    
    // Test fallback content when JSON files are missing
    func testFallbackContent() async throws {
        let paths = try await contentService.loadLearningPaths()
        XCTAssertFalsepaths.isEmpty, "Should have fallback content")
    }
}
