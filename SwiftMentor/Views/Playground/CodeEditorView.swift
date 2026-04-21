import SwiftUI
import AppKit
import Splash

// MARK: - CodeEditorView

struct CodeEditorView: View {
    @Binding var code: String
    @Binding var cursorPosition: Int
    let showAutocomplete: Bool
    let completions: [AutocompleteCompletion]
    let onCompletionSelect: (AutocompleteCompletion) -> Void
    let onRunCode: () -> Void

    @State private var scrollOffset: CGFloat = 0
    @State private var lineCount: Int = 1

    var body: some View {
        ZStack(alignment: .topLeading) {
            Color(nsColor: NSColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0))

            HStack(alignment: .top, spacing: 0) {
                lineNumbersView
                    .frame(width: 50)

                ScrollView(.vertical, showsIndicators: true) {
                    PlainTextEditor(text: $code)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.white)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .frame(minHeight: 300)
                        .onChange(of: code) { _, newValue in
                            updateLineCount()
                            cursorPosition = newValue.count
                        }
                }
            }

            if showAutocomplete && !completions.isEmpty {
                autocompletePopup
                    .offset(x: 60, y: 50 + scrollOffset)
            }
        }
        .onAppear {
            updateLineCount()
        }
    }

    private var lineNumbersView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .trailing, spacing: 0) {
                ForEach(1...max(lineCount, 1), id: \.self) { lineNum in
                    Text("\(lineNum)")
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.gray)
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
}

// MARK: - PlainTextEditor (NSViewRepresentable)
// Wraps NSTextView directly so we can disable macOS "smart" text substitutions
// (smart quotes, smart dashes, auto-correct, etc.) that break Swift code.
// Now with live Splash syntax highlighting!

struct PlainTextEditor: NSViewRepresentable {
    @Binding var text: String

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView

        // Disable ALL automatic text substitutions that break code
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        textView.isAutomaticTextReplacementEnabled = false
        textView.isAutomaticSpellingCorrectionEnabled = false
        textView.isAutomaticDataDetectionEnabled = false
        textView.isAutomaticLinkDetectionEnabled = false
        textView.isContinuousSpellCheckingEnabled = false
        textView.isGrammarCheckingEnabled = false

        // Make it a plain text editor (not rich text)
        textView.isRichText = false
        textView.usesFindBar = true
        textView.isSelectable = true
        textView.isEditable = true
        textView.allowsUndo = true
        textView.drawsBackground = false
        textView.textColor = NSColor.white
        textView.insertionPointColor = NSColor.white

        // Set font
        textView.font = NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)

        // Content
        textView.string = text
        textView.delegate = context.coordinator

        // Store reference in coordinator
        context.coordinator.textView = textView

        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            // External update — set text and re-highlight
            textView.string = text
            applySyntaxHighlighting(to: textView)
        }
    }

    /// Apply Splash syntax highlighting to the text view while preserving cursor position
    private func applySyntaxHighlighting(to textView: NSTextView) {
        let code = textView.string
        guard !code.isEmpty else { return }

        let highlighted = SyntaxHighlightingService.shared.highlightedAttributedString(for: code)

        // Preserve cursor position
        let selectedRange = textView.selectedRange()

        // Apply the highlighted attributed string to the text storage
        guard let textStorage = textView.textStorage else { return }
        textStorage.beginEditing()
        textStorage.setAttributedString(highlighted)
        textStorage.endEditing()

        // Restore cursor position
        if selectedRange.location <= textStorage.length {
            textView.setSelectedRange(selectedRange)
        }
    }
}

// MARK: - PlainTextEditor Coordinator

extension PlainTextEditor {
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: PlainTextEditor
        weak var textView: NSTextView?
        private var highlightTimer: Timer?

        init(_ parent: PlainTextEditor) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            let newString = textView.string
            parent.text = newString

            // Debounce syntax highlighting — highlight after a short pause
            highlightTimer?.invalidate()
            highlightTimer = Timer.scheduledTimer(withTimeInterval: 0.15, repeats: false) { [weak self] _ in
                guard let self, let textView = self.textView else { return }
                self.parent.applySyntaxHighlighting(to: textView)
            }
        }
    }
}

#Preview {
    CodeEditorView(
        code: .constant("print(\"Hello, World!\")"),
        cursorPosition: .constant(20),
        showAutocomplete: true,
        completions: [
            AutocompleteCompletion(text: "print", type: .keyword, detail: "Print to console"),
            AutocompleteCompletion(text: "String", type: .type, detail: "Swift String type")
        ],
        onCompletionSelect: { _ in },
        onRunCode: {}
    )
    .frame(height: 400)
}
