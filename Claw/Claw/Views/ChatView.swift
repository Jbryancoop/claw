import SwiftUI

struct ChatView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @StateObject private var voiceManager = VoiceManager()
    @State private var inputText: String = ""
    @State private var backgroundMode: Bool = false
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 8) {
                            ForEach(viewModel.messages) { message in
                                ChatBubbleView(message: message, voiceManager: voiceManager)
                                    .id(message.id)
                            }

                            if viewModel.isLoading {
                                LoadingBubbleView(
                                    steps: viewModel.agentSteps,
                                    elapsedSeconds: viewModel.elapsedSeconds
                                )
                                .id("loading-indicator")
                                .transition(.opacity)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                    .onTapGesture {
                        isInputFocused = false
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        if let last = viewModel.messages.last {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo(last.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: viewModel.isLoading) { _, isLoading in
                        if isLoading {
                            withAnimation(.easeOut(duration: 0.2)) {
                                proxy.scrollTo("loading-indicator", anchor: .bottom)
                            }
                        }
                    }
                }

                // Background mode toggle (above input bar)
                if !inputText.isEmpty {
                    HStack {
                        Image(systemName: backgroundMode ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(backgroundMode ? ClawTheme.accent : ClawTheme.textTertiary)
                        Text("Run in background & notify")
                            .font(.caption)
                            .foregroundStyle(ClawTheme.textSecondary)
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .background(backgroundMode ? ClawTheme.surfaceElevated : Color.clear)
                    .onTapGesture {
                        backgroundMode.toggle()
                    }
                }
                
                // Input bar
                HStack(spacing: 8) {
                    // Mic button
                    Button {
                        if voiceManager.isListening {
                            voiceManager.stopListening()
                            if !voiceManager.transcript.isEmpty {
                                inputText = voiceManager.transcript
                            }
                        } else {
                            voiceManager.startListening()
                        }
                    } label: {
                        Image(systemName: voiceManager.isListening ? "mic.fill" : "mic")
                            .font(.title3)
                            .foregroundStyle(voiceManager.isListening ? .red : ClawTheme.accent)
                    }

                    TextField(voiceManager.isListening ? "Listening..." : "Send a command...", text: $inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .foregroundStyle(ClawTheme.textPrimary)
                        .lineLimit(1...4)
                        .focused($isInputFocused)
                        .onSubmit { send() }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(ClawTheme.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .tint(ClawTheme.accent)

                    Button(action: send) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(canSend ? ClawTheme.accent : ClawTheme.textTertiary)
                    }
                    .disabled(!canSend)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(
                    VStack(spacing: 0) {
                        ClawTheme.border.frame(height: 0.5)
                        Spacer()
                    }
                    .background(ClawTheme.surface)
                )
                .onChange(of: voiceManager.transcript) { _, newValue in
                    if voiceManager.isListening {
                        inputText = newValue
                    }
                }
            }
            .background(ClawTheme.background)
            .navigationTitle("Claw")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button("Clear History", role: .destructive) {
                            viewModel.clearHistory()
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isLoading
    }

    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        let runInBackground = backgroundMode
        inputText = ""
        backgroundMode = false
        
        if runInBackground {
            Task { await viewModel.sendInBackground(text) }
        } else {
            Task { await viewModel.send(text) }
        }
    }
}

#Preview {
    ChatView()
        .environmentObject(ChatViewModel())
}
