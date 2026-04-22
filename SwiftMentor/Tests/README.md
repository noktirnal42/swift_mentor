# SwiftMentor Tests

This directory contains unit tests for the SwiftMentor application.

## Running Tests

### In Xcode
1. Open `SwiftMentor.xcodeproj`
2. Press `Cmd+U` or go to Product → Test
3. View results in the Test Navigator (Cmd+6)

### From Command Line
```bash
cd SwiftMentor
xcodebuild -project SwiftMentor.xcodeproj \
  -scheme SwiftMentorTests \
  -configuration Debug \
  -destination "platform=macOS" \
  test
```

## Test Structure

### Service Tests
- **ContentServiceTests** - Tests for lesson content loading and management
- **CodeExecutionServiceTests** - Tests for Swift code execution
- **UserProgressTests** - Tests for progress tracking and achievements

### Model Tests
- **LearningPathTests** - Tests for LearningPath model
- **LessonTests** - Tests for Lesson model (TODO)
- **UserProgressTests** - Tests for UserProgress model

## Adding New Tests

1. Create a new test file following the pattern: `<ServiceOrModel>Tests.swift`
2. Inherit from `XCTestCase`
3. Use `setUp()` and `tearDown()` for setup/cleanup
4. Name test methods with `test` prefix
5. Use descriptive test names that explain what's being tested

## Test Coverage Goals

- [ ] Services: 80% coverage
- [ ] Models: 90% coverage
- [ ] Views: 50% coverage (where testable)
- [ ] Overall: 60% coverage

## Mocking

For tests requiring network or file system access:
- Use `XCTExpectation` for async operations
- Create mock data in test resources
- Isolate side effects to setUp/tearDown

## Continuous Integration

Tests run automatically on:
- Every push to main/develop
- Every pull request
- Scheduled weekly runs

View results in GitHub Actions tab.
