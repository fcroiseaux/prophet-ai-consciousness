import SwiftUI

struct ProphetEditView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel = ProphetEditViewModel()
    
    let prophet: Prophet?
    
    @State private var name = ""
    @State private var systemPrompt = ""
    @State private var selectedVoice: ElevenLabsVoice?
    @State private var selectedIcon = "person.circle.fill"
    @State private var voiceSpeed = 1.0
    
    private let iconOptions = [
        "person.circle.fill",
        "brain.head.profile",
        "sparkles",
        "wand.and.stars",
        "eye.fill",
        "bolt.fill",
        "flame.fill",
        "moon.stars.fill",
        "sun.max.fill",
        "star.fill"
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Prophet Details") {
                    TextField("Name", text: $name)
                    
                    VStack(alignment: .leading) {
                        Text("System Prompt")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextEditor(text: $systemPrompt)
                            .frame(minHeight: 100)
                    }
                }
                
                Section("Icon") {
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5)) {
                        ForEach(iconOptions, id: \.self) { icon in
                            Image(systemName: icon)
                                .font(.title)
                                .foregroundColor(selectedIcon == icon ? .white : .accentColor)
                                .frame(width: 50, height: 50)
                                .background(selectedIcon == icon ? Color.accentColor : Color.gray.opacity(0.2))
                                .cornerRadius(10)
                                .onTapGesture {
                                    selectedIcon = icon
                                }
                        }
                    }
                }
                
                Section("Voice") {
                    if viewModel.isLoadingVoices {
                        HStack {
                            ProgressView()
                            Text("Loading voices...")
                                .foregroundColor(.secondary)
                        }
                    } else if viewModel.voices.isEmpty {
                        Text("No voices available. Check your ElevenLabs API key.")
                            .foregroundColor(.secondary)
                    } else {
                        Picker("Select Voice", selection: $selectedVoice) {
                            Text("Select a voice").tag(Optional<ElevenLabsVoice>.none)
                            ForEach(viewModel.voices) { voice in
                                Text(voice.name).tag(Optional(voice))
                            }
                        }
                        .pickerStyle(.menu)
                        
                        VStack(alignment: .leading) {
                            Text("Voice Speed: \(String(format: "%.1fx", voiceSpeed))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Slider(value: $voiceSpeed, in: 0.5...2.0, step: 0.1)
                        }
                    }
                }
            }
            .navigationTitle(prophet == nil ? "New Prophet" : "Edit Prophet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { saveProphet() }
                        .disabled(name.isEmpty || systemPrompt.isEmpty || selectedVoice == nil)
                }
            }
        }
        .onAppear {
            if let prophet = prophet {
                name = prophet.name
                systemPrompt = prophet.systemPrompt
                selectedIcon = prophet.iconName ?? "person.circle.fill"
                voiceSpeed = prophet.voiceSpeed
                
                Task {
                    await viewModel.loadVoices()
                    selectedVoice = viewModel.voices.first { $0.voice_id == prophet.elevenLabsVoiceId }
                }
            } else {
                Task {
                    await viewModel.loadVoices()
                }
            }
        }
    }
    
    private func saveProphet() {
        guard let voice = selectedVoice else { return }
        
        if let existingProphet = prophet {
            var updated = existingProphet
            updated.name = name
            updated.systemPrompt = systemPrompt
            updated.elevenLabsVoiceId = voice.voice_id
            updated.iconName = selectedIcon
            updated.voiceSpeed = voiceSpeed
            updated.updatedAt = Date()
            viewModel.updateProphet(updated)
        } else {
            let newProphet = Prophet(
                name: name,
                systemPrompt: systemPrompt,
                elevenLabsVoiceId: voice.voice_id,
                iconName: selectedIcon,
                voiceSpeed: voiceSpeed
            )
            viewModel.addProphet(newProphet)
        }
        
        dismiss()
    }
}

@MainActor
class ProphetEditViewModel: ObservableObject {
    @Published var voices: [ElevenLabsVoice] = []
    @Published var isLoadingVoices = false
    
    private let prophetStore = ProphetStore.shared
    private let elevenLabsService = ElevenLabsService.shared
    
    func loadVoices() async {
        isLoadingVoices = true
        do {
            voices = try await elevenLabsService.getVoices()
        } catch {
            print("Failed to load voices: \(error)")
        }
        isLoadingVoices = false
    }
    
    func addProphet(_ prophet: Prophet) {
        prophetStore.addProphet(prophet)
    }
    
    func updateProphet(_ prophet: Prophet) {
        prophetStore.updateProphet(prophet)
    }
}