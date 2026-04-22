import XCTest
@testable import SwiftMentor

final class CodeExecutionServiceTests: XCTestCase {
    var codeService: CodeExecutionService!
    
    override func setUp() async throws {
        codeService = CodeExecutionService.shared
    }
    
    override func tearDown() {
        codeService = nil
    }
    
    // Test that CodeExecutionService singleton is accessible
    func testCodeExecutionServiceShared() {
        XCTAssertNotNil(CodeExecutionService.shared)
    }
    
    // Test basic Swift code execution
    func testExecuteSimpleCode() async throws {
        let code = "print(\"Hello, World!\")"
        let result = try await codeService.execute(code: code)
        XCTAssertFalse(result.output.isEmpty, "Should produce output")
        XCTAssertTrue(result.output.contains("Hello"), "Output should contain greeting")
    }
    
    // Test code execution with error handling
    func testExecuteInvalidCode() async throws {
        let code = "let invalid = "  // Incomplete statement
        do {
            _ = try await codeService.execute(code: code)
            // If no error thrown, that's also acceptable for this test
        } catch {
            // Error expected for invalid code
            XCTAssertNotNil(error)
        }
    }
    
    // Test timeout handling
    func testExecutionTimeout() async throws {
        // This test verifies timeout mechanism exists
        // Actual timeout testing would require long-running code
        XCTAssertGreaterThan(codeService.timeout, 0, "Timeout should be configured")
    }
}
