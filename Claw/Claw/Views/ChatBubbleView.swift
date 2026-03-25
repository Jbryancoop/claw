import SwiftUI

struct ChatBubbleView: View {
    let message: Message
    var voiceManager: VoiceManager?
    @State private var showCopied = false

    private var isUser: Bool { message.role == .user }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 60) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 2) {
                Group {
                    if isUser {
                        Text(message.content)
                    } else {
                        MarkdownView(message.content, font: .callout)
                    }
                }
                .textSelection(.enabled)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isUser ? Color.blue : Color(.systemGray5))
                .foregroundStyle(isUser ? .white : .primary)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                    .contextMenu {
                        Button {
                            UIPasteboard.general.string = message.content
                            showCopied = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                showCopied = false
                            }
                        } label: {
                            Label("Copy", systemImage: "doc.on.doc")
                        }
                        if !isUser, let vm = voiceManager {
                            Button {
                                Task { await vm.speak(message.content) }
                            } label: {
                                Label("Read Aloud", systemImage: "speaker.wave.2")
                            }
                        }
                    }
                    .overlay(alignment: .center) {
                        if showCopied {
                            Text("Copied")
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .transition(.opacity)
                        }
                    }
                    .animation(.easeInOut(duration: 0.2), value: showCopied)

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 4)
            }

            if !isUser { Spacer(minLength: 60) }
        }
    }
}

#Preview {
    VStack {
        ChatBubbleView(message: Message(role: .user, content: "Hello server"), voiceManager: nil)
        ChatBubbleView(message: Message(role: .server, content: "Command received."), voiceManager: nil)
    }
    .padding()
}
