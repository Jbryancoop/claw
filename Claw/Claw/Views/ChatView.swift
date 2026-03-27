import SwiftUI

struct ChatView: View {
    @EnvironmentObject var viewModel: ChatViewModel
    @State private var inputText: String = ""
    @State private var isAtBottom: Bool = true
    @State private var lastMessageCount: Int = 0
    @FocusState private var isInputFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages
                ScrollViewReader { proxy in
                    ZStack(alignment: .bottomTrailing) {
                        ScrollView {
                            VStack(spacing: 8) {
                                ForEach(viewModel.messages) { message in
                                    ChatBubbleView(message: message)
                                        .id(message.id)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                            .padding(.bottom, 4)

                            // Bottom anchor — tracks whether we're scrolled down
                            GeometryReader { geo in
                                Color.clear
                                    .preference(
                                        key: BottomVisibleKey.self,
                                        value: geo.frame(in: .named("chatScroll")).maxY
                                    )
                            }
                            .frame(height: 1)
                            .id("bottom")
                        }
                        .coordinateSpace(name: "chatScroll")
                        .onPreferenceChange(BottomVisibleKey.self) { maxY in
                            // If the bottom anchor's maxY is within the visible scroll area
                            // (plus a small margin), we're at the bottom
                            isAtBottom = maxY < UIScreen.main.bounds.height + 100
                        }

                        // Scroll-to-bottom button
                        if !isAtBottom {
                            Button {
                                withAnimation(.easeOut(duration: 0.2)) {
                                    proxy.scrollTo("bottom", anchor: .bottom)
                                }
                            } label: {
                                Image(systemName: "arrow.down.circle.fill")
                                    .font(.title)
                                    .foregroundStyle(.white, .blue)
                                    .shadow(radius: 3)
                            }
                            .padding(.trailing, 16)
                            .padding(.bottom, 8)
                            .transition(.opacity.combined(with: .scale))
                        }
                    }
                    .onAppear {
                        scrollToBottom(proxy: proxy, animated: false)
                    }
                    .onChange(of: viewModel.messages.count) { _, newCount in
                        // Auto-scroll when new messages arrive (if we were near the bottom)
                        if isAtBottom || newCount > lastMessageCount {
                            scrollToBottom(proxy: proxy, animated: true)
                        }
                        lastMessageCount = newCount
                    }
                }

                // Input bar
                HStack(spacing: 8) {
                    TextField("Send a command...", text: $inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .lineLimit(1...4)
                        .focused($isInputFocused)
                        .onSubmit { send() }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 20))

                    Button(action: send) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundStyle(canSend ? .blue : .gray)
                    }
                    .disabled(!canSend)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(.bar)
            }
            .navigationTitle("Claw")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var canSend: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !viewModel.isLoading
    }

    private func send() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        inputText = ""
        Task { await viewModel.send(text) }
    }

    private func scrollToBottom(proxy: ScrollViewProxy, animated: Bool) {
        guard !viewModel.messages.isEmpty else { return }
        if animated {
            withAnimation(.easeOut(duration: 0.2)) {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        } else {
            proxy.scrollTo("bottom", anchor: .bottom)
        }
    }
}

// Preference key to track the bottom anchor's position
private struct BottomVisibleKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    ChatView()
        .environmentObject(ChatViewModel())
}
