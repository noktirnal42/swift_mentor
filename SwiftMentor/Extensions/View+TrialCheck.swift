import SwiftUI

/// Extension to check trial status in any view
extension View {
    func trialCheck() -> some View {
        self.modifier(TrialCheckModifier())
    }
}

struct TrialCheckModifier: ViewModifier {
    @State private var showPurchaseDialog = false
    @State private var trialExpired = false
    
    func body(content: Content) -> some View {
        content
            .onAppear {
                checkTrial()
            }
            .sheet(isPresented: $showPurchaseDialog) {
                PurchaseDialogView(onActivate: {
                    showPurchaseDialog = false
                    trialExpired = false
                })
            }
    }
    
    private func checkTrial() {
        if TrialManager.shared.isTrialExpired() && !LicenseKeyManager.shared.hasValidLicense() {
            showPurchaseDialog = true
        }
    }
}
