import SwiftUI

// MARK: - SMQuizView (Enhanced Quiz View per SPEC.md)

struct SMQuizView: View {
    let quiz: Quiz
    @State private var selectedOption: Int? = nil
    @State private var isAnswered: Bool = false
    @State private var showExplanation: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Question
            VStack(alignment: .leading, spacing: 12) {
                Text(quiz.question)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)

                if !quiz.explanation.isEmpty && showExplanation {
                    Text(quiz.explanation)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.1))
                        )
                }
            }

            // Options
            VStack(alignment: .leading, spacing: 12) {
                ForEach(Array(quiz.options.enumerated()), id: \.offset) { index, option in
                    QuizOptionView(
                        option: option,
                        index: index,
                        isSelected: selectedOption == index,
                        isAnswered: isAnswered,
                        isCorrect: index == quiz.correctIndex,
                        onSelect: { selectOption(index) }
                    )
                }
            }

            // Submit Button
            if !isAnswered {
                Button(action: submitAnswer) {
                    HStack {
                        Spacer()
                        Text("Submit Answer")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        Spacer()
                    }
                    .padding(.vertical, 12)
                    .background(
                        selectedOption != nil ? Color.blue : Color.gray.opacity(0.3)
                    )
                    .cornerRadius(8)
                }
                .disabled(selectedOption == nil)
            }

            // Results
            if isAnswered && !showExplanation {
                HStack {
                    Spacer()
                    Button(action: { showExplanation = true }) {
                        HStack {
                            Text("Explanation")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.blue)
                            Image(systemName: "chevron.down")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    Spacer()
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 8,
                    x: 0,
                    y: 4
                )
        )
    }

    private func selectOption(_ index: Int) {
        if !isAnswered {
            selectedOption = index
        }
    }

    private func submitAnswer() {
        guard selectedOption != nil, !isAnswered else { return }
        isAnswered = true
    }
}

// MARK: - Quiz Option View

private struct QuizOptionView: View {
    let option: String
    let index: Int
    let isSelected: Bool
    let isAnswered: Bool
    let isCorrect: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 16) {
                // Selection Indicator
                ZStack {
                    Circle()
                        .strokeBorder(
                            isSelected ? (isAnswered ? (isCorrect ? Color.green : Color.red) : Color.blue) : Color.gray.opacity(0.3),
                            lineWidth: 2
                        )
                        .background(
                            isSelected ? (isAnswered ? (isCorrect ? Color.green : Color.red) : Color.blue.opacity(0.2)) : Color.clear
                        )
                        .frame(width: 24, height: 24)

                    if isAnswered {
                        if isCorrect {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "xmark")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                        }
                    }
                }

                // Option Text
                Text(option)
                    .font(.system(size: 15))
                    .foregroundColor(isAnswered ? (isCorrect ? .primary : .secondary) : .primary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isAnswered ? (isCorrect ? Color.green.opacity(0.1) : Color.red.opacity(0.1)) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview("SMQuizView") {
    VStack(spacing: 20) {
        SMQuizView(
            quiz: Quiz(
                question: "What is the output of print(\"Hello, World!\")?",
                options: ["Hello", "World", "Hello, World!", "Swift"],
                correctIndex: 2,
                explanation: "The print() function outputs the exact string."
            )
        )
        .frame(maxWidth: 500)
    }
    .padding()
}
