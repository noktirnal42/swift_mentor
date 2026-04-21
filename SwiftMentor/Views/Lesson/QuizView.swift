import SwiftUI

struct QuizView: View {
    let quiz: Quiz
    @State private var selectedIndex: Int? = nil
    @State private var showResult: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(quiz.question)
                .font(.headline)

            ForEach(Array(quiz.options.enumerated()), id: \.offset) { index, option in
                Button(action: {
                    selectedIndex = index
                    showResult = true
                }) {
                    HStack {
                        Image(systemName: selectedIndex == index ? "circle.fill" : "circle")
                            .foregroundColor(selectedIndex == index ? .blue : .gray)
                        Text(option)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .padding()
                    .background(selectedIndex == index ? Color.blue.opacity(0.1) : Color.clear)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
            }

            if showResult {
                HStack {
                    if selectedIndex == quiz.correctIndex {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Correct!")
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                        Text("Incorrect. \(quiz.explanation)")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
        }
        .padding()
    }
}