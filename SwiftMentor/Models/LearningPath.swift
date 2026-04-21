import Foundation

struct LearningPath: Codable, Identifiable, Hashable {
  let id: String
  let title: String
  let description: String
  let icon: String
  let color: String
  var difficulty: Lesson.Difficulty = .beginner
  var lessons: [LessonRef] = []
  var prerequisites: [String] = []
  var order: Int = 0

  var lessonCount: Int {
    lessons.count
  }

  // Initializer for hardcoded paths
  init(id: String, title: String, description: String, icon: String, color: String, difficulty: Lesson.Difficulty, lessons: [LessonRef], prerequisites: [String], order: Int) {
    self.id = id
    self.title = title
    self.description = description
    self.icon = icon
    self.color = color
    self.difficulty = difficulty
    self.lessons = lessons
    self.prerequisites = prerequisites
    self.order = order
  }

  // Custom decoder with defaults for missing keys
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    title = try container.decode(String.self, forKey: .title)
    description = try container.decode(String.self, forKey: .description)
    icon = try container.decode(String.self, forKey: .icon)
    color = try container.decode(String.self, forKey: .color)
    difficulty = (try? container.decode(Lesson.Difficulty.self, forKey: .difficulty)) ?? .beginner
    lessons = (try? container.decode([LessonRef].self, forKey: .lessons)) ?? []
    prerequisites = (try? container.decode([String].self, forKey: .prerequisites)) ?? []
    order = (try? container.decode(Int.self, forKey: .order)) ?? 0
  }

  enum CodingKeys: String, CodingKey {
    case id, title, description, icon, color, difficulty, lessons, prerequisites, order
  }
}

struct LessonRef: Codable, Identifiable, Hashable {
    let id: String
    let title: String
    let type: String?
}

struct LearningPathsResponse: Codable {
    let paths: [LearningPath]
}