import XCTest
@testable import SwiftMentor

final class LearningPathTests: XCTestCase {
    
    // Test LearningPath model initialization
    func testLearningPathInitialization() {
        let path = LearningPath(
            id: "test-path",
            title: "Test Path",
            description: "A test learning path",
            icon: "book.fill",
            color: "#007AFF",
            order: 1,
            lessonCount: 5
        )
        
        XCTAssertEqual(path.id, "test-path")
        XCTAssertEqual(path.title, "Test Path")
        XCTAssertEqual(path.icon, "book.fill")
        XCTAssertEqual(path.lessonCount, 5)
    }
    
    // Test LearningPath decoding with missing optional fields
    func testLearningPathDecodingWithDefaults() {
        let json = """
        {
            "id": "test-path",
            "title": "Test Path",
            "description": "A test",
            "icon": "book.fill",
            "color": "#007AFF",
            "order": 1,
            "lessonCount": 3
        }
        """
        
        let data = Data(json.utf8)
        let decoder = JSONDecoder()
        
        do {
            let path = try decoder.decode(LearningPath.self, from: data)
            XCTAssertEqual(path.id, "test-path")
            XCTAssertEqual(path.title, "Test Path")
        } catch {
            XCTFail("Failed to decode LearningPath: \(error)")
        }
    }
    
    // Test LearningPath equality
    func testLearningPathEquality() {
        let path1 = LearningPath(
            id: "test-path",
            title: "Test Path",
            description: "A test",
            icon: "book.fill",
            color: "#007AFF",
            order: 1,
            lessonCount: 3
        )
        
        let path2 = LearningPath(
            id: "test-path",
            title: "Test Path",
            description: "A test",
            icon: "book.fill",
            color: "#007AFF",
            order: 1,
            lessonCount: 3
        )
        
        XCTAssertEqual(path1, path2)
    }
}
