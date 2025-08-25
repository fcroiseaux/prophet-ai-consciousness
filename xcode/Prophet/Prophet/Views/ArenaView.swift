import SwiftUI

struct ArenaView: View {
    @StateObject private var viewModel = DualChatViewModel()
    @State private var subject = ""
    @State private var showingSetup = true
    @State private var showingErrorAlert = false
    @Environment(\.tabSelection) private var tabSelection
    
    var body: some View {
        NavigationStack {
            VStack {
                if showingSetup {
                    ArenaSetupView(
                        prophet1: $viewModel.prophet1,
                        prophet2: $viewModel.prophet2,
                        subject: $subject,
                        prophets: viewModel.prophets,
                        onStart: startConversation
                    )
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 12) {
                                ForEach(viewModel.messages) { message in
                                    ArenaMessageBubble(
                                        message: message,
                                        prophet: viewModel.getProphet(for: message)
                                    )
                                    .id(message.id)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: viewModel.messages.count) { _, _ in
                            withAnimation {
                                proxy.scrollTo(viewModel.messages.last?.id)
                            }
                        }
                    }
                    
                    HStack {
                        Button(action: { viewModel.toggleConversation() }) {
                            Image(systemName: viewModel.isConversationActive ? "pause.fill" : "play.fill")
                                .font(.title2)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(viewModel.errorMessage != nil)
                        
                        Button(action: resetConversation) {
                            Text("New Conversation")
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("Arena")
            .alert("Configuration Error", isPresented: $showingErrorAlert) {
                Button("Go to Settings") {
                    tabSelection.wrappedValue = 3 // Settings tab
                    viewModel.clearError()
                }
                Button("Cancel", role: .cancel) {
                    viewModel.clearError()
                }
            } message: {
                Text(viewModel.errorMessage ?? "An error occurred. Please check your API keys in Settings.")
            }
            .onChange(of: viewModel.errorMessage) { _, newValue in
                showingErrorAlert = newValue != nil
            }
        }
    }
    
    private func startConversation() {
        guard viewModel.prophet1 != nil, viewModel.prophet2 != nil, !subject.isEmpty else { return }
        showingSetup = false
        Task {
            await viewModel.startConversation(subject: subject)
        }
    }
    
    private func resetConversation() {
        viewModel.stopConversation()
        viewModel.clearMessages()
        showingSetup = true
        subject = ""
    }
}

struct ArenaSetupView: View {
    @Binding var prophet1: Prophet?
    @Binding var prophet2: Prophet?
    @Binding var subject: String
    let prophets: [Prophet]
    let onStart: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Setup Arena")
                .font(.largeTitle)
                .bold()
            
            VStack(alignment: .leading, spacing: 16) {
                Text("Select Two Prophets")
                    .font(.headline)
                
                HStack {
                    Picker("Prophet 1", selection: $prophet1) {
                        Text("Select Prophet").tag(Optional<Prophet>.none)
                        ForEach(prophets) { prophet in
                            Text(prophet.name).tag(Optional(prophet))
                        }
                    }
                    .pickerStyle(.menu)
                    
                    Image(systemName: "arrow.left.arrow.right")
                        .font(.title2)
                    
                    Picker("Prophet 2", selection: $prophet2) {
                        Text("Select Prophet").tag(Optional<Prophet>.none)
                        ForEach(prophets) { prophet in
                            if prophet.id != prophet1?.id {
                                Text(prophet.name).tag(Optional(prophet))
                            }
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                Text("Conversation Topic")
                    .font(.headline)
                
                TextField("Enter a topic for discussion...", text: $subject, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(3...6)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)
            
            Button(action: onStart) {
                Text("Start Conversation")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(prophet1 == nil || prophet2 == nil || subject.isEmpty)
            
            Spacer()
        }
        .padding()
    }
}

struct ArenaMessageBubble: View {
    let message: Message
    let prophet: Prophet?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let prophet = prophet {
                HStack {
                    Image(systemName: prophet.iconName ?? "person.circle.fill")
                    Text(prophet.name)
                        .font(.caption)
                        .bold()
                }
                .foregroundColor(.secondary)
            }
            
            Text(message.content)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
        }
    }
}