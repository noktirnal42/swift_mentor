import Foundation
import AppKit

final class ProjectGeneratorService {
    static let shared = ProjectGeneratorService()
    private init() {}

    struct GeneratedProject {
        let name: String
        let path: URL
        let files: [String]
    }

    enum ProjectType {
        case swiftPackage
        case swiftUIApp
        case playground
        case swiftCLI
        case metalApp
        case coremlApp
    }

    func generateProject(for lesson: Lesson) async throws -> GeneratedProject {
        guard lesson.xcodeProject?.enabled == true,
              let projectInfo = lesson.xcodeProject else {
            throw ProjectError.notAvailable
        }

        let tempDir = FileManager.default.temporaryDirectory
        let projectDir = tempDir.appendingPathComponent(projectInfo.projectName)

        if FileManager.default.fileExists(atPath: projectDir.path) {
            try FileManager.default.removeItem(at: projectDir)
        }
        try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)

        let files = try generateFiles(for: lesson, in: projectDir, projectInfo: projectInfo)

        try generateXcodeGenConfig(in: projectDir, name: projectInfo.projectName, files: files)

        return GeneratedProject(name: projectInfo.projectName, path: projectDir, files: files)
    }

    private func generateFiles(for lesson: Lesson, in projectDir: URL, projectInfo: ProjectInfo) throws -> [String] {
        var files: [String] = []

        let mainFile = projectDir.appendingPathComponent("main.swift")
        let mainContent = generateMainFile(for: lesson)
        try mainContent.write(to: mainFile, atomically: true, encoding: .utf8)
        files.append("main.swift")

        for section in lesson.sections {
            if case .code(_, let title, let starterCode, _, _) = section {
                let sanitizedTitle = title
                    .replacingOccurrences(of: " ", with: "_")
                    .replacingOccurrences(of: "/", with: "_")
                    .lowercased()
                let fileName = "\(sanitizedTitle).swift"
                let filePath = projectDir.appendingPathComponent(fileName)

                let fullContent = """
                import Foundation
                import SwiftUI

                // \(title)

                \(starterCode)
                """
                try fullContent.write(to: filePath, atomically: true, encoding: .utf8)
                files.append(fileName)
            }
        }

        // Check project type and generate appropriate files
        switch projectInfo.projectType {
        case "swiftui-app":
            let contentViewFile = projectDir.appendingPathComponent("ContentView.swift")
            let contentView = generateContentView(for: lesson)
            try contentView.write(to: contentViewFile, atomically: true, encoding: .utf8)
            files.append("ContentView.swift")

            let appFile = projectDir.appendingPathComponent("SwiftMentorApp.swift")
            let appContent = """
            import SwiftUI

            @main
            struct \(projectInfo.projectName)App: App {
                var body: some Scene {
                    WindowGroup {
                        ContentView()
                    }
                }
            }
            """
            try appContent.write(to: appFile, atomically: true, encoding: .utf8)
            files.append("SwiftMentorApp.swift")

        case "metal-app":
            let metalFile = projectDir.appendingPathComponent("MetalRenderer.swift")
            let metalContent = """
            import Metal
            import MetalKit

            class MetalRenderer: NSObject, MTKViewDelegate {
                func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
                    // Handle resize
                }

                func draw(in view: MTKView) {
                    // Draw here
                }
            }
            """
            try metalContent.write(to: metalFile, atomically: true, encoding: .utf8)
            files.append("MetalRenderer.swift")

        case "coreml-app":
            // CoreML apps still need basic SwiftUI app structure
            let contentViewFile = projectDir.appendingPathComponent("ContentView.swift")
            let contentView = generateContentView(for: lesson)
            try contentView.write(to: contentViewFile, atomically: true, encoding: .utf8)
            files.append("ContentView.swift")

        case "swift-cli":
            // CLI apps just need main.swift
            break

        default:
            // Default to SwiftUI app for any other type
            let contentViewFile = projectDir.appendingPathComponent("ContentView.swift")
            let contentView = generateContentView(for: lesson)
            try contentView.write(to: contentViewFile, atomically: true, encoding: .utf8)
            files.append("ContentView.swift")
        }

        return files
    }

    private func generateMainFile(for lesson: Lesson) -> String {
        var content = "// \(lesson.title)\n"
        content += "// \(lesson.description)\n\n"
        content += "import Foundation\n\n"

        for section in lesson.sections {
            if case .code(_, _, let starterCode, _, _) = section {
                content += "// Code: \(starterCode.prefix(50))...\n"
            }
        }

        content += "\n// Run the code to see the output!\n"
        return content
    }

    private func generateContentView(for lesson: Lesson) -> String {
        var content = "import SwiftUI\n\n"

        for section in lesson.sections {
            if case .code(_, let title, let starterCode, _, _) = section {
                content += "// MARK: - \(title)\n"
                content += starterCode
                content += "\n\n"
            }
        }

        content += """
        struct ContentView: View {
            var body: some View {
                VStack {
                    Text("Hello, SwiftUI!")
                        .font(.largeTitle)
                    Text("\(lesson.description)")
                        .font(.caption)
                }
                .padding()
            }
        }
        """

        return content
    }

    private func generateXcodeGenConfig(in projectDir: URL, name: String, files: [String]) throws {
        let projectYml = """
        name: \(name)
        options:
          bundleIdPrefix: com.swiftmentor
          deploymentTarget:
            macOS: "14.0"

        targets:
          \(name):
            type: application
            platform: macOS
            sources: [\(files.map { "\"\($0)\"" }.joined(separator: ", "))]
            settings:
              base:
                PRODUCT_BUNDLE_IDENTIFIER: com.swiftmentor.\(name.lowercased())
                INFOPLIST_GENERATION_MODE: GeneratedFile
                INFOPLIST_KEY_CFBundleDisplayName: \(name)
                GENERATE_INFOPLIST_FILE: YES
                SWIFT_VERSION: "5.9"
        """

        try projectYml.write(to: projectDir.appendingPathComponent("project.yml"), atomically: true, encoding: .utf8)
    }

    func openProjectInXcode(_ project: GeneratedProject) {
        let xcodegenProcess = Process()
        xcodegenProcess.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/xcodegen")
        xcodegenProcess.arguments = ["generate", "--spec", project.path.appendingPathComponent("project.yml").path]
        xcodegenProcess.currentDirectoryURL = project.path

        do {
            try xcodegenProcess.run()
            xcodegenProcess.waitUntilExit()

            let xcodeproj = project.path.appendingPathComponent("\(project.name).xcodeproj")
            if FileManager.default.fileExists(atPath: xcodeproj.path) {
                NSWorkspace.shared.open(xcodeproj)
            }
        } catch {
            print("Failed to open Xcode: \(error)")
        }
    }
}

enum ProjectError: LocalizedError {
    case notAvailable
    case generationFailed(String)

    var errorDescription: String? {
        switch self {
        case .notAvailable: return "No Xcode project available for this lesson"
        case .generationFailed(let reason): return "Project generation failed: \(reason)"
        }
    }
}