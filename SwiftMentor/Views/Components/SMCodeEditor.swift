import SwiftUI
import AppKit
import Splash

// MARK: - SMCodeEditor (Enhanced Code Editor with Syntax Highlighting)

struct SMCodeEditor: View {
    @Binding var code: String
    @Binding var cursorPosition: Int
    let isEditable: Bool
    let language: String
    let showLineNumbers: Bool
    let showAutocomplete: Bool
    let completions: [AutocompleteCompletion]
    let onCompletionSelect: (AutocompleteCompletion) -> Void
    let onRunCode: () -> Void
    let onErrorHighlight: ([CodeError]) -> Void

    @State private var attributedCode: NSAttributedString = NSAttributedString(string: "")
    @State private var scrollOffset: CGFloat = 0
    @State private var lineCount: Int = 1
    @State private var errors: [CodeError] = []
    @State private var isHighlighting: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Editor Toolbar
            HStack {
                Text("\(language.uppercased()) Editor")
                    .font(.system(.caption, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Spacer()

                if isEditable {
                    Button(action: {
                        Task { await highlightCode() }
                    }) {
                        Image(systemName: isHighlighting ? "gobackward" : "sparkles")
                            .font(.caption)
                    }
                    .help("Highlight Syntax")
                    .disabled(isHighlighting)
                }

                Button(action: onRunCode) {
                    Image(systemName: "play.fill")
                        .font(.caption)
                }
                .help("Run Code")
                .disabled(!isEditable)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Main Editor Content
            HStack(alignment: .top, spacing: 0) {
                // Line Numbers
                if showLineNumbers {
                    lineNumbersView
                        .frame(width: 50)
                        .background(Color(nsColor: .controlBackgroundColor))
                }

                // Code Editor
                ZStack(alignment: .topLeading) {
                    // Background
                    Color(nsColor: NSColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0))

                    // Text Content
                    ScrollView(.vertical, showsIndicators: true) {
                        TextEditor(text: $code)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white)
                            .scrollContentBackground(.hidden)
                            .background(Color.clear)
                            .frame(minHeight: 300)
                            .onChange(of: code) { _, newValue in
                                updateLineCount()
                                cursorPosition = newValue.count
                                if isEditable && !isHighlighting {
                                    Task { await highlightCode() }
                                }
                            }
                    }

                    // Error Highlights
                    ForEach(errors) { error in
                        errorHighlightView(for: error)
                    }

                    // Autocomplete Popup
                    if showAutocomplete && !completions.isEmpty && !code.isEmpty {
                        autocompletePopup
                            .offset(x: 60, y: 50 + scrollOffset)
                    }
                }
            }
        }
        .background(Color(nsColor: NSColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0)))
        .onAppear {
            updateLineCount()
            Task { await highlightCode() }
        }
        .onChange(of: language) { _, newValue in
            Task { await highlightCode() }
        }
    }

    private var lineNumbersView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .trailing, spacing: 0) {
                ForEach(1...max(lineCount, 1), id: \.self) { lineNum in
                    Text("\(lineNum)")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.gray.opacity(0.6))
                        .frame(height: 21)
                }
            }
            .padding(.top, 8)
        }
        .background(Color(nsColor: NSColor(red: 0.08, green: 0.08, blue: 0.08, alpha: 1.0)))
    }

    private var autocompletePopup: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(completions.enumerated()), id: \.element.id) { index, completion in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(completion.text)
                            .font(.system(.body, design: .monospaced))
                            .foregroundColor(.white)
                        Text(completion.detail)
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    completionTypeIcon(completion.type)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(index == 0 ? Color.blue.opacity(0.3) : Color.clear)
                .contentShape(Rectangle())
                .onTapGesture {
                    onCompletionSelect(completion)
                }

                if index < completions.count - 1 {
                    Divider()
                        .background(Color.gray.opacity(0.3))
                }
            }
        }
        .frame(width: 300)
        .background(Color(nsColor: NSColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0)))
        .cornerRadius(8)
        .shadow(color: .black.opacity(0.3), radius: 10)
    }

    @ViewBuilder
    private func completionTypeIcon(_ type: AutocompleteCompletion.CompletionType) -> some View {
        switch type {
        case .keyword:
            Image(systemName: "k")
                .foregroundColor(.purple)
                .font(.caption)
        case .type:
            Image(systemName: "T")
                .foregroundColor(.blue)
                .font(.caption)
        case .modifier:
            Image(systemName: "m")
                .foregroundColor(.green)
                .font(.caption)
        case .snippet:
            Image(systemName: "S")
                .foregroundColor(.orange)
                .font(.caption)
        case .method:
            Image(systemName: "f")
                .foregroundColor(.cyan)
                .font(.caption)
        }
    }

    private func updateLineCount() {
        lineCount = code.components(separatedBy: "\n").count
    }

    private func errorHighlightView(for error: CodeError) -> some View {
        // Simplified error highlight - in a real implementation, this would be more precise
        return EmptyView()
    }

  private func highlightCode() async {
    guard isEditable else { return }

    isHighlighting = true

    do {
      // Small delay to debounce rapid typing
      try await Task.sleep(nanoseconds: 50_000_000) // 0.05 second

      // Use Splash for real syntax highlighting
      attributedCode = SyntaxHighlightingService.shared.highlightedAttributedString(for: code)

      // Parse errors (simplified)
      errors = parseErrors(in: code)

      // Notify parent of errors
      onErrorHighlight(errors)

    } catch {
      print("Error highlighting code: \(error)")
    }
    isHighlighting = false
  }

    private func parseErrors(in code: String) -> [CodeError] {
        var errors: [CodeError] = []

        // Simple error detection for demo purposes
        let lines = code.components(separatedBy: "\n")
        for (index, line) in lines.enumerated() {
            let lineNumber = index + 1

            // Check for common Swift syntax errors
            if line.hasPrefix("let ") && !line.contains("=") && !line.contains(":") {
                errors.append(CodeError(
                    line: lineNumber,
                    message: "Constant 'let' declaration requires initial value or type annotation"
                ))
            }

            if line.hasSuffix("(") && !line.contains(")") {
                errors.append(CodeError(
                    line: lineNumber,
                    message: "Missing closing parenthesis"
                ))
            }

            if line.contains("print(") && !line.contains(")") {
                errors.append(CodeError(
                    line: lineNumber,
                    message: "Missing closing parenthesis in print statement"
                ))
            }
        }

        return errors
    }
}

// MARK: - Preview

#Preview("SMCodeEditor") {
    SMCodeEditor(
        code: .constant("func greet(name: String) -> String {\n    return \"Hello, \\(name)!\"\n}\n\nprint(greet(name: \"World\"))"),
        cursorPosition: .constant(50),
        isEditable: true,
        language: "swift",
        showLineNumbers: true,
        showAutocomplete: true,
        completions: [
            AutocompleteCompletion(text: "print", type: .keyword, detail: "Print to console"),
            AutocompleteCompletion(text: "String", type: .type, detail: "Swift String type")
        ],
        onCompletionSelect: { _ in },
        onRunCode: {},
        onErrorHighlight: { _ in }
    )
    .frame(width: 600, height: 400)
}