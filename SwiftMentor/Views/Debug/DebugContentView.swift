#if DEBUG
import SwiftUI

struct DebugContentView: View {
    @State private var paths: [LearningPath] = []
    @State private var lessons: [Lesson] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section("Learning Paths") {
                if isLoading {
                    Text("Loading...")
                    ProgressView()
                } else if let error = errorMessage {
                    Text("Error: \(error)")
                        .foregroundColor(.red)
                } else if paths.isEmpty {
                    Text("No paths found")
                } else {
                    ForEach(paths) { path in
                        VStack(alignment: .leading) {
                            Text(path.title)
                                .font(.headline)
                            Text("\(path.lessonCount) lessons")
                                .font(.caption)
                        }
                    }
                }
            }

            Section("Lessons Loaded") {
                Text("Lessons: \(lessons.count)")
                if !lessons.isEmpty {
                    ForEach(Array(lessons.prefix(3))) { lesson in
                        VStack(alignment: .leading) {
                            Text(lesson.title)
                            Text(lesson.id)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .navigationTitle("Debug Content")
        .task {
            await loadContent()
        }
    }

    private func loadContent() async {
        isLoading = true
        errorMessage = nil
        do {
            paths = try await ContentService.shared.loadLearningPaths()
            if let firstPath = paths.first {
                lessons = try await ContentService.shared.loadAllLessonsForPath(firstPath.id)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}

#Preview {
    DebugContentView()
}

#endif
