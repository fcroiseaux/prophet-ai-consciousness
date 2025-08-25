import SwiftUI

struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var messageText = ""
    
    var body: some View {
        NavigationStack {
            VStack {
                if viewModel.selectedProphet == nil {
                    ContentUnavailableView(
                        "Select a Prophet",
                        systemImage: "message",
                        description: Text("Choose a prophet to start chatting")
                    )
                } else {
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 12) {
                                ForEach(viewModel.messages) { message in
                                    MessageBubble(message: message)
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
                        TextField("Type a message...", text: $messageText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .disabled(viewModel.isProcessing)
                        
                        Button(action: sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(messageText.isEmpty || viewModel.isProcessing ? .gray : .accentColor)
                        }
                        .disabled(messageText.isEmpty || viewModel.isProcessing)
                    }
                    .padding()
                }
            }
            .navigationTitle("Chat")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(viewModel.prophets) { prophet in
                            Button(prophet.name) {
                                viewModel.selectProphet(prophet)
                            }
                        }
                    } label: {
                        HStack {
                            Text(viewModel.selectedProphet?.name ?? "Select Prophet")
                            Image(systemName: "chevron.down")
                        }
                    }
                }
            }
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        Task {
            await viewModel.sendMessage(messageText)
            messageText = ""
        }
    }
}

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            if message.content.contains("is thinking...") {
                // Special styling for thinking indicator
                HStack {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text(message.content)
                        .italic()
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .foregroundColor(.secondary)
                .cornerRadius(16)
            } else {
                Text(message.content)
                    .padding()
                    .background(message.isUser ? Color.accentColor : Color.gray.opacity(0.2))
                    .foregroundColor(message.isUser ? .white : .primary)
                    .cornerRadius(16)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.75, alignment: message.isUser ? .trailing : .leading)
            }
            
            if !message.isUser { Spacer() }
        }
    }
}