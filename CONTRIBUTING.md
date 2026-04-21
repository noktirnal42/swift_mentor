# Contributing to SwiftMentor

Thank you for your interest in contributing! This guide covers everything you need to get started.

---

## Quick Start

1. Fork the repository
2. Clone your fork: `git clone https://github.com/YOUR_USERNAME/swift_mentor.git`
3. Install [XcodeGen](https://github.com/yonaskolb/XcodeGen): `brew install xcodegen`
4. Open `SwiftMentor/` and run `xcodegen generate`
5. Open `SwiftMentor.xcodeproj` in Xcode 26+
6. Build and run (⌘R)

---

## How to Contribute

### 📝 Add New Lessons

Lessons are JSON files in `SwiftMentor/Resources/Lessons/`. Each lesson file follows this schema:

```json
{
  "id": "your-path-1",
  "pathId": "your-path",
  "title": "Lesson Title",
  "description": "Brief description of the lesson",
  "order": 1,
  "type": "lesson",
  "sections": [
    {
      "title": "Section Title",
      "content": "Markdown-like text content. Supports **bold**, `code`, and [links](url).",
      "codeExample": "let example = \"Hello, World!\"",
      "type": "theory"
    },
    {
      "title": "Try It Yourself",
      "content": "Instructions for the exercise",
      "codeExample": "// Write your code here",
      "type": "exercise"
    },
    {
      "title": "Quick Check",
      "type": "quiz",
      "questions": [
        {
          "question": "What does `let` declare in Swift?",
          "options": ["A variable", "A constant", "A function", "A class"],
          "correctIndex": 1,
          "explanation": "`let` declares a constant value that cannot be reassigned."
        }
      ]
    }
  ]
}
```

**Steps to add a lesson:**

1. Create a new JSON file: `SwiftMentor/Resources/Lessons/your-path-N.json`
2. Add a lesson reference to `SwiftMentor/Resources/LearningPaths/paths.json`
3. Add a fallback entry in `ContentService.swift`'s `hardcodedFallbackPaths` array
4. Run `xcodegen generate` to pick up the new file
5. Test in the app

### 🎨 Improve the UI

The glassmorphism components live in `Views/Components/GlassEffects.swift`. Key components:

- `GlassCard` — Floating card with vibrancy material
- `StatGlassCard` — Dashboard stat cards
- `GradientText` — Text with gradient fill
- `ShimmerEffect` — Loading shimmer animation
- `HoverEffect` — Hover scaling for interactive elements

### 🐛 Fix Bugs

Check the [GitHub Issues](https://github.com/noktirnal42/swift_mentor/issues) page for open bug reports. Comment on an issue to claim it.

### 🔧 Add Features

Feature requests are tracked as GitHub Issues with the `enhancement` label. Large features should be discussed in an issue before starting work.

---

## Code Style

- **Language:** Swift 5.9
- **Pattern:** MVVM (Model-View-ViewModel)
- **Views:** SwiftUI with AppKit interop where needed (`NSViewRepresentable`)
- **Naming:** PascalCase for types, camelCase for properties/methods
- **Comments:** Use `// MARK: -` sections to organize files
- **Debug logging:** Gate all `print()` behind `#if DEBUG`

### ViewModels

- Always use `@StateObject` (never `@State`) for ViewModel declarations in views
- ViewModels should be `@MainActor` if they update UI
- Use `@Published` for reactive state properties

### Services

- Use the singleton pattern (`static let shared`) for app-wide services
- Services are `final class` unless testing requires otherwise

---

## Project Generation

This project uses [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate the Xcode project from `project.yml`. **Never edit the `.xcodeproj` directly** — changes will be overwritten.

After adding new Swift files or resources:
```bash
cd SwiftMentor && xcodegen generate
```

---

## Testing

Currently, SwiftMentor does not have automated tests. This is a known gap — see GitHub Issues. Contributions adding unit tests for Services and Models are especially welcome.

Manual testing checklist:
- [ ] App launches without crashes
- [ ] All 10 learning paths load
- [ ] Lessons display correctly with sections and code blocks
- [ ] Code playground executes Swift code
- [ ] Progress saves between sessions
- [ ] Search returns results across lesson content
- [ ] Quiz questions work with correct answer validation

---

## Pull Request Process

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Make your changes
3. Ensure the project builds: `xcodegen generate && xcodebuild build`
4. Update documentation if needed
5. Submit a PR with a clear description of changes
6. Link any related GitHub Issues

---

## Code of Conduct

Be respectful, constructive, and inclusive. We're all here to learn and teach.
