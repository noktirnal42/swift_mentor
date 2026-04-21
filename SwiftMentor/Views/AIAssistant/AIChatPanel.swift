import SwiftUI

struct AIChatPanel: View {
    @StateObject private var viewModel = AIAssistantViewModel()
    @State private var showSessionList = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            headerView

            Divider()

            if viewModel.isLoading && viewModel.messages.isEmpty {
                loadingView
            } else if viewModel.messages.isEmpty {
                emptyStateView
            } else {
                messagesView
            }

            Divider()

            inputView
        }
        .frame(minWidth: 400, idealWidth: 500, maxWidth: 600, minHeight: 500)
        .toolbar {
            ToolbarItemGroup(placement: .automatic) {
                Button(action: { showSessionList = true }) {
                    Image(systemName: "sidebar.left")
                }
                .help("Chat Sessions")

                Button(action: { viewModel.clearChat() }) {
                    Image(systemName: "trash")
                }
                .help("Clear Chat")
            }
        }
        .onAppear {
            viewModel.loadSessions()
        }
    }

    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("AI Coding Assistant")
                    .font(.headline)
                HStack(spacing: 6) {
                    Circle()
                        .fill(viewModel.isConnected ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(viewModel.isConnected ? "Connected" : "Disconnected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            Menu {
                ForEach(viewModel.availableModels, id: \.self) { model in
                    Button(model) { }
                }
            } label: {
                HStack {
                    Text("llama3")
                        .font(.caption)
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
            }
            .disabled(!viewModel.isConnected)
        }
        .padding()
    }

    private var loadingView: some View {
        VStack {
            ProgressView()
                .scaleEffect(1.5)
            Text("Connecting to AI service...")
                .foregroundColor(.secondary)
                .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "brain")
                .font(.system(size: 60))
                .foregroundColor(.secondary)

            Text("Ask me anything about Swift!")
                .font(.title3)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Try asking:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                ForEach([
                    "How do I use @State in SwiftUI?",
                    "Explain closures in Swift",
                    "How do I create a Metal shader?"
                ], id: \.self) { question in
                    Button(action: {
                        viewModel.inputText = question
                        Task { await viewModel.sendMessage() }
                    }) {
                        Text(question)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
            .cornerRadius(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var messagesView: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 16) {
                    ForEach(viewModel.messages) { message in
                        MessageBubble(message: message)
                            .id(message.id)
                    }
                }
                .padding()
            }
            .onChange(of: viewModel.messages.count) { _, _ in
                if let lastMessage = viewModel.messages.last {
                    withAnimation {
                        proxy.scrollTo(lastMessage.id, anchor: .bottom)
                    }
                }
            }
        }
    }

    private var inputView: some View {
        HStack(spacing: 12) {
            TextField("Ask about Swift, iOS, macOS development...", text: $viewModel.inputText, axis: .vertical)
                .textFieldStyle(.plain)
                .lineLimit(1...4)
                .focused($isInputFocused)

            Button(action: {
                Task { await viewModel.sendMessage() }
            }) {
                Image(systemName: "paperplane.fill")
            }
            .disabled(viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isLoading)
            .keyboardShortcut(.return, modifiers: .command)
        }
        .padding()
    }
}

struct MessageBubble: View {
    let message: AIMessage

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
                Text(message.content)
                    .font(.body)

                if !message.codeBlocks.isEmpty {
                    ForEach(message.codeBlocks, id: \.self) { block in
                        CodeBlockView(code: block, language: "swift")
                    }
                }
            }
            .padding(12)
            .background(isUser ? Color.blue : Color(nsColor: .controlBackgroundColor))
            .foregroundColor(isUser ? .white : .primary)
            .cornerRadius(16)

            if !isUser { Spacer(minLength: 60) }
        }
    }
}

#Preview {
    AIChatPanel()
}