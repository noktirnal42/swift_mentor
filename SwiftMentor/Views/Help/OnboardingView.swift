import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedTab: HelpTab = .gettingStarted

    enum HelpTab: String, CaseIterable, Identifiable {
        case gettingStarted = "Getting Started"
        case playground = "Playground"
        case learningPaths = "Learning Paths"
        case keyboardShortcuts = "Shortcuts"
        case tips = "Tips & FAQ"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .gettingStarted: return "star.fill"
            case .playground: return "terminal.fill"
            case .learningPaths: return "book.fill"
            case .keyboardShortcuts: return "keyboard"
            case .tips: return "lightbulb.fill"
            }
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Tab bar
            tabBar

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    switch selectedTab {
                    case .gettingStarted:
                        gettingStartedContent
                    case .playground:
                        playgroundContent
                    case .learningPaths:
                        learningPathsContent
                    case .keyboardShortcuts:
                        shortcutsContent
                    case .tips:
                        tipsContent
                    }
                }
                .padding(32)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color(nsColor: .windowBackgroundColor))
        .navigationTitle("Help & Onboarding")
    }

    // MARK: - Tab Bar

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(HelpTab.allCases) { tab in
                Button(action: { selectedTab = tab }) {
                    HStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .font(.caption)
                        Text(tab.rawValue)
                            .font(.subheadline)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(selectedTab == tab ? Color.accentColor.opacity(0.15) : Color.clear)
                    .foregroundColor(selectedTab == tab ? .accentColor : .secondary)
                    .cornerRadius(6)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }

    // MARK: - Getting Started

    private var gettingStartedContent: some View {
        VStack(alignment: .leading, spacing: 28) {
            // Hero section
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    Image(systemName: "swift")
                        .font(.system(size: 48))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange, .red],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome to SwiftMentor")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text("Your companion for learning Apple development technologies")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                }
            }

            Divider()

            // What is SwiftMentor?
            HelpSection(
                title: "What is SwiftMentor?",
                icon: "info.circle.fill",
                color: .blue
            ) {
                Text("SwiftMentor is an interactive learning environment for Apple's development ecosystem. Whether you're brand new to programming or coming from another language, SwiftMentor guides you through Swift, SwiftUI, Metal, CoreML, and more with hands-on lessons and a live code playground.")
            }

            // Quick Start Steps
            HelpSection(
                title: "Quick Start — Your First 5 Minutes",
                icon: "bolt.fill",
                color: .orange
            ) {
                VStack(alignment: .leading, spacing: 16) {
                    StepRow(number: 1, title: "Pick a Learning Path",
                            description: "Click \"Learning Paths\" in the sidebar. Choose \"Swift Fundamentals\" if you're new to programming, or any path that matches your interest.")
                    StepRow(number: 2, title: "Read the Lesson",
                            description: "Each lesson contains explanations, code examples, and quizzes. Read through the content at your own pace.")
                    StepRow(number: 3, title: "Try the Code",
                            description: "Click \"Go to Playground\" inside any lesson. The starter code loads automatically — modify it, experiment, and learn by doing.")
                    StepRow(number: 4, title: "Run Your Code",
                            description: "Press the Play button (or \u{2318}R) to execute your code. Output appears instantly in the console panel below the editor.")
                    StepRow(number: 5, title: "Track Your Progress",
                            description: "Completed lessons are tracked automatically. Check the Progress tab to see how far you've come.")
                }
            }

            // Navigate the app
            HelpSection(
                title: "Navigating the App",
                icon: "compass.fill",
                color: .green
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    NavRow(icon: "house.fill", name: "Dashboard", description: "Your home base — see recent lessons, stats, and learning path overview.")
                    NavRow(icon: "book.fill", name: "Learning Paths", description: "Browse and select structured curricula for different technologies.")
                    NavRow(icon: "terminal.fill", name: "Playground", description: "Write and run Swift code freely. Loaded with a lesson's starter code when you come from a lesson, or blank for freeform experimentation.")
                    NavRow(icon: "doc.text.fill", name: "Snippets", description: "A library of reusable code snippets you can copy into the playground or your own projects.")
                    NavRow(icon: "chart.bar.fill", name: "Progress", description: "Track completed lessons, streaks, and time spent learning.")
                    NavRow(icon: "brain", name: "AI Assistant", description: "Ask questions about Swift, debugging, or any lesson topic.")
                }
            }

            // Go to playground button
            HStack {
                Spacer()
                Button(action: { appState.selectedSection = .playground }) {
                    Label("Open Playground", systemImage: "terminal.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button(action: { appState.selectedSection = .learningPaths }) {
                    Label("Browse Learning Paths", systemImage: "book.fill")
                        .font(.headline)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                Spacer()
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Playground Help

    private var playgroundContent: some View {
        VStack(alignment: .leading, spacing: 28) {
            HelpSection(
                title: "The Code Playground",
                icon: "terminal.fill",
                color: .purple
            ) {
                Text("The playground is where you write and execute Swift code. It uses the Swift interpreter (\u{2F}usr\u{2F}bin\u{2F}swift) running locally on your Mac, so you have full access to Foundation, GCD, and the standard library — just like a real Swift script.")
            }

            HelpSection(
                title: "How to Run Code",
                icon: "play.fill",
                color: .green
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("There are three ways to execute your code:")
                    BulletRow("Press \u{2318}R (Command+R) on your keyboard")
                    BulletRow("Click the Play button (\u{25B6}) in the toolbar")
                    BulletRow("Use the menu: Editor \u{2192} Run Code")
                    Text("Output appears in the console panel below the editor. Execution typically takes 1\u{2013}3 seconds for the Swift interpreter to start up and run your code.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            HelpSection(
                title: "Writing Code",
                icon: "pencil.and.outline",
                color: .blue
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("The editor is a plain-text code editor with line numbers. A few things to know:")
                    BulletRow("Smart quotes and dashes are disabled — only straight quotes (\") and regular dashes (-) are inserted, which Swift requires.")
                    BulletRow("Auto-correct and spell checking are off so your code isn't \"corrected\" behind your back.")
                    BulletRow("Use \u{2325}\u{21E5} (Option+Tab) or regular Tab for indentation.")
                    BulletRow("The editor supports Undo/Redo (\u{2318}Z / \u{2318}\u{21E7}Z).")
                }
            }

            HelpSection(
                title: "What You Can Run",
                icon: "checkmark.circle.fill",
                color: .green
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("The playground runs standard Swift scripts. You can use:")
                    BulletRow("All Swift language features: variables, functions, classes, structs, enums, protocols, extensions, generics")
                    BulletRow("Foundation framework: String, Date, URL, JSONEncoder, URLSession, FileManager, etc.")
                    BulletRow("Concurrency: async/await, Task, TaskGroup")
                    BulletRow("GCD: DispatchQueue, DispatchGroup")
                    BulletRow("Standard library: collections, algorithms, optionals, error handling")
                }
            }

            HelpSection(
                title: "What You Cannot Run",
                icon: "xmark.circle.fill",
                color: .red
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Since this is a Swift interpreter (not a full Xcode project), some things are unavailable:")
                    BulletRow("SwiftUI views — these require an Xcode project with a SwiftUI app lifecycle")
                    BulletRow("UIKit / AppKit — these require a compiled application bundle")
                    BulletRow("Metal, CoreML, ARKit — these need a compiled app with proper entitlements")
                    BulletRow("Import statements for frameworks not available to the Swift REPL")
                    Text("For these technologies, use the \"Open in Xcode\" feature (when available) to generate a starter project.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            HelpSection(
                title: "Common Errors",
                icon: "exclamationmark.triangle.fill",
                color: .orange
            ) {
                VStack(alignment: .leading, spacing: 14) {
                    ErrorRow(title: "\"error: unable to spawn process\"",
                            description: "The Swift interpreter wasn't found. Make sure Xcode Command Line Tools are installed: run \"xcode-select --install\" in Terminal.")
                    ErrorRow(title: "\"error: use of unresolved identifier\"",
                            description: "You're referencing a variable or function that hasn't been defined. Check for typos and make sure it's declared earlier in the file.")
                    ErrorRow(title: "\"error: expected expression\"",
                            description: "Usually a syntax error — check for missing braces, parentheses, or commas. Also verify you're using straight quotes, not curly quotes.")
                    ErrorRow(title: "No output appears",
                            description: "Make sure you're using print() to see results. Swift doesn't automatically display values like a REPL — you need explicit print() calls.")
                }
            }
        }
    }

    // MARK: - Learning Paths Help

    private var learningPathsContent: some View {
        VStack(alignment: .leading, spacing: 28) {
            HelpSection(
                title: "Learning Paths",
                icon: "book.fill",
                color: .blue
            ) {
                Text("Learning Paths are structured curricula that take you from beginner to proficient in a specific Apple technology. Each path contains a sequence of lessons that build on each other.")
            }

            HelpSection(
                title: "Available Paths",
                icon: "list.bullet.rectangle.fill",
                color: .purple
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    PathInfoRow(icon: "swift", color: .orange, name: "Swift Fundamentals",
                                description: "Variables, types, control flow, functions, collections, optionals, error handling — the foundations of the Swift language.")
                    PathInfoRow(icon: "rectangle.3.group.fill", color: .blue, name: "SwiftUI Basics",
                                description: "Declarative UI, views, modifiers, state management, navigation, lists, and forms.")
                    PathInfoRow(icon: "cube.transparent", color: .cyan, name: "Metal & GPU Programming",
                                description: "Shaders, compute pipelines, rendering, and parallel processing on the GPU.")
                    PathInfoRow(icon: "brain.head.profile", color: .purple, name: "CoreML & AI",
                                description: "Machine learning models, on-device inference, Create ML, and integrating AI into your apps.")
                    PathInfoRow(icon: "arrow.triangle.branch", color: .green, name: "Advanced Swift",
                                description: "Generics, protocols, concurrency, memory management, and performance optimization.")
                }
            }

            HelpSection(
                title: "How Lessons Work",
                icon: "doc.richtext.fill",
                color: .green
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Each lesson contains:")
                    BulletRow("Explanations — written descriptions of the concept with examples")
                    BulletRow("Code examples — copy them into the playground to experiment")
                    BulletRow("Starter code — pre-loaded in the playground when you click \"Go to Playground\"")
                    BulletRow("Quizzes — test your understanding (when available)")
                    BulletRow("Xcode projects — some lessons include a generated starter project you can open in Xcode")
                }
            }

            HelpSection(
                title: "Recommended Approach",
                icon: "map.fill",
                color: .orange
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    StepRow(number: 1, title: "Start with Swift Fundamentals",
                            description: "Even if you know another language, Swift has unique features (optionals, value types, protocol-oriented design) worth learning systematically.")
                    StepRow(number: 2, title: "Follow the order",
                            description: "Lessons in each path are ordered by dependency. Skipping ahead may leave knowledge gaps.")
                    StepRow(number: 3, title: "Experiment in the playground",
                            description: "Don't just read the code — modify it, break it, fix it. Active learning beats passive reading every time.")
                    StepRow(number: 4, title: "Use the AI Assistant",
                            description: "Stuck on a concept? Ask the AI assistant for a different explanation or a simpler example.")
                    StepRow(number: 5, title: "Build your own projects",
                            description: "Once you've completed a path, try building something from scratch. That's where real learning happens.")
                }
            }
        }
    }

    // MARK: - Keyboard Shortcuts

    private var shortcutsContent: some View {
        VStack(alignment: .leading, spacing: 28) {
            HelpSection(
                title: "Keyboard Shortcuts",
                icon: "keyboard",
                color: .blue
            ) {
                Text("Speed up your workflow with these shortcuts:")
            }

            VStack(alignment: .leading, spacing: 12) {
                ShortcutGroup(title: "Playground", shortcuts: [
                    ("\u{2318}R", "Run code"),
                    ("\u{2318}S", "Save snippet (copy to clipboard)"),
                    ("\u{2318}Z", "Undo"),
                    ("\u{2318}\u{21E7}Z", "Redo"),
                    ("\u{2318}F", "Find in editor"),
                    ("\u{2318}G", "Find next"),
                    ("\u{21E7}\u{2318}G", "Find previous"),
                ])

                ShortcutGroup(title: "Navigation", shortcuts: [
                    ("\u{2318}1", "Dashboard"),
                    ("\u{2318}2", "Learning Paths"),
                    ("\u{2318}3", "Playground"),
                    ("\u{2318}4", "Snippets"),
                    ("\u{2318}5", "Progress"),
                    ("\u{2318},", "Settings"),
                    ("\u{2325}\u{2318}S", "Toggle sidebar"),
                ])

                ShortcutGroup(title: "General", shortcuts: [
                    ("\u{2318}K", "Search lessons"),
                    ("\u{21E7}\u{2318}A", "AI Assistant"),
                    ("\u{2318},", "Preferences / Settings"),
                    ("\u{2318}Q", "Quit SwiftMentor"),
                ])
            }
        }
    }

    // MARK: - Tips & FAQ

    private var tipsContent: some View {
        VStack(alignment: .leading, spacing: 28) {
            HelpSection(
                title: "Tips for New Programmers",
                icon: "lightbulb.fill",
                color: .yellow
            ) {
                VStack(alignment: .leading, spacing: 14) {
                    TipRow(title: "Read error messages carefully",
                           description: "Swift's compiler errors are remarkably helpful. They usually tell you exactly what's wrong and where. Don't panic when you see red — read the message.")
                    TipRow(title: "\"I don't understand\" is normal",
                           description: "Programming concepts often click on the second or third encounter. If something doesn't make sense, continue to the next lesson and come back later.")
                    TipRow(title: "Type it out, don't copy-paste",
                           description: "Muscle memory matters. Typing code yourself builds familiarity with syntax, even if it feels slower at first.")
                    TipRow(title: "Use print() liberally",
                           description: "Not sure what a variable holds? Print it. Not sure which branch of an if-statement runs? Add a print. Printing is the programmer's oldest debugging tool.")
                    TipRow(title: "Break things on purpose",
                           description: "Change a keyword, delete a line, swap two arguments — see what breaks and what the error says. Understanding errors is as important as writing correct code.")
                }
            }

            HelpSection(
                title: "Frequently Asked Questions",
                icon: "questionmark.circle.fill",
                color: .blue
            ) {
                VStack(alignment: .leading, spacing: 18) {
                    FAQRow(question: "Do I need Xcode installed?",
                           answer: "Yes — the playground uses /usr/bin/swift which is installed with Xcode's Command Line Tools. Install Xcode from the Mac App Store, then run \"xcode-select --install\" in Terminal.")
                    FAQRow(question: "Can I use SwiftMentor without an internet connection?",
                           answer: "Yes. All lesson content is bundled with the app. The only feature that requires internet is the AI Assistant (if connected to a remote AI service).")
                    FAQRow(question: "Is my progress saved?",
                           answer: "Yes. Progress is saved locally in a SQLite database. Completed lessons, time spent, and streaks are all persisted between sessions.")
                    FAQRow(question: "Why does the first run take a few seconds?",
                           answer: "The Swift interpreter (/usr/bin/swift) needs a moment to initialize. Subsequent runs within the same session may be slightly faster due to OS caching.")
                    FAQRow(question: "Can I write SwiftUI code in the playground?",
                           answer: "The playground runs Swift scripts via the interpreter, so SwiftUI views won't render visually here. However, you can test SwiftUI data models, view model logic, and utility functions. For full SwiftUI projects, use the \"Open in Xcode\" feature when a lesson provides one.")
                    FAQRow(question: "How do I reset my progress?",
                           answer: "Go to Settings and use the \"Reset Progress\" option. This will clear all completed lesson records and streak data.")
                }
            }

            HelpSection(
                title: "Getting More Help",
                icon: "bubble.left.and.bubble.right.fill",
                color: .green
            ) {
                VStack(alignment: .leading, spacing: 10) {
                    BulletRow("Use the **AI Assistant** (sidebar \u{2192} AI Assistant) to ask questions about any concept")
                    BulletRow("Open **Apple Documentation** (sidebar \u{2192} Quick Links \u{2192} Documentation)")
                    BulletRow("Visit **developer.apple.com** for official guides, videos, and sample code")
                    BulletRow("Search the **Swift Forums** at forums.swift.org for community answers")
                }
            }
        }
    }
}

// MARK: - Helper Subviews

private struct HelpSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            content()
                .font(.body)
                .foregroundColor(.primary.opacity(0.85))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }
}

private struct StepRow: View {
    let number: Int
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text("\(number)")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 28, height: 28)
                .background(Color.accentColor)
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private struct NavRow: View {
    let icon: String
    let name: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private struct BulletRow: View {
    let text: LocalizedStringKey

    init(_ text: LocalizedStringKey) {
        self.text = text
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text("\u{2022}")
                .foregroundColor(.accentColor)
                .font(.body.weight(.bold))
            Text(text)
                .font(.body)
        }
    }
}

private struct ErrorRow: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.red)
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

private struct PathInfoRow: View {
    let icon: String
    let color: Color
    let name: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(name)
                    .font(.subheadline.weight(.semibold))
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private struct ShortcutGroup: View {
    let title: String
    let shortcuts: [(key: String, action: String)]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 6) {
                ForEach(shortcuts, id: \.action) { shortcut in
                    HStack(spacing: 12) {
                        Text(shortcut.key)
                            .font(.system(.caption, design: .monospaced, weight: .medium))
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(nsColor: NSColor(red: 0.2, green: 0.2, blue: 0.22, alpha: 1.0)))
                            .cornerRadius(4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.gray.opacity(0.4), lineWidth: 0.5)
                            )

                        Text(shortcut.action)
                            .font(.subheadline)

                        Spacer()
                    }
                }
            }
            .padding(16)
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
    }
}

private struct TipRow: View {
    let title: String
    let description: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

private struct FAQRow: View {
    let question: String
    let answer: String

    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Button(action: { withAnimation(.easeInOut(duration: 0.2)) { isExpanded.toggle() } }) {
                HStack(spacing: 8) {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(width: 12)
                    Text(question)
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.leading)
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            if isExpanded {
                Text(answer)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 20)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}

#Preview {
    OnboardingView()
        .environmentObject(AppState.shared)
        .frame(width: 800, height: 600)
}
