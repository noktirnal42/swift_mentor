import SwiftUI

// MARK: - SMProgressRing (Enhanced Progress Ring per SPEC.md)

struct SMProgressRing: View {
    let progress: Double // 0.0 to 1.0
    let size: CGFloat
    let lineWidth: CGFloat?
    let showPercentage: Bool
    let animation: Animation?

    init(progress: Double, size: CGFloat = 40, lineWidth: CGFloat? = nil,
         showPercentage: Bool = true, animation: Animation? = .easeInOut(duration: 0.3)) {
        self.progress = max(0, min(1, progress)) // Clamp between 0 and 1
        self.size = size
        self.lineWidth = lineWidth
        self.showPercentage = showPercentage
        self.animation = animation
    }

    private var calculatedLineWidth: CGFloat {
        lineWidth ?? size / 10
    }

    private var progressColor: Color {
        if progress >= 1.0 {
            return .green
        } else if progress > 0.5 {
            return .blue
        } else if progress > 0 {
            return .orange
        } else {
            return .gray
        }
    }

    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: calculatedLineWidth)

            // Progress circle
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    progressColor,
                    style: StrokeStyle(lineWidth: calculatedLineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(animation, value: progress)

            // Percentage text
            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: size / 4, weight: .medium))
                    .foregroundColor(.primary)
                    .monospacedDigit()
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Preview

#Preview("SMProgressRing") {
    VStack(spacing: 20) {
        SMProgressRing(progress: 0.0, size: 60)
        SMProgressRing(progress: 0.25, size: 60)
        SMProgressRing(progress: 0.5, size: 60)
        SMProgressRing(progress: 0.75, size: 60)
        SMProgressRing(progress: 1.0, size: 60)
    }
    .padding()
}

#Preview("SMProgressRing - Variations") {
    VStack(spacing: 30) {
        HStack(spacing: 20) {
            SMProgressRing(progress: 0.6, size: 30)
            SMProgressRing(progress: 0.6, size: 50)
            SMProgressRing(progress: 0.6, size: 80)
        }

        HStack(spacing: 20) {
            SMProgressRing(progress: 0.6, size: 50, lineWidth: 2)
            SMProgressRing(progress: 0.6, size: 50, lineWidth: 4)
            SMProgressRing(progress: 0.6, size: 50, lineWidth: 8)
        }

        HStack(spacing: 20) {
            SMProgressRing(progress: 0.6, size: 50, showPercentage: false)
            SMProgressRing(progress: 0.6, size: 50, showPercentage: true)
            SMProgressRing(progress: 0.6, size: 50, animation: .linear(duration: 1.0))
        }
    }
    .padding()
}