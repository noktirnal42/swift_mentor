import SwiftUI

struct SettingsView: View {
    @StateObject private var viewModel = SettingsViewModel()

    var body: some View {
        Form {
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

                Button(action: { Task { await viewModel.testAIConnection() } }) {
                    HStack {
                        Text("Test Connection")
                        if viewModel.isTestingConnection {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    }
                }
                .disabled(viewModel.isTestingConnection)

                if let result = viewModel.connectionTestResult {
                    Text(result)
                        .font(.caption)
                        .foregroundColor(result.contains("success") ? .green : .red)
                }

                Toggle("Enable Inline AI Suggestions", isOn: $viewModel.settings.enableInlineAI)
            }

            Section("Preview") {
                Toggle("Show Preview Panel", isOn: $viewModel.settings.showPreviewPanel)
            }

            Section {
                Button("Reset to Defaults", role: .destructive) {
                    viewModel.resetToDefaults()
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .onChange(of: viewModel.settings) { _, _ in
            viewModel.saveSettings()
        }
        .onChange(of: viewModel.aiConfiguration) { _, _ in
            viewModel.saveAIConfiguration()
        }
    }
}

#Preview {
    SettingsView()
}