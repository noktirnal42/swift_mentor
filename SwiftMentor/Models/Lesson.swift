import Foundation

struct Lesson: Codable, Identifiable {
  let id: String
  let pathId: String
  let title: String
  let description: String
  let difficulty: Difficulty
  let estimatedMinutes: Int
  let order: Int
  let sections: [LessonSection]
  let xcodeProject: ProjectInfo?

  init(id: String, pathId: String, title: String, description: String, difficulty: Difficulty, estimatedMinutes: Int, order: Int, sections: [LessonSection], xcodeProject: ProjectInfo?) {
    self.id = id
    self.pathId = pathId
    self.title = title
    self.description = description
    self.difficulty = difficulty
    self.estimatedMinutes = estimatedMinutes
    self.order = order
    self.sections = sections
    self.xcodeProject = xcodeProject
  }

  // Custom decoder with graceful handling of missing/invalid xcodeProject
  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(String.self, forKey: .id)
    pathId = try container.decode(String.self, forKey: .pathId)
    title = try container.decode(String.self, forKey: .title)
    description = try container.decode(String.self, forKey: .description)
    difficulty = try container.decode(Difficulty.self, forKey: .difficulty)
    estimatedMinutes = try container.decode(Int.self, forKey: .estimatedMinutes)
    order = try container.decode(Int.self, forKey: .order)
    sections = try container.decode([LessonSection].self, forKey: .sections)
    xcodeProject = try? container.decode(ProjectInfo.self, forKey: .xcodeProject)
  }

  private enum CodingKeys: String, CodingKey {
    case id, pathId, title, description, difficulty, estimatedMinutes, order, sections, xcodeProject
  }
    
    enum Difficulty: String, Codable, CaseIterable {
        case beginner
        case intermediate
        case advanced

        var displayName: String {
            rawValue.capitalized
        }

        var color: String {
            switch self {
            case .beginner: return "green"
            case .intermediate: return "orange"
            case .advanced: return "red"
            }
        }
    }

    var icon: String {
        switch difficulty {
        case .beginner: return "1.circle.fill"
        case .intermediate: return "2.circle.fill"
        case .advanced: return "3.circle.fill"
        }
    }
}

struct ProjectInfo: Codable {
  let enabled: Bool
  let projectName: String
  let files: [String]?
  let projectType: String?

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    enabled = try container.decode(Bool.self, forKey: .enabled)
    projectName = (try? container.decode(String.self, forKey: .projectName)) ?? "Project"
    files = try? container.decode([String].self, forKey: .files)
    projectType = try? container.decode(String.self, forKey: .projectType)
  }
}

enum LessonSection: Codable {
    case text(content: String)
    case code(language: String, title: String, starterCode: String, expectedOutput: String?, solution: String?)
    case interactive(title: String, instructions: String, starterCode: String, validation: Validation)
    case quiz(Quiz)
    case image(url: String, alt: String)

    enum CodingKeys: String, CodingKey {
        case type, content, language, title, starterCode, expectedOutput, solution
        case instructions, validation, question, options, correctIndex, explanation, url, alt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)

        switch type {
        case "text":
            let content = try container.decode(String.self, forKey: .content)
            self = .text(content: content)
        case "code":
            let language = try container.decodeIfPresent(String.self, forKey: .language) ?? "swift"
            let title = try container.decode(String.self, forKey: .title)
            let starterCode = try container.decode(String.self, forKey: .starterCode)
            let expectedOutput = try container.decodeIfPresent(String.self, forKey: .expectedOutput)
            let solution = try container.decodeIfPresent(String.self, forKey: .solution)
            self = .code(language: language, title: title, starterCode: starterCode, expectedOutput: expectedOutput, solution: solution)
        case "interactive":
            let title = try container.decode(String.self, forKey: .title)
            let instructions = try container.decode(String.self, forKey: .instructions)
            let starterCode = try container.decodeIfPresent(String.self, forKey: .starterCode) ?? ""
            let validation = try container.decode(Validation.self, forKey: .validation)
            self = .interactive(title: title, instructions: instructions, starterCode: starterCode, validation: validation)
        case "quiz":
            let question = try container.decode(String.self, forKey: .question)
            let options = try container.decode([String].self, forKey: .options)
            let correctIndex = try container.decode(Int.self, forKey: .correctIndex)
            let explanation = try container.decode(String.self, forKey: .explanation)
            self = .quiz(Quiz(question: question, options: options, correctIndex: correctIndex, explanation: explanation))
        case "image":
            let url = try container.decode(String.self, forKey: .url)
            let alt = try container.decode(String.self, forKey: .alt)
            self = .image(url: url, alt: alt)
        default:
            throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Unknown section type: \(type)")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .text(let content):
            try container.encode("text", forKey: .type)
            try container.encode(content, forKey: .content)
        case .code(let language, let title, let starterCode, let expectedOutput, let solution):
            try container.encode("code", forKey: .type)
            try container.encode(language, forKey: .language)
            try container.encode(title, forKey: .title)
            try container.encode(starterCode, forKey: .starterCode)
            try container.encodeIfPresent(expectedOutput, forKey: .expectedOutput)
            try container.encodeIfPresent(solution, forKey: .solution)
        case .interactive(let title, let instructions, let starterCode, let validation):
            try container.encode("interactive", forKey: .type)
            try container.encode(title, forKey: .title)
            try container.encode(instructions, forKey: .instructions)
            try container.encode(starterCode, forKey: .starterCode)
            try container.encode(validation, forKey: .validation)
        case .quiz(let quiz):
            try container.encode("quiz", forKey: .type)
            try container.encode(quiz.question, forKey: .question)
            try container.encode(quiz.options, forKey: .options)
            try container.encode(quiz.correctIndex, forKey: .correctIndex)
            try container.encode(quiz.explanation, forKey: .explanation)
        case .image(let url, let alt):
            try container.encode("image", forKey: .type)
            try container.encode(url, forKey: .url)
            try container.encode(alt, forKey: .alt)
        }
    }
}

struct Validation: Codable {
    let type: String
    let pattern: String
}

struct Quiz: Codable, Identifiable {
    var id: String { question }
    let question: String
    let options: [String]
    let correctIndex: Int
    let explanation: String
}

// MARK: - Code Error (used by SMCodeEditor & SMOutputPanel)

struct CodeError: Identifiable {
    let id = UUID()
    let line: Int
    let message: String
}