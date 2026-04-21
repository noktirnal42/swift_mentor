import SwiftUI

struct SidebarView: View {
    @EnvironmentObject private var appState: AppState
    @State private var selectedSection: AppState.Section? = .dashboard

    var body: some View {
        List(selection: $selectedSection) {
            Section("Learn") {
                NavigationLink(value: AppState.Section.dashboard) {
                    Label("Dashboard", systemImage: "house.fill")
                }

                NavigationLink(value: AppState.Section.learningPaths) {
                    Label("Learning Paths", systemImage: "book.fill")
                }

                NavigationLink(value: AppState.Section.playground) {
                    Label("Playground", systemImage: "terminal.fill")
                }

                NavigationLink(value: AppState.Section.snippets) {
                    Label("Snippets", systemImage: "doc.text.fill")
                }
            }

            Section("Progress") {
                NavigationLink(value: AppState.Section.progress) {
                    Label {
                        HStack {
                            Text("Progress")
                            Spacer()
                            Text("\(Int(appState.overallProgress * 100))%")
                                .foregroundColor(.secondary)
                                .font(.caption)
                                .monospacedDigit()
                        }
                    } icon: {
                        Image(systemName: "chart.bar.fill")
                    }
                }

                if appState.streakDays > 0 {
                    Label {
                        HStack {
                            Text("Streak")
                            Spacer()
                            HStack(spacing: 4) {
                                Image(systemName: "flame.fill")
                                    .foregroundStyle(Theme.fireGradient)
                                Text("\(appState.streakDays)")
                                    .foregroundColor(.orange)
                            }
                            .font(.caption)
                        }
                    } icon: {
                        Image(systemName: "flame")
                    }
                }
            }

            Section("Tools") {
                Button(action: { appState.showAIAssistant = true }) {
                    Label {
                        HStack {
                            Text("AI Assistant")
                            Spacer()
                            Circle()
                                .fill(AIService.shared.isConnected ? Color.green : Color.red)
                                .frame(width: 8, height: 8)
                        }
                    } icon: {
                        Image(systemName: "brain")
                    }
                }
                .buttonStyle(.plain)

                NavigationLink(value: AppState.Section.settings) {
                    Label("Settings", systemImage: "gearshape.fill")
                }

                NavigationLink(value: AppState.Section.help) {
                    Label("Help & Onboarding", systemImage: "questionmark.circle.fill")
                }
            }

            Section("Quick Links") {
                Button(action: openXcode) {
                    Label("Open Xcode", systemImage: "hammer.fill")
                }
                .buttonStyle(.plain)

                Button(action: openDocumentation) {
                    Label("Documentation", systemImage: "book")
                }
                .buttonStyle(.plain)
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("SwiftMentor")
        .onChange(of: selectedSection) { _, newValue in
            if let section = newValue {
                appState.selectedSection = section
            }
        }
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Button(action: { appState.showSidebar.toggle() }) {
                    Image(systemName: "sidebar.left")
                }
            }
        }
    }

    private func openXcode() {
        if let xcodePath = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.dt.Xcode") {
            NSWorkspace.shared.openApplication(at: xcodePath, configuration: NSWorkspace.OpenConfiguration())
        }
    }

    private func openDocumentation() {
        if let url = URL(string: "https://developer.apple.com/documentation") {
            NSWorkspace.shared.open(url)
        }
    }
}

#Preview {
    SidebarView()
        .environmentObject(AppState.shared)
}
