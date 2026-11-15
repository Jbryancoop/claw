import SwiftUI
import PhotosUI

struct ChatView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @StateObject private var voiceManager = VoiceManager()
    @State private var inputText: String = ""
    @State private var backgroundMode: Bool = false
    @State private var showScrollButton = false
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var pendingImageData: Data?
    @State private var pendingImagePreview: UIImage?
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ZStack(alignment: .bottomTrailing) {
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

                                // Invisible anchor at the very bottom
                                Color.clear.frame(height: 1).id("bottom-anchor")
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                        .onTapGesture {
                            isInputFocused = false
                        }
                        .onAppear {
                            // Delay to let messages load from UserDefaults first
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                scrollToBottom(proxy: proxy, animated: false)
                            }
                        }
                        .onChange(of: viewModel.messages.count) { old, new in
                            if new > old {
                                scrollToBottom(proxy: proxy, animated: true)
                            }
                        }
                        .onChange(of: viewModel.isLoading) { _, isLoading in
                            if isLoading {
                                scrollToBottom(proxy: proxy, animated: true)
                            }
                        }
                        .onScrollGeometryChange(for: Bool.self) { geo in
                            let distanceFromBottom = geo.contentSize.height - geo.contentOffset.y - geo.containerSize.height
                            return distanceFromBottom > 80
                        } action: { old, isScrolledUp in
                            guard old != isScrolledUp else { return }
                            withAnimation { showScrollButton = isScrolledUp }
                        }

                        // Scroll to bottom button
                        if showScrollButton {
                            Button {
                                scrollToBottom(proxy: proxy, animated: true)
                            } label: {
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(ClawTheme.accent)
                                    .frame(width: 44, height: 44)
                                    .background(ClawTheme.surface)
                                    .clipShape(Circle())
                                    .overlay(Circle().stroke(ClawTheme.border, lineWidth: 1))
                                    .shadow(color: .black.opacity(0.4), radius: 6, y: 3)
                            }
                            .padding(.trailing, 16)
                            .padding(.bottom, 12)
                            .transition(.opacity.combined(with: .scale))
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

                // Image preview (above input bar)
                if let preview = pendingImagePreview {
                    HStack {
                        Image(uiImage: preview)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(ClawTheme.border, lineWidth: 1)
                            )

                        Button {
                            pendingImageData = nil
                            pendingImagePreview = nil
                            selectedPhoto = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(ClawTheme.textSecondary)
                        }

                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
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

                    // Photo picker
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Image(systemName: pendingImageData != nil ? "photo.fill" : "photo")
                            .font(.title3)
                            .foregroundStyle(pendingImageData != nil ? ClawTheme.accent : ClawTheme.textSecondary)
                    }
                    .onChange(of: selectedPhoto) { _, newItem in
                        guard let newItem else { return }
                        Task {
                            if let data = try? await newItem.loadTransferable(type: Data.self) {
                                pendingImageData = data
                                pendingImagePreview = UIImage(data: data)
                            }
                        }
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
        let hasText = !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let hasImage = pendingImageData != nil
        return (hasText || hasImage) && !viewModel.isLoading
    }

    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        let imageData = pendingImageData
        guard !text.isEmpty || imageData != nil else { return }
        let runInBackground = backgroundMode
        inputText = ""
        backgroundMode = false
        pendingImageData = nil
        pendingImagePreview = nil
        selectedPhoto = nil

        if runInBackground {
            Task { await viewModel.sendInBackground(text, imageData: imageData) }
        } else {
            Task { await viewModel.send(text, imageData: imageData) }
        }
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool) {
        if animated {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo("bottom-anchor", anchor: .bottom)
            }
        } else {
            proxy.scrollTo("bottom-anchor", anchor: .bottom)
        }
        withAnimation { showScrollButton = false }
    }
}

#Preview {
    ChatView()
        .environmentObject(ChatViewModel())
}
