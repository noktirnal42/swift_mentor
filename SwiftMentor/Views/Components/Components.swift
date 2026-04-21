import SwiftUI

// MARK: - Lesson Card (alias for SMLessonCard used in Dashboard)

struct LessonCard: View {
    let lesson: Lesson
    @EnvironmentObject private var appState: AppState
    let onTap: (() -> Void)?
    @State private var isHovered = false

    private var progress: LessonProgress {
        appState.userProgress.lessonProgress[lesson.id] ?? LessonProgress()
    }

    private var progressValue: Double {
        progress.progress
    }

    private var isCompleted: Bool {
        progress.completed
    }

    init(lesson: Lesson, onTap: (() -> Void)? = nil) {
        self.lesson = lesson
        self.onTap = onTap
    }

    var body: some View {
        Button(action: { onTap?() }) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(alignment: .top, spacing: 16) {
                    // Icon and Difficulty Badge
                    VStack(alignment: .leading, spacing: 8) {
                        Image(systemName: lesson.icon)
                            .font(.system(size: 28))
                            .foregroundStyle(Theme.pathGradient(for: lesson.difficulty.color == "green" ? "34C759" : lesson.difficulty.color == "orange" ? "FF9500" : "FF3B30"))
                            .symbolEffect(.pulse, options: .repeating, isActive: isHovered)

                        Spacer().frame(height: 4)

                        DifficultyBadge(difficulty: lesson.difficulty)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        // Lesson Info
                        Text(lesson.title)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.primary)
                            .lineLimit(2)

                        Text(lesson.description)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .lineLimit(3)

                        Spacer().frame(height: 8)

                        // Progress and Metadata
                        HStack(spacing: 16) {
                            // Progress Ring
                            ZStack {
                                Circle()
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 3)
                                    .frame(width: 32, height: 32)

                                Circle()
                                    .trim(from: 0, to: CGFloat(min(progressValue, 1.0)))
                                    .stroke(
                                        progressColor,
                                        style: StrokeStyle(lineWidth: 3, lineCap: .round)
                                    )
                                    .frame(width: 32, height: 32)
                                    .rotationEffect(.degrees(-90))
                                    .animation(.easeInOut(duration: 0.3), value: progressValue)

                                Text("\(Int(progressValue * 100))%")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.primary)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Label("\(lesson.estimatedMinutes) min", systemImage: "clock")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)

            if lesson.order > 0 {
                Text("Lesson \(lesson.order)")
                                        .font(.system(size: 12))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }

                // Progress bar at bottom
                if !isCompleted {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .frame(width: geometry.size.width, height: 4)
                                .foregroundColor(Color.gray.opacity(0.2))
                                .cornerRadius(2)

                            Rectangle()
                                .frame(width: geometry.size.width * CGFloat(progressValue), height: 4)
                                .foregroundColor(progressColor)
                                .cornerRadius(2)
                                .animation(.easeInOut(duration: 0.3), value: progressValue)
                        }
                        .frame(height: 4)
                    }
                }
            }
            .padding(20)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .opacity(0.6)

                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(isHovered ? 0.12 : 0.06), Color.white.opacity(0.01)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    if isCompleted {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(colors: [Color.green.opacity(0.6), Color.green.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 2
                            )
                    } else {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(colors: [Color.white.opacity(isHovered ? 0.2 : 0.1), Color.white.opacity(0.02)], startPoint: .topLeading, endPoint: .bottomTrailing),
                                lineWidth: 0.5
                            )
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(isHovered ? 0.3 : 0.1), radius: isHovered ? 16 : 6, x: 0, y: isHovered ? 8 : 3)
            .scaleEffect(isHovered ? 1.01 : 1.0)
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }

    private var progressColor: Color {
        if progressValue >= 1.0 { return .green }
        else if progressValue > 0.5 { return .blue }
        else if progressValue > 0 { return .orange }
        else { return .gray }
    }
}

// MARK: - SMLessonCard (backward compat alias)

typealias SMLessonCard = LessonCard

// MARK: - Progress Ring

struct ProgressRing: View {
    let progress: Double
    let size: CGFloat
    var lineWidth: CGFloat? = nil

    private var calculatedLineWidth: CGFloat {
        lineWidth ?? size / 10
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: calculatedLineWidth)

            Circle()
                .trim(from: 0, to: CGFloat(min(progress, 1.0)))
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: calculatedLineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progress)
        }
        .frame(width: size, height: size)
    }

    private var progressColor: Color {
        if progress >= 1.0 { return .green }
        else if progress > 0.5 { return .blue }
        else if progress > 0 { return .orange }
        else { return .gray }
    }
}

// MARK: - Code Block View

struct CodeBlockView: View {
  let code: String
  let language: String
  @State private var showCopied = false
  @State private var isHovered = false
  @State private var highlightedCode: AttributedString = AttributedString(stringLiteral: "")

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Text(language.uppercased())
          .font(.caption2)
          .fontWeight(.medium)
          .foregroundColor(.secondary)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(Color.gray.opacity(0.2))
          .cornerRadius(4)

        Spacer()

        Button(action: copyToClipboard) {
          HStack(spacing: 4) {
            Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
            Text(showCopied ? "Copied!" : "Copy")
          }
          .font(.caption2)
          .foregroundColor(showCopied ? .green : .secondary)
        }
        .buttonStyle(.plain)
      }
      .padding(.horizontal, 12)
      .padding(.vertical, 8)
      .background(Color(nsColor: NSColor(red: 0.15, green: 0.15, blue: 0.17, alpha: 1.0)))

      ScrollView(.horizontal, showsIndicators: false) {
        if language.lowercased() == "swift" && !highlightedCode.characters.isEmpty {
          Text(highlightedCode)
            .font(.system(.body, design: .monospaced))
            .textSelection(.enabled)
            .padding(12)
        } else {
          Text(code)
            .font(.system(.body, design: .monospaced))
            .foregroundColor(.white)
            .textSelection(.enabled)
            .padding(12)
        }
      }
      .background(Color(nsColor: NSColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0)))
    }
    .cornerRadius(8)
    .overlay(
      RoundedRectangle(cornerRadius: 8)
        .stroke(Color.gray.opacity(isHovered ? 0.5 : 0.3), lineWidth: 1)
    )
    .onHover { hovering in
      withAnimation(.easeInOut(duration: 0.15)) {
        isHovered = hovering
      }
    }
    .onAppear {
      highlightCode()
    }
    .onChange(of: code) { _, _ in
      highlightCode()
    }
  }

  private func highlightCode() {
    if language.lowercased() == "swift" {
      highlightedCode = SyntaxHighlightingService.shared.highlightedSwiftString(for: code)
    }
  }

  private func copyToClipboard() {
    NSPasteboard.general.clearContents()
    NSPasteboard.general.setString(code, forType: .string)
    showCopied = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      showCopied = false
    }
  }
}

// MARK: - Difficulty Badge

struct DifficultyBadge: View {
    let difficulty: Lesson.Difficulty

    var body: some View {
        Text(difficulty.displayName)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(backgroundColor)
            .cornerRadius(4)
    }

    private var backgroundColor: Color {
        switch difficulty {
        case .beginner: return .green
        case .intermediate: return .orange
        case .advanced: return .red
        }
    }
}

// MARK: - Path Progress Bar

struct PathProgressBar: View {
    let currentIndex: Int
    let totalCount: Int
    let completedIndices: Set<Int>

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<totalCount, id: \.self) { index in
                Circle()
                    .fill(colorForIndex(index))
                    .frame(width: 10, height: 10)
            }
        }
    }

    private func colorForIndex(_ index: Int) -> Color {
        if completedIndices.contains(index) { return .green }
        else if index == currentIndex { return .blue }
        else { return .gray.opacity(0.3) }
    }
}

// MARK: - Loading View

struct LoadingView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
            Text(message)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Error View

struct ErrorView: View {
    let message: String
    let retryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundColor(.orange)

            Text("Something went wrong")
                .font(.headline)

            Text(message)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            if let retry = retryAction {
                Button("Try Again", action: retry)
                    .buttonStyle(.bordered)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Lesson Card") {
    LessonCard(lesson: Lesson(
        id: "test-1",
        pathId: "swift-fundamentals",
        title: "Introduction to Swift",
        description: "Learn the basics of Swift programming language",
        difficulty: .beginner,
        estimatedMinutes: 30,
        order: 1,
        sections: [],
        xcodeProject: nil
    ))
    .frame(width: 300)
    .environmentObject(AppState.shared)
}

#Preview("Progress Ring") {
    HStack(spacing: 20) {
        ProgressRing(progress: 0.25, size: 60)
        ProgressRing(progress: 0.5, size: 60)
        ProgressRing(progress: 0.75, size: 60)
        ProgressRing(progress: 1.0, size: 60)
    }
    .padding()
}

#Preview("Code Block") {
    CodeBlockView(code: """
    func greet(name: String) -> String {
        return "Hello, \\(name)!"
    }
    print(greet(name: "World"))
    """, language: "swift")
    .frame(width: 400)
}
