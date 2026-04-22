<div align="center">

# SwiftMentor

### Master Apple Development. One Lesson at a Time.

[![Release](https://img.shields.io/github/v/release/noktirnal42/swift_mentor?color=007AFF&label=Latest%20Release)](https://github.com/noktirnal42/swift_mentor/releases/latest)
[![Platform](https://img.shields.io/badge/platform-macOS%2015.4%2B-4ECDC4?logo=apple&logoColor=white)](https://www.apple.com/macos)
[![License](https://img.shields.io/github/license/noktirnal42/swift_mentor?color=9B5DE5)](LICENSE)
[![Website](https://img.shields.io/website?url=https%3A%2F%2Fnoktirnal42.github.io%2Fswift_mentor%2F&label=Website&color=FF6B35)](https://noktirnal42.github.io/swift_mentor/)

The definitive all-in-one Apple development tutor for macOS. Learn Swift, SwiftUI, Metal, CoreML, and more — with interactive lessons, a live code playground, and progress tracking. Built with SwiftUI and a stunning glassmorphism UI.

[⬇ Download](https://github.com/noktirnal42/swift_mentor/releases/latest) · [🌐 Website](https://noktirnal42.github.io/swift_mentor/) · [📖 Wiki](https://github.com/noktirnal42/swift_mentor/wiki) · [🐛 Report Bug](https://github.com/noktirnal42/swift_mentor/issues/new) · [💡 Request Feature](https://github.com/noktirnal42/swift_mentor/discussions)

</div>

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

## Download

Get the latest release from the [Releases page](https://github.com/noktirnal42/swift_mentor/releases/latest):

- **SwiftMentor-1.2.0.dmg** (5.5 MB) — Ready-to-use macOS disk image

> **Note:** Since the app is not code-signed with a Developer ID, macOS Gatekeeper will warn on first launch. Right-click the app → Open → Open to bypass.

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
│   Views/    │────▶│   ViewModels/    │────▶│  Services/   │
│  (SwiftUI)  │     │  (Observable)    │     │  (Business)  │
└─────────────┘     └──────────────────┘     └──────┬───────┘
                                                      │
                       ┌──────────────────┐     ┌─────▼───────┐
                       │   Resources/     │     │  Database/  │
                       │ (JSON Content)   │     │  (SQLite)   │
                       └──────────────────┘     └─────────────┘
```

### Directory Structure

```
SwiftMentor/
├── App/                    # App lifecycle (AppDelegate, main)
├── Models/                 # Data models (LearningPath, Lesson, UserProgress)
├── ViewModels/             # Observable view models (AppState, DashboardVM, etc.)
├── Views/
│   ├── MainWindow/         # Content/Sidebar layout
│   ├── Dashboard/          # Home screen "Command Center"
│   ├── LearningPath/       # Path listing and navigation
│   ├── Lesson/             # Lesson detail, quizzes
│   ├── Playground/         # Code editor + execution
│   ├── Progress/           # Stats, trophies, activity
│   ├── Settings/           # App preferences
│   ├── Help/               # Onboarding flow
│   ├── AIAssistant/        # AI chat panel
│   ├── Snippets/           # Code snippet library
│   ├── Components/         # Shared UI components (GlassEffects, etc.)
│   └── Debug/              # Debug/preview views
├── Services/               # Business logic
│   ├── ContentService      # JSON content loading + fallbacks
│   ├── CodeExecutionService# Swift interpreter execution
│   ├── SyntaxHighlighting  # Splash-powered syntax coloring
│   ├── AutocompleteService # Code completion suggestions
│   ├── ProgressService     # Progress persistence (SQLite)
│   ├── AIService           # AI assistant integration
│   ├── PreviewService      # Xcode project generation
│   └── ProjectGenerator    # Scaffold Xcode projects from lessons
├── Database/
│   └── DatabaseManager     # SQLite.swift schema + CRUD
├── Extensions/             # SwiftUI/AppKit helpers
├── Resources/
│   ├── LearningPaths/      # Path definitions (paths.json)
│   ├── Lessons/            # 36 lesson content files
│   ├── Snippets/           # Code snippet collections
│   └── Assets.xcassets     # App icon + colors
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

## Documentation

| Resource | Link |
|----------|------|
| 🌐 **Website** | [noktirnal42.github.io/swift_mentor](https://noktirnal42.github.io/swift_mentor/) |
| 📖 **Wiki** | [GitHub Wiki](https://github.com/noktirnal42/swift_mentor/wiki) |
| 🏗️ **Architecture** | [Architecture.md](https://github.com/noktirnal42/swift_mentor/wiki/Architecture) |
| 🎨 **Brand Guide** | [Brand-Guide.md](https://github.com/noktirnal42/swift_mentor/wiki/Brand-Guide) |
| 📋 **Lesson Schema** | [Lesson-Schema.md](https://github.com/noktirnal42/swift_mentor/wiki/Lesson-Schema) |
| 🔧 **Technical Notes** | [Technical-Notes.md](https://github.com/noktirnal42/swift_mentor/wiki/Technical-Notes) |
| 🗺️ **Roadmap** | [Roadmap.md](https://github.com/noktirnal42/swift_mentor/wiki/Roadmap) |
| ❓ **FAQ** | [FAQ.md](https://github.com/noktirnal42/swift_mentor/wiki/FAQ) |
| 📝 **Changelog** | [Changelog.md](https://github.com/noktirnal42/swift_mentor/wiki/Changelog) |

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on how to contribute lessons, fix bugs, or add features.

---

## Known Issues

See the [GitHub Issues](https://github.com/noktirnal42/swift_mentor/issues) page for a complete list. Key issues:

- **#1** — SMCodeEditor still uses SwiftUI `TextEditor` (smart quotes leak through)
- **#6** — Splash `Theme.wwdc18()` static methods invisible under explicit module builds
- **#5** — AI Assistant panel is UI-only (no backend connected)
- **#4** — No dark/light mode toggle (always dark)

---

## Brand

SwiftMentor's brand reflects the intersection of **Apple's design philosophy** and **educational empowerment**. For the complete brand identity — colors, typography, voice & tone, visual language, and asset guidelines — see the [Brand Guide](https://github.com/noktirnal42/swift_mentor/wiki/Brand-Guide).

**Primary Colors:** Mentor Blue `#007AFF` · Deep Indigo `#5856D6` · Solar Orange `#FF6B35` · Hot Pink `#F72585` · Mint Teal `#4ECDC4` · Electric Purple `#9B5DE5`

---

## License

MIT License. See [LICENSE](LICENSE) for details.

---

## Acknowledgments

- [Splash](https://github.com/JohnSundell/Splash) by John Sundell — Swift syntax highlighting
- [SQLite.swift](https://github.com/stephencelis/SQLite.swift) by Stephen Celis — Type-safe SQLite wrapper
- Apple WWDC session content inspired the lesson material structure
