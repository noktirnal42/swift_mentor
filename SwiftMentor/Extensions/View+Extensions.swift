import SwiftUI

extension View {
    // MARK: - Card Style
func cardStyle() -> some View {
        self
            .background(Color(nsColor: .windowBackgroundColor))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    // MARK: - Hover Effect
    func hoverEffect(isHovered: Bool) -> some View {
        self.scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
    }

    // MARK: - Conditional Modifier
    @ViewBuilder
    func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    // MARK: - Hide Keyboard
    func hideKeyboard() {
        NSApp.keyWindow?.makeFirstResponder(nil)
    }

    // MARK: - Scrollable
    func scrollable(direction: Axis.Set = .vertical) -> some View {
        ScrollView(direction) {
            self
        }
    }

    // MARK: - Section Header Style
    func sectionHeader() -> some View {
        self
            .font(.headline)
            .foregroundColor(.secondary)
            .padding(.horizontal)
            .padding(.top, 8)
    }
}

// MARK: - Animation Extensions
extension Animation {
    static var smSpring: Animation {
        .spring(response: 0.3, dampingFraction: 0.7)
    }

    static var smEaseOut: Animation {
        .easeOut(duration: 0.25)
    }
}