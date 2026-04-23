import SwiftUI

/// Extended PurchaseDialogView with Gumroad support
struct PurchaseDialogView_Extended: View {
    @State private var licenseKey = ""
    @State private var isActivating = false
    @State private var activationSuccess = false
    @State private var activationError = ""
    @State private var showLicenseEntry = false
    @State private var selectedVendor: Vendor? = nil
    
    enum Vendor {
        case lemonSqueezy
        case gumroad
    }
    
    let onActivate: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "lock.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Trial Period Expired")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Your 30-day free trial has ended. Purchase a license to continue using SwiftMentor.")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                // LemonSqueezy Button
                Button(action: { selectedVendor = .lemonSqueezy; openLemonSqueezy() }) {
                    HStack {
                        Image(systemName: "cart")
                        Text("Buy with LemonSqueezy")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                // Gumroad Button
                Button(action: { selectedVendor = .gumroad; openGumroad() }) {
                    HStack {
                        Image(systemName: "bag")
                        Text("Buy with Gumroad")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .buttonStyle(.plain)
                
                // Enter License Key
                if showLicenseEntry {
                    VStack(spacing: 8) {
                        TextField("License Key", text: $licenseKey)
                            .textFieldStyle(.roundedBorder)
                            .disabled(isActivating)
                        
                        Button(action: activateLicense) {
                            if isActivating {
                                ProgressView().scaleEffect(0.8)
                            } else {
                                Text("Activate License")
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isActivating || licenseKey.isEmpty)
                        
                        if !activationError.isEmpty {
                            Text(activationError).font(.caption).foregroundColor(.red)
                        }
                        if activationSuccess {
                            Text("✓ License activated!").font(.caption).foregroundColor(.green)
                        }
                    }
                    .padding(.top, 8)
                } else {
                    Button(action: { showLicenseEntry = true }) {
                        Text("Already have a license key?").foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top)
            Spacer()
        }
        .padding()
        .frame(width: 450, height: 550)
    }
    
    private func openLemonSqueezy() {
        if let url = URL(string: "https://app.lemonsqueezy.com/products/996638") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func openGumroad() {
        // Replace with your actual Gumroad link when you have it
        if let url = URL(string: "https://gumroad.com/l/swiftmentor") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func activateLicense() {
        isActivating = true
        activationError = ""
        activationSuccess = false
        
        DispatchQueue.global().async {
            var license: LicenseKey?
            
            // Check if it's a Gumroad key
            if LicenseKeyManager.shared.isGumroadKey(licenseKey) {
                license = LicenseKeyManager.shared.validateGumroadKey(licenseKey)
            } else {
                license = LicenseKeyManager.shared.validateKey(licenseKey)
            }
            
            DispatchQueue.main.async {
                isActivating = false
                if let validLicense = license, validLicense.isValid {
                    LicenseKeyManager.shared.storeLicenseKey(licenseKey)
                    activationSuccess = true
                    onActivate()
                } else {
                    activationError = "Invalid license key."
                }
            }
        }
    }
}

#Preview {
    PurchaseDialogView_Extended(onActivate: {})
}
