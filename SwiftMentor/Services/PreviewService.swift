import Foundation
import AppKit
import SwiftUI

final class PreviewService {
    static let shared = PreviewService()
    private init() {}

    enum PreviewResult {
        case image(NSImage)
        case view(SwiftUI.AnyView)
        case error(String)
    }

    struct PreviewImage {
        let image: NSImage
        let aspectRatio: CGFloat

        var width: CGFloat { image.size.width }
        var height: CGFloat { image.size.height }
    }

    func generatePreview(for code: String) async -> PreviewResult {
        if code.contains("SwiftUI") || code.contains("View") {
            if let result = await renderSwiftUIView(code) {
                return result
            }
        }

        return await generateStaticPreview(for: code)
    }

    private func renderSwiftUIView(_ code: String) async -> PreviewResult? {
        guard code.contains("struct ") && (code.contains(": View") || code.contains("View body")) else {
            return nil
        }

        do {
            let tempDir = FileManager.default.temporaryDirectory
            let projectDir = tempDir.appendingPathComponent("Preview_\(UUID().uuidString)")
            try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)

            let mainFile = projectDir.appendingPathComponent("PreviewApp.swift")
            let viewFile = projectDir.appendingPathComponent("PreviewView.swift")

            let appCode = """
            import SwiftUI

            @main
            struct PreviewApp: App {
                var body: some Scene {
                    WindowGroup {
                        PreviewView()
                    }
                }
            }
            """

            let viewCode = code.replacingOccurrences(of: "@State", with: "@State private")
                .replacingOccurrences(of: "@Binding", with: "@Binding private")

            try appCode.write(to: mainFile, atomically: true, encoding: .utf8)
            try viewCode.write(to: viewFile, atomically: true, encoding: .utf8)

            let image = try await captureWindow(projectDir: projectDir)

            try? FileManager.default.removeItem(at: projectDir)

            return .image(image)
        } catch {
            return .error("Failed to render preview: \(error.localizedDescription)")
        }
    }

    private func captureWindow(projectDir: URL) async throws -> NSImage {
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
            process.arguments = ["-a", "Xcode", projectDir.path]
            process.terminationHandler = { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    let image = NSImage(size: NSSize(width: 400, height: 300))
                    image.lockFocus()
                    NSColor.white.setFill()
                    NSRect(x: 0, y: 0, width: 400, height: 300).fill()

                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.alignment = .center
                    let attrs: [NSAttributedString.Key: Any] = [
                        .foregroundColor: NSColor.gray,
                        .font: NSFont.systemFont(ofSize: 14),
                        .paragraphStyle: paragraphStyle
                    ]
                    "Preview available in Xcode".draw(at: NSPoint(x: 100, y: 140), withAttributes: attrs)
                    image.unlockFocus()
                    continuation.resume(returning: image)
                }
            }
            try? process.run()
        }
    }

    private func generateStaticPreview(for code: String) async -> PreviewResult {
        let previewImage = getStaticPreviewImage(for: code)
        return .image(previewImage)
    }

    private func getStaticPreviewImage(for code: String) -> NSImage {
        let image = NSImage(size: NSSize(width: 400, height: 300))

        image.lockFocus()

        NSColor(red: 0.95, green: 0.95, blue: 0.95, alpha: 1.0).setFill()
        NSRect(x: 0, y: 0, width: 400, height: 300).fill()

        let borderPath = NSBezierPath(roundedRect: NSRect(x: 20, y: 20, width: 360, height: 260), xRadius: 12, yRadius: 12)
        NSColor.white.setFill()
        borderPath.fill()
        NSColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0).setStroke()
        borderPath.lineWidth = 1
        borderPath.stroke()

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center

        let codeAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 1.0),
            .font: NSFont(name: "SF Mono", size: 12) ?? NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
            .paragraphStyle: paragraphStyle
        ]

        let lines = code.components(separatedBy: "\n").prefix(5)
        var yOffset: CGFloat = 240
        for line in lines {
            let displayLine = String(line.trimmingCharacters(in: .whitespaces).prefix(40))
            if !displayLine.isEmpty {
                displayLine.draw(at: NSPoint(x: 40, y: yOffset), withAttributes: codeAttrs)
            }
            yOffset -= 20
        }

        let hintAttrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: NSColor.gray,
            .font: NSFont.systemFont(ofSize: 11),
            .paragraphStyle: paragraphStyle
        ]
        "Static Preview".draw(at: NSPoint(x: 140, y: 30), withAttributes: hintAttrs)

        image.unlockFocus()

        return image
    }

    func getPreviewImagePath(for codeSnippet: String) -> String? {
        let normalized = codeSnippet.lowercased()
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "\n", with: "")

        if normalized.contains("vstack") || normalized.contains("hstack") {
            return "swiftui/layout-stack.png"
        } else if normalized.contains("list") || normalized.contains("foreach") {
            return "swiftui/list-basic.png"
        } else if normalized.contains("navigationstack") || normalized.contains("navigationlink") {
            return "swiftui/navigationstack.png"
        } else if normalized.contains("textfield") {
            return "swiftui/textfield.png"
        } else if normalized.contains("button") {
            return "swiftui/button.png"
        }

        return nil
    }

    func loadPreviewImage(named name: String) -> NSImage? {
        guard let url = Bundle.main.url(forResource: name, withExtension: nil, subdirectory: "PreviewImages") else {
            return nil
        }
        return NSImage(contentsOf: url)
    }
}