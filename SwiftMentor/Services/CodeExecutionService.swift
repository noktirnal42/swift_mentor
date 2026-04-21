import Foundation

final class CodeExecutionService {
    static let shared = CodeExecutionService()
    private init() {}

    struct ExecutionResult {
        let success: Bool
        let output: String
        let errors: [ExecutionError]
        let executionTime: TimeInterval
    }

    struct ExecutionError: Identifiable {
        let id = UUID()
        let line: Int?
        let column: Int?
        let message: String
        let severity: Severity

        enum Severity {
            case error
            case warning
            case note
        }
    }

    func execute(code: String) async -> ExecutionResult {
        let startTime = Date()
        #if DEBUG
        Self.writeDebugStatic("execute() called with \(code.count) chars")
        Self.writeDebugStatic("Code preview: \(code.prefix(100))")
        #endif

        guard !code.isEmpty else {
            #if DEBUG
            Self.writeDebugStatic("FAILED: Code is empty")
            #endif
            return ExecutionResult(
                success: false,
                output: "",
                errors: [ExecutionError(line: nil, column: nil, message: "No code to execute", severity: .error)],
                executionTime: 0
            )
        }

        guard code.count <= 10000 else {
            #if DEBUG
            Self.writeDebugStatic("FAILED: Code exceeds 10k chars")
            #endif
            return ExecutionResult(
                success: false,
                output: "",
                errors: [ExecutionError(line: nil, column: nil, message: "Code exceeds 10,000 character limit", severity: .error)],
                executionTime: 0
            )
        }

        let syntaxErrors = validateSyntax(code)
        if !syntaxErrors.isEmpty {
            #if DEBUG
            Self.writeDebugStatic("FAILED: Syntax errors: \(syntaxErrors.map { $0.message })")
            #endif
            return ExecutionResult(
                success: false,
                output: "",
                errors: syntaxErrors,
                executionTime: Date().timeIntervalSince(startTime)
            )
        }

        #if DEBUG
        Self.writeDebugStatic("Syntax OK, calling runSwiftCode...")
        #endif
        let result = await runSwiftCode(code, startTime: startTime)
        #if DEBUG
        Self.writeDebugStatic("runSwiftCode returned: success=\(result.success), output=\(result.output.prefix(200)), errors=\(result.errors.count)")
        #endif
        return result
    }

    private func validateSyntax(_ code: String) -> [ExecutionError] {
        var errors: [ExecutionError] = []

        let openBraces = code.filter { $0 == "{" }.count
        let closeBraces = code.filter { $0 == "}" }.count
        if openBraces != closeBraces {
            errors.append(ExecutionError(
                line: nil,
                column: nil,
                message: "Mismatched braces: \(openBraces) open, \(closeBraces) close",
                severity: .error
            ))
        }

        let openParens = code.filter { $0 == "(" }.count
        let closeParens = code.filter { $0 == ")" }.count
        if openParens != closeParens {
            errors.append(ExecutionError(
                line: nil,
                column: nil,
                message: "Mismatched parentheses: \(openParens) open, \(closeParens) close",
                severity: .error
            ))
        }

        return errors
    }

    private func runSwiftCode(_ code: String, startTime: Date) async -> ExecutionResult {
        // Run the entire process on a background thread so we never block the main actor
        return await Task.detached(priority: .userInitiated) {
            #if DEBUG
            Self.writeDebugStatic("Task.detached started")
            #endif

            let tempDir = FileManager.default.temporaryDirectory
            let projectDir = tempDir.appendingPathComponent("SwiftMentor_\(UUID().uuidString)")

            do {
                try FileManager.default.createDirectory(at: projectDir, withIntermediateDirectories: true)
                #if DEBUG
                Self.writeDebugStatic("Created temp dir: \(projectDir.path)")
                #endif

                let mainFile = projectDir.appendingPathComponent("main.swift")
                try code.write(to: mainFile, atomically: true, encoding: .utf8)
                #if DEBUG
                Self.writeDebugStatic("Wrote code to \(mainFile.path), \(code.count) chars")
                #endif

                // Verify /usr/bin/swift exists
                let swiftBin = "/usr/bin/swift"
                let swiftExists = FileManager.default.fileExists(atPath: swiftBin)
                #if DEBUG
                Self.writeDebugStatic("/usr/bin/swift exists: \(swiftExists)")
                #endif

                let swiftURL = URL(fileURLWithPath: swiftBin)

                let process = Process()
                process.executableURL = swiftURL
                process.arguments = [mainFile.path]
                process.currentDirectoryURL = projectDir

                let outputPipe = Pipe()
                let errorPipe = Pipe()
                process.standardOutput = outputPipe
                process.standardError = errorPipe

                #if DEBUG
                Self.writeDebugStatic("Process configured, calling run()...")
                #endif

                try process.run()
                #if DEBUG
                Self.writeDebugStatic("process.run() succeeded, isRunning: \(process.isRunning)")
                #endif

                // Timeout: kill the process if it runs longer than 10 seconds
                let timeoutTask = Task {
                    try await Task.sleep(nanoseconds: 10_000_000_000)
                    if process.isRunning {
                        #if DEBUG
                        Self.writeDebugStatic("Timeout reached, terminating process")
                        #endif
                        process.terminate()
                    }
                }

                process.waitUntilExit()
                timeoutTask.cancel()
                #if DEBUG
                Self.writeDebugStatic("Process exited with status: \(process.terminationStatus)")
                #endif

                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

                let output = String(data: outputData, encoding: .utf8) ?? ""
                let errorOutput = String(data: errorData, encoding: .utf8) ?? ""

                #if DEBUG
                Self.writeDebugStatic("STDOUT (\(output.count) chars): \(output.prefix(200))")
                Self.writeDebugStatic("STDERR (\(errorOutput.count) chars): \(errorOutput.prefix(200))")
                #endif

                try? FileManager.default.removeItem(at: projectDir)

                let executionTime = Date().timeIntervalSince(startTime)

                if process.terminationStatus != 0 {
                    let errors = self.parseCompilerErrors(errorOutput)
                    #if DEBUG
                    Self.writeDebugStatic("FAILED: Non-zero exit status \(process.terminationStatus), \(errors.count) parsed errors")
                    #endif
                    return ExecutionResult(
                        success: false,
                        output: output,
                        errors: errors.isEmpty && !errorOutput.isEmpty
                        ? [ExecutionError(line: nil, column: nil, message: errorOutput.trimmingCharacters(in: .whitespacesAndNewlines), severity: .error)]
                        : errors,
                        executionTime: executionTime
                    )
                }

                #if DEBUG
                Self.writeDebugStatic("SUCCESS! Execution time: \(executionTime)s")
                #endif
                return ExecutionResult(
                    success: true,
                    output: output.isEmpty ? "✅ Program finished with no output." : output,
                    errors: [],
                    executionTime: executionTime
                )
            } catch {
                #if DEBUG
                Self.writeDebugStatic("CAUGHT ERROR: \(error.localizedDescription)")
                Self.writeDebugStatic("Error domain: \((error as NSError).domain), code: \((error as NSError).code)")
                #endif
                try? FileManager.default.removeItem(at: projectDir)
                return ExecutionResult(
                    success: false,
                    output: "",
                    errors: [ExecutionError(line: nil, column: nil, message: "Execution failed: \(error.localizedDescription)", severity: .error)],
                    executionTime: Date().timeIntervalSince(startTime)
                )
            }
        }.value
    }
    
    #if DEBUG
    private static func writeDebugStatic(_ message: String) {
        let logPath = "/tmp/SwiftMentor_debug.log"
        let timestamped = "\(Date()): [CodeExec] \(message)\n"
        if let data = timestamped.data(using: .utf8) {
            if FileManager.default.fileExists(atPath: logPath) {
                if let fileHandle = try? FileHandle(forWritingTo: URL(fileURLWithPath: logPath)) {
                    fileHandle.seekToEndOfFile()
                    fileHandle.write(data)
                    fileHandle.closeFile()
                }
            } else {
                try? data.write(to: URL(fileURLWithPath: logPath))
            }
        }
    }
    #endif

    private func parseCompilerErrors(_ output: String) -> [ExecutionError] {
        var errors: [ExecutionError] = []

        let lines = output.components(separatedBy: "\n")
        let errorPattern = #"^(.+?):(\d+):(\d+):\s*(error|warning|note):\s*(.+)$"#

        guard let regex = try? NSRegularExpression(pattern: errorPattern) else { return errors }

        for line in lines {
            let nsLine = line as NSString
            let range = NSRange(location: 0, length: nsLine.length)
            if let match = regex.firstMatch(in: line, range: range) {
                let _ = nsLine.substring(with: match.range(at: 1))
                let lineNum = Int(nsLine.substring(with: match.range(at: 2))) ?? 0
                let column = Int(nsLine.substring(with: match.range(at: 3))) ?? 0
                let severityStr = nsLine.substring(with: match.range(at: 4))
                let message = nsLine.substring(with: match.range(at: 5))

                let severity: ExecutionError.Severity
                switch severityStr {
                case "error": severity = .error
                case "warning": severity = .warning
                default: severity = .note
                }

                errors.append(ExecutionError(
                    line: lineNum,
                    column: column,
                    message: message,
                    severity: severity
                ))
            }
        }

        return errors
    }

    func validateInteractiveExercise(code: String, validation: Validation) -> (passed: Bool, message: String) {
        switch validation.type {
        case "contains":
            if code.range(of: validation.pattern, options: .regularExpression) != nil {
                return (true, "✅ Correct! Your code contains the expected pattern.")
            } else {
                return (false, "❌ Your code doesn't contain the expected pattern. Try again!")
            }
        case "matches":
            do {
                let regex = try NSRegularExpression(pattern: validation.pattern)
                let range = NSRange(code.startIndex..., in: code)
                if regex.firstMatch(in: code, range: range) != nil {
                    return (true, "✅ Excellent work!")
                } else {
                    return (false, "❌ The output doesn't match expectations.")
                }
            } catch {
                return (false, "Validation error: \(error.localizedDescription)")
            }
        default:
            return (false, "Unknown validation type")
        }
    }
}
