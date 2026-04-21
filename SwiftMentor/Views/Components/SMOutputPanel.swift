import SwiftUI
import AppKit

// MARK: - SMOutputPanel (Enhanced Output Panel with Rich Display)

struct SMOutputPanel: View {
    let output: String
    let errors: [CodeError]
    let isExecuting: Bool
    let executionTime: TimeInterval
    let previewImage: NSImage?
    let onClearOutput: () -> Void
    let onCopyOutput: () -> Void
    let onShareOutput: () -> Void

    @State private var isShowingErrorDetails = false
    @State private var selectedError: CodeError?

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Output")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.semibold)

                Spacer()

                // Status Indicator
                HStack(spacing: 8) {
                    if isExecuting {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Running...")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    } else if !errors.isEmpty {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text("\(errors.count) Error\(errors.count == 1 ? "" : "s")")
                            .font(.system(.caption, design: .monospaced))
                            .fontWeight(.medium)
                            .foregroundColor(.red)
                    } else if !output.isEmpty {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Completed in \(String(format: "%.2f", executionTime))s")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.green)
                    } else {
                        Text("Ready")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Action Buttons
                Button(action: onCopyOutput) {
                    Image(systemName: "doc.on.doc")
                        .font(.caption)
                }
                .help("Copy Output")

                Button(action: onShareOutput) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.caption)
                }
                .help("Share Output")

                Button(action: onClearOutput) {
                    Image(systemName: "trash")
                        .font(.caption)
                }
                .help("Clear Output")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(nsColor: .controlBackgroundColor))

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    // Preview Image (for SwiftUI/UIKit output)
                    if previewImage != nil {
                        previewView
                            .frame(maxHeight: 300)
                    }

                    // Error Display
                    if !errors.isEmpty {
                        errorListView
                    }

                    // Output Text
                    if !output.isEmpty {
                        outputTextView
                    }

                    // Empty State
                    if output.isEmpty && errors.isEmpty && previewImage == nil {
                        emptyStateView
                    }
                }
                .padding()
            }
            .background(Color(nsColor: .textBackgroundColor))
        }
    }

    private var previewView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "photo")
                    .font(.title2)
                    .foregroundColor(.blue)

                Text("Preview")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Spacer()
            }

            if let previewImage = previewImage {
                Image(nsImage: previewImage)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                    )
                    .overlay(
                        Text("No Preview")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    )
            }
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
    }

    private var errorListView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title2)
                    .foregroundColor(.red)

                Text("Errors")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Spacer()

                Button(action: { isShowingErrorDetails.toggle() }) {
                    Image(systemName: isShowingErrorDetails ? "chevron.up" : "chevron.down")
                        .font(.caption)
                }
                .help("Toggle Error Details")
            }

            if isShowingErrorDetails {
                ForEach(errors) { error in
                    errorDetailView(error)
                        .padding(.vertical, 4)
                }
            } else {
                HStack {
                    Text("\(errors.count) error\(errors.count == 1 ? "" : "s") detected")
                        .font(.system(.subheadline))
                        .foregroundColor(.secondary)

                    Spacer()

                    Button("View Details") {
                        isShowingErrorDetails = true
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                }
            }
        }
        .padding()
        .background(Color.red.opacity(0.05))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.red.opacity(0.2), lineWidth: 1)
        )
    }

    private func errorDetailView(_ error: CodeError) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.title3)
                    .foregroundColor(.red)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Line \(error.line)")
                        .font(.system(.subheadline, design: .monospaced))
                        .fontWeight(.medium)
                        .foregroundColor(.red)

                    Text(error.message)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Divider()
                .opacity(0.3)
        }
        .padding()
        .background(Color(nsColor: .underPageBackgroundColor))
        .cornerRadius(6)
    }

    private var outputTextView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "terminal.fill")
                    .font(.title2)
                    .foregroundColor(.green)

                Text("Output")
                    .font(.system(.headline, design: .rounded))
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                Spacer()
            }

            ScrollView {
                Text(output)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.white)
                    .textSelection(.enabled)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(nsColor: NSColor(red: 0.1, green: 0.1, blue: 0.12, alpha: 1.0)))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
        }
        .padding()
        .background(Color(nsColor: .controlBackgroundColor))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "terminal.fill")
                .font(.system(size: 48))
                .foregroundColor(.secondary)

            Text("No output yet")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            Text("Run your code to see output here")
                .font(.system(.body))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

// MARK: - Preview

#Preview("SMOutputPanel") {
    SMOutputPanel(
        output: """
        Hello, World!
        42
        Swift is fun!
        """,
        errors: [],
        isExecuting: false,
        executionTime: 0.42,
previewImage: nil as NSImage?,
    onClearOutput: {},
        onCopyOutput: {},
        onShareOutput: {}
    )
    .frame(width: 500, height: 400)
}

#Preview("SMOutputPanel - Executing") {
    SMOutputPanel(
        output: "",
        errors: [],
        isExecuting: true,
        executionTime: 0,
previewImage: nil as NSImage?,
    onClearOutput: {},
        onCopyOutput: {},
        onShareOutput: {}
    )
    .frame(width: 500, height: 300)
}

#Preview("SMOutputPanel - Preview") {
    SMOutputPanel(
        output: "",
        errors: [],
        isExecuting: false,
        executionTime: 0,
        previewImage: nil as NSImage?,
        onClearOutput: {},
        onCopyOutput: {},
        onShareOutput: {}
    )
    .frame(width: 500, height: 400)
}
