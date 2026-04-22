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
        // Try multiple Xcode locations and versions
        let xcodeBundleIds = [
            "com.apple.dt.Xcode", // Standard Xcode
            "com.apple.dt.Xcode-beta" // Xcode Beta
        ]
        
        // Try to find Xcode via bundle identifier first
        for bundleId in xcodeBundleIds {
            if let xcodePath = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) {
                NSWorkspace.shared.openApplication(at: xcodePath, configuration: NSWorkspace.OpenConfiguration())
                return
            }
        }
        
        // Fallback: Try common installation paths
        let commonPaths = [
            "/Applications/Xcode.app",
            "/Applications/Xcode-beta.app",
            "\(NSHomeDirectory())/Applications/Xcode.app"
        ]
        
        for path in commonPaths {
            if FileManager.default.fileExists(atPath: path) {
                let url = URL(fileURLWithPath: path)
                NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
                return
            }
        }
        
        // If still not found, try xcode-select
        if let xcodeSelectPath = getXcodeSelectPath(), FileManager.default.fileExists(atPath: xcodeSelectPath) {
            let url = URL(fileURLWithPath: xcodeSelectPath)
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
            return
        }
        
        // Xcode not found - show alert and open App Store
        showAlertForMissingXcode()
    }
    
    private func getXcodeSelectPath() -> String? {
        let task = Process()
        task.launchPath = "/usr/bin/xcode-select"
        task.arguments = ["-p"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                if !output.isEmpty && !output.contains("command line tools") {
                    return output + "/Contents/MacOS/Xcode"
                }
            }
        } catch {
            print("Error getting xcode-select path: \(error)")
        }
        
        return nil
    }
    
    private func showAlertForMissingXcode() {
        // In a real app, we'd show an alert here
        // For now, just print to console
        print("⚠️ Xcode not found. Please install Xcode from the App Store.")
        
        // Open App Store Xcode page as fallback
        if let appStoreURL = URL(string: "https://apps.apple.com/us/app/xcode/id497768473?mt=12") {
            NSWorkspace.shared.open(appStoreURL)
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
