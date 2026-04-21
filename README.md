# SwiftMentor

**The definitive all-in-one Apple development tutor for macOS.**

SwiftMentor is a native macOS application that teaches Apple development technologies through interactive lessons, a live Swift code playground, progress tracking, and AI-powered assistance. Built with SwiftUI, it features a polished glassmorphism UI and covers the full spectrum of Apple platforms and frameworks.

---

## Features

### 📚 10 Learning Paths, 36+ Lessons
- **Swift Fundamentals** — Variables, types, control flow, functions, closures
- **SwiftUI Essentials** — Declarative UI, layout, state management, navigation
- **Advanced Swift** — Generics, concurrency, error handling, protocols
- **Metal Basics** — GPU programming, shaders, rendering pipeline
- **CoreML Introduction** — On-device ML, Vision framework, NLP
- **Xcode Mastery** — Debugging, Instruments, build settings, distribution
- **SwiftData Essentials** — @Model macro, queries, relationships, migrations
- **WidgetKit Basics** — Timeline providers, configurations, interactive widgets
- **Combine Framework** — Publishers, subscribers, operators, real-world patterns
- **App Store Distribution** — Provisioning, TestFlight, App Review, analytics

### 💻 Live Code Playground
- Execute real Swift code using the system `/usr/bin/swift` interpreter
- Syntax highlighting powered by [Splash](https://github.com/JohnSundell/Splash)
- Snippet quick-insert bar with common Swift patterns
- Execution history panel with replay
- Smart-quote prevention (no more curly quotes breaking your code!)

### 🎯 Progress & Achievements
- Track completion across all learning paths
- 12 achievement badges (First Steps, Swift Explorer, SwiftUI Master, etc.)
- Daily streak tracking with visual progress ring
- Daily goal tracker on the dashboard

### 🔍 Smart Search
- Full-text search across all lesson content
- Recent search history
- Auto-suggestions
- Browse topics by category

### 🎨 Modern UI
- Glassmorphism design with `NSVisualEffectView` materials
- Custom gradient text effects and hover animations
- Shimmer loading placeholders
- Fade-in transitions and smooth animations
- Adaptive dark theme

---

## Requirements

- **macOS** 15.4 (Sequoia) or later
- **Xcode** 26.4+ (for building from source)
- **XcodeGen** — `brew install xcodegen`

---

## Building from Source

1. **Clone the repository:**
   ```bash
   git clone https://github.com/noktirnal42/swift_mentor.git
   cd swift_mentor/SwiftMentor
   ```

2. **Generate the Xcode project:**
   ```bash
   xcodegen generate
   ```

3. **Open in Xcode:**
   ```bash
   open SwiftMentor.xcodeproj
   ```

4. **Build & Run** (⌘R)

> **Note:** The first build will resolve Swift Package Manager dependencies (SQLite.swift and Splash). This may take a few minutes.

---

## Architecture

SwiftMentor follows the **MVVM** (Model-View-ViewModel) pattern:

```
┌─────────────┐     ┌──────────────────┐     ┌──────────────┐
│   Views/     │────▶│   ViewModels/    │────▶│  Services/   │
│  (SwiftUI)   │     │  (Observable)    │     │  (Business)  │
└─────────────┘     └──────────────────┘     └──────┬───────┘
                                                     │
                    ┌──────────────────┐     ┌───────▼───────┐
                    │   Resources/     │     │   Database/   │
                    │  (JSON Content)  │     │  (SQLite)     │
                    └──────────────────┘     └───────────────┘
```

### Directory Structure

```
SwiftMentor/
├── App/                          # App lifecycle (AppDelegate, main)
├── Models/                       # Data models (LearningPath, Lesson, UserProgress)
├── ViewModels/                   # Observable view models (AppState, DashboardVM, etc.)
├── Views/
│   ├── MainWindow/               # Content/Sidebar layout
│   ├── Dashboard/                # Home screen "Command Center"
│   ├── LearningPath/             # Path listing and navigation
│   ├── Lesson/                   # Lesson detail, quizzes
│   ├── Playground/               # Code editor + execution
│   ├── Progress/                 # Stats, trophies, activity
│   ├── Settings/                 # App preferences
│   ├── Help/                     # Onboarding flow
│   ├── AIAssistant/              # AI chat panel
│   ├── Snippets/                 # Code snippet library
│   ├── Components/               # Shared UI components (GlassEffects, etc.)
│   └── Debug/                    # Debug/preview views
├── Services/                     # Business logic
│   ├── ContentService.swift      # JSON content loading + fallbacks
│   ├── CodeExecutionService.swift# Swift interpreter execution
│   ├── SyntaxHighlightingService # Splash-powered syntax coloring
│   ├── AutocompleteService.swift # Code completion suggestions
│   ├── ProgressService.swift     # Progress persistence (SQLite)
│   ├── AIService.swift           # AI assistant integration
│   ├── PreviewService.swift      # Xcode project generation
│   └── ProjectGeneratorService   # Scaffold Xcode projects from lessons
├── Database/
│   └── DatabaseManager.swift     # SQLite.swift schema + CRUD
├── Extensions/                   # SwiftUI/AppKit helpers
├── Resources/
│   ├── LearningPaths/paths.json  # Path definitions
│   ├── Lessons/*.json            # 36 lesson content files
│   ├── Snippets/*.json           # Code snippet collections
│   └── Assets.xcassets           # App icon + colors
└── Supporting/
    ├── Info.plist
    └── SwiftMentor.entitlements  # Sandbox disabled for Process execution
```

### Key Design Decisions

| Decision | Rationale |
|----------|-----------|
| **App Sandbox disabled** | Required to spawn `/usr/bin/swift` for live code execution |
| `CODE_SIGN_INJECT_BASE_ENTITLEMENTS: NO` | Prevents Xcode from auto-injecting sandbox entitlement |
| `PlainTextEditor` (NSViewRepresentable) | SwiftUI `TextEditor` inserts smart quotes that break Swift code |
| `EXPLICIT_MODULE_BUILD: NO` | Splash 0.16.0's `Theme` struct is inside `#if !os(Linux)` which is invisible under explicit module builds |
| `@StateObject` (not `@State`) for ViewModels | `@State` never subscribes to `@Published` on reference types |
| Content loaded from JSON with hardcoded fallback | Ensures app works even if bundle resources aren't found |

---

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| [SQLite.swift](https://github.com/stephencelis/SQLite.swift) | 0.15.3 | Progress tracking database |
| [Splash](https://github.com/JohnSundell/Splash) | 0.16.0 | Swift syntax highlighting |

Both are resolved via Swift Package Manager automatically.

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| ⌘R | Run code in playground |
| ⌘S | Save current progress |
| ⌘F | Search lessons |
| ⌘, | Open settings |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute lessons, fix bugs, or add features.

---

## Known Issues

See the [GitHub Issues](https://github.com/noktirnal42/swift_mentor/issues) page for a complete list. Key issues:

- **#1** — SMCodeEditor still uses SwiftUI `TextEditor` (smart quotes leak through)
- **#6** — Splash `Theme.wwdc18()` static methods invisible under explicit module builds
- **#7** — AI Assistant panel is UI-only (no backend connected)
- **#8** — No dark/light mode toggle (always dark)

---

## License

MIT License. See [LICENSE](LICENSE) for details.

---

## Acknowledgments

- [Splash](https://github.com/JohnSundell/Splash) by John Sundell — Swift syntax highlighting
- [SQLite.swift](https://github.com/stephencelis/SQLite.swift) by Stephen Celis — Type-safe SQLite wrapper
- Apple WWDC session content inspired the lesson material structure
