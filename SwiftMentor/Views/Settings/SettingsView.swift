import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()
    @State private var showLicenseEntry = false
    @State private var licenseKey = ""
    @State private var activationError = ""
    @State private var activationSuccess = false
    
    var body: some View {
        Form {
            // LICENSING SECTION - NEW!
            Section("Licensing") {
                if LicenseKeyManager.shared.hasValidLicense() {
                    Label("License Status", systemImage: "checkmark.seal.fill")
                        .foregroundColor(.green)
                    Text("License Active")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Button(action: deactivateLicense) {
                        Text("Deactivate License")
                    }
                } else {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.orange)
                        Text("Trial Period")
                    }
                    
                    if !TrialManager.shared.isTrialExpired() {
                        Text("\(TrialManager.shared.daysRemaining()) days remaining")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Trial Expired")
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    
                    HStack {
                        Button(action: openLemonSqueezy) {
                            Label("Purchase License", systemImage: "cart")
                        }
                        
                        Button(action: { showLicenseEntry = true }) {
                            Label("Enter License", systemImage: "key")
                        }
                    }
                    
                    if showLicenseEntry {
                        VStack(spacing: 8) {
                            TextField("License Key", text: $licenseKey)
                                .textFieldStyle(.roundedBorder)
                            
                            HStack {
                                Button(action: activateLicense) {
                                    Text("Activate")
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(licenseKey.isEmpty)
                                
                                Spacer()
                                
                                if activationSuccess {
                                    Text("✓ Activated!")
                                        .foregroundColor(.green)
                                        .font(.caption)
                                }
                            }
                            
                            if !activationError.isEmpty {
                                Text(activationError)
                                    .foregroundColor(.red)
                                    .font(.caption)
                            }
                        }
                        .padding(.top, 8)
                    }
                }
            }
            
            // Existing sections
            Section("Appearance") {
                Picker("Theme", selection: $viewModel.settings.appearance) {
                    ForEach(viewModel.appearanceModes, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
            }
            
            Section("Code Editor") {
                HStack {
                    Text("Font Size")
                    Spacer()
                    Stepper("\(viewModel.settings.codeEditorFontSize)", value: $viewModel.settings.codeEditorFontSize, in: 10...24)
                }
                Toggle("Show Line Numbers", isOn: $viewModel.settings.showLineNumbers)
                Toggle("Enable Autocomplete", isOn: $viewModel.settings.enableAutocomplete)
            }
            
            Section("AI Assistant") {
                HStack {
                    Text("Provider")
                    Spacer()
                    Picker("", selection: $viewModel.aiConfiguration.provider) {
                        Text("Ollama").tag(AIProvider.ollama)
                        Text("LM Studio").tag(AIProvider.lmStudio)
                        Text("Both (Auto-detect)").tag(AIProvider.both)
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 250)
                }
                
                HStack {
                    Text("Ollama Endpoint")
                    Spacer()
                    TextField("http://localhost:11434", text: $viewModel.aiConfiguration.ollamaEndpoint)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)
                }
                
                HStack {
                    Text("LM Studio Endpoint")
                    Spacer()
                    TextField("http://localhost:1234", text: $viewModel.aiConfiguration.lmStudioEndpoint)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 200)
                }
                
                Picker("Model", selection: $viewModel.aiConfiguration.selectedModel) {
                    ForEach(viewModel.aiConfiguration.availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }
                
                HStack {
                    Text("Temperature")
                    Slider(value: $viewModel.aiConfiguration.temperature, in: 0...1)
                    Text(String(format: "%.1f", viewModel.aiConfiguration.temperature))
                        .frame(width: 40)
                }
                
                HStack {
                    Text("Max Tokens")
                    Stepper("\(viewModel.aiConfiguration.maxTokens)", value: $viewModel.aiConfiguration.maxTokens, in: 256...8192, step: 256)
                }
                
                Button(action: {
                    Task { await viewModel.testAIConnection() }
                }) {
                    HStack {
                        Text("Test Connection")
                        if viewModel.isTestingConnection {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
    }
    
    private func openLemonSqueezy() {
        if let url = URL(string: "https://app.lemonsqueezy.com/products/996638") {
            NSWorkspace.shared.open(url)
        }
    }
    
    private func activateLicense() {
        activationError = ""
        activationSuccess = false
        
        let license = LicenseKeyManager.shared.validateKey(licenseKey)
        
        if license.isValid {
            LicenseKeyManager.shared.storeLicenseKey(licenseKey)
            activationSuccess = true
            activationError = ""
        } else {
            activationError = "Invalid license key. Please check and try again."
        }
    }
    
    private func deactivateLicense() {
        LicenseKeyManager.shared.removeLicenseKey()
    }
}

#Preview {
    SettingsView()
}
