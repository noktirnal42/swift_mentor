import SwiftUI
import Foundation

// Preview test for learning paths
struct LearningPathsPreview: View {
    @State private var paths: [LearningPath] = []
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 20) {
            if let error = errorMessage {
                Text("Error: \(error)")
                    .foregroundColor(.red)
            } else if paths.isEmpty {
                ProgressView()
                Text("Loading learning paths...")
            } else {
                List(paths) { path in
                    HStack {
                        Image(systemName: path.icon)
                            .foregroundColor(.accentColor)
                        VStack(alignment: .leading) {
                            Text(path.title)
                                .font(.headline)
                            Text("\(path.lessonCount) lessons")
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .padding()
        .task {
            await loadPaths()
        }
        .previewDisplayName("Learning Paths Preview")
    }

    private func loadPaths() async {
        do {
            paths = try await ContentService.shared.loadLearningPaths()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    LearningPathsPreview()
}
