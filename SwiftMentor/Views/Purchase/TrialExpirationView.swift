import SwiftUI

struct TrialExpirationView: View {
    var body: some View {
        VStack(spacing: 20) {
            if TrialManager.shared.isTrialExpired() && !LicenseKeyManager.shared.hasValidLicense() {
                PurchaseDialogView(onActivate: {})
            } else {
                TrialWarningView(daysRemaining: TrialManager.shared.daysRemaining())
            }
        }
    }
}

struct TrialWarningView: View {
    let daysRemaining: Int
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "clock.fill").foregroundColor(.orange)
                Text("Trial: \(daysRemaining) day\(daysRemaining == 1 ? "" : "s") remaining")
                    .fontWeight(.medium)
                Spacer()
                Button("Purchase License") {
                    if let url = URL(string: "https://app.lemonsqueezy.com/products/996638") {
                        NSWorkspace.shared.open(url)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            .background(Color.orange.opacity(0.1))
            .cornerRadius(8)
        }
        .padding()
    }
}

#Preview {
    TrialExpirationView()
}
