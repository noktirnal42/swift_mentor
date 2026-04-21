import SwiftUI

// MARK: - Visual Effect Material Types

enum VisualEffectMaterial {
    case sidebar
    case content
    case header
    case card
    case popover

    var nsMaterial: NSVisualEffectView.Material {
        switch self {
        case .sidebar: return .sidebar
        case .content: return .windowBackground
        case .header: return .titlebar
        case .card: return .sheet
        case .popover: return .popover
        }
    }
}

// MARK: - Visual Effect View (NSViewRepresentable)

struct VisualEffectView: NSViewRepresentable {
    let material: VisualEffectMaterial

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material.nsMaterial
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material.nsMaterial
    }
}

// MARK: - Glass Background

struct GlassBackground: View {
    var material: VisualEffectMaterial = .content

    var body: some View {
        VisualEffectView(material: material)
            .ignoresSafeArea()
    }
}

// MARK: - Glass Card

struct GlassCard<Content: View>: View {
    let content: Content
    let isCompleted: Bool
    let isHovered: Bool

    init(isCompleted: Bool = false, isHovered: Bool = false, @ViewBuilder content: () -> Content) {
        self.isCompleted = isCompleted
        self.isHovered = isHovered
        self.content = content()
    }

    var body: some View {
        content
            .padding()
            .background(
                ZStack {
                    // Glass fill
                    RoundedRectangle(cornerRadius: 16)
                        .fill(.ultraThinMaterial)
                        .opacity(0.6)

                    // Subtle white shimmer
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(isHovered ? 0.12 : 0.06),
                                    Color.white.opacity(0.01)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    // Completed glow
                    if isCompleted {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.green.opacity(0.6), Color.green.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                    } else {
                        // Default border
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    colors: [Color.white.opacity(isHovered ? 0.2 : 0.1), Color.white.opacity(0.02)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(isHovered ? 0.3 : 0.15), radius: isHovered ? 16 : 8, x: 0, y: isHovered ? 8 : 4)
            .scaleEffect(isHovered ? 1.01 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
    }
}

// MARK: - Stat Glass Card (for Dashboard)

struct StatGlassCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let gradient: LinearGradient
    @State private var isHovered = false

    var body: some View {
        GlassCard(isCompleted: false, isHovered: isHovered) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(gradient)
                        .symbolEffect(.pulse, options: .repeating, isActive: isHovered)
                    Spacer()
                }

                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(gradient)

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.headline)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

// MARK: - Hover Effect Modifier

struct HoverEffect: ViewModifier {
    @State private var isHovered = false
    let scale: CGFloat
    let shadowRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .scaleEffect(isHovered ? scale : 1.0)
            .shadow(color: .black.opacity(isHovered ? 0.2 : 0.05), radius: isHovered ? shadowRadius : 4, x: 0, y: isHovered ? 6 : 2)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

extension View {
    func hoverEffect(scale: CGFloat = 1.02, shadowRadius: CGFloat = 12) -> some View {
        modifier(HoverEffect(scale: scale, shadowRadius: shadowRadius))
    }
}

// MARK: - Animated Gradient Text

struct GradientText: View {
    let text: String
    let font: Font
    let gradient: LinearGradient

    init(_ text: String, font: Font = .largeTitle.bold(), gradient: LinearGradient = Theme.textGradient) {
        self.text = text
        self.font = font
        self.gradient = gradient
    }

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(gradient)
    }
}

// MARK: - Shimmer Effect

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    let duration: Double

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.15),
                            Color.white.opacity(0)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geometry.size.width * 2)
                    .offset(x: -geometry.size.width + (geometry.size.width * 4 * phase))
                    .mask(content)
                }
            )
            .onAppear {
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    phase = 1.0
                }
            }
    }
}

extension View {
    func shimmer(duration: Double = 2.0) -> some View {
        modifier(ShimmerEffect(duration: duration))
    }
}

// MARK: - Fade-in Animation Modifier

struct FadeInModifier: ViewModifier {
    @State private var isVisible = false
    let delay: Double

    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 10)
            .animation(.easeOut(duration: 0.5).delay(delay), value: isVisible)
            .onAppear {
                isVisible = true
            }
    }
}

extension View {
    func fadeIn(delay: Double = 0) -> some View {
        modifier(FadeInModifier(delay: delay))
    }
}
