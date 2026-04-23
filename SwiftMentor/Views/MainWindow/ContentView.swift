import SwiftUI
import AppKit

struct ContentView: View {
    @EnvironmentObject private var appState: AppState
    @State private var columnVisibility: NavigationSplitViewVisibility = .all
    @State private var showPurchaseDialog = false
    @State private var trialExpired = false
    
    var body: some View {
        ZStack {
            GlassBackground(material: .content)
            
            NavigationSplitView(columnVisibility: $columnVisibility) {
                SidebarView()
            } detail: {
                detailView
            }
            .navigationSplitViewStyle(.balanced)
            .sheet(isPresented: $appState.showingSearch) {
                SearchView()
            }
            .sheet(isPresented: $appState.showAIAssistant) {
                AIChatPanel()
                    .frame(minWidth: 400, idealWidth: 500, maxWidth: 600)
            }
            .sheet(isPresented: $showPurchaseDialog) {
                PurchaseDialogView(onActivate: {
                    showPurchaseDialog = false
                    trialExpired = false
                })
                .frame(width: 450, height: 550)
            }
        }
        .onAppear {
            checkTrialStatus()
        }
    }
    
    private func checkTrialStatus() {
        // Check if trial has expired and no valid license
        let trialManager = TrialManager.shared
        let licenseManager = LicenseKeyManager.shared
        
        if trialManager.isTrialExpired() && !licenseManager.hasValidLicense() {
            showPurchaseDialog = true
            trialExpired = true
        }
    }
    
    @ViewBuilder
    private var detailView: some View {
        switch appState.selectedSection {
        case .dashboard:
            DashboardView()
        case .learningPaths:
            LearningPathsView()
        case .playground, .playgroundDetail:
            CodePlaygroundView()
        case .progress:
            ProgressView_()
        case .snippets:
            SnippetLibraryView()
        case .settings:
            SettingsView()
        case .aiAssistant:
            AIChatPanel()
        case .help:
            OnboardingView()
        case .debug:
            SettingsView()
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState.shared)
}
