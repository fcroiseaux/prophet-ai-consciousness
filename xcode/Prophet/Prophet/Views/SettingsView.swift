import SwiftUI

struct SettingsView: View {
    @State private var openAIKey = APIConfiguration.openAIAPIKey
    @State private var elevenLabsKey = APIConfiguration.elevenLabsAPIKey
    @State private var useStreaming = APIConfiguration.useStreaming
    @State private var selectedLanguage = APIConfiguration.selectedLanguage
    @State private var showingAPIKeySaved = false
    @State private var showingReinitializeConfirmation = false
    @State private var showingReinitializeSuccess = false
    
    @ObservedObject private var prophetStore = ProphetStore.shared
    
    private let availableLanguages = [
        "English", "Français", "Español", "Deutsch", "Italiano",
        "Português", "Nederlands", "Polski", "Русский", "日本語",
        "中文", "한국어", "العربية", "हिन्दी", "Türkçe"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("API Keys") {
                    VStack(alignment: .leading) {
                        Text("OpenAI API Key")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SecureField("sk-...", text: $openAIKey)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("ElevenLabs API Key")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        SecureField("API Key", text: $elevenLabsKey)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    Button("Save API Keys") {
                        saveAPIKeys()
                    }
                    .frame(maxWidth: .infinity)
                    .buttonStyle(.borderedProminent)
                }
                
                Section("Audio Settings") {
                    Toggle("Enable Low Latency Audio", isOn: $useStreaming)
                        .onChange(of: useStreaming) { _, newValue in
                            APIConfiguration.setUseStreaming(newValue)
                        }
                    
                    Text("Splits responses into sentences for faster playback start")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Language Settings") {
                    Picker("Prophet Language", selection: $selectedLanguage) {
                        ForEach(availableLanguages, id: \.self) { language in
                            Text(language).tag(language)
                        }
                    }
                    .onChange(of: selectedLanguage) { _, newValue in
                        APIConfiguration.setSelectedLanguage(newValue)
                    }
                    
                    Text("Prophets will respond in the selected language")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Section("Prophet Management") {
                    Button(action: { showingReinitializeConfirmation = true }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Reinitialize Prophets from JSON")
                        }
                        .foregroundColor(.red)
                    }
                }
                
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("OpenAI Documentation", destination: URL(string: "https://platform.openai.com/docs")!)
                    Link("ElevenLabs Documentation", destination: URL(string: "https://docs.elevenlabs.io")!)
                }
            }
            .navigationTitle("Settings")
            .alert("API Keys Saved", isPresented: $showingAPIKeySaved) {
                Button("OK") { }
            } message: {
                Text("Your API keys have been securely saved.")
            }
            .alert("Reinitialize Prophets?", isPresented: $showingReinitializeConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reinitialize", role: .destructive) {
                    reinitializeProphets()
                }
            } message: {
                Text("This will replace all existing prophets with the ones from prophets.json. This action cannot be undone.")
            }
            .alert("Prophets Reinitialized", isPresented: $showingReinitializeSuccess) {
                Button("OK") { }
            } message: {
                Text("The prophets list has been successfully reinitialized from prophets.json.")
            }
        }
    }
    
    private func saveAPIKeys() {
        APIConfiguration.setOpenAIAPIKey(openAIKey)
        APIConfiguration.setElevenLabsAPIKey(elevenLabsKey)
        showingAPIKeySaved = true
    }
    
    private func reinitializeProphets() {
        prophetStore.reinitializeFromJSON()
        showingReinitializeSuccess = true
    }
}