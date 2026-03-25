import SwiftUI

struct AgentStep: Codable, Equatable {
    let message: String
    let timestamp: String
}

/// Shows real-time agent progress
struct LoadingBubbleView: View {
    let steps: [AgentStep]
    let elapsedSeconds: Int

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                // Current status with spinner
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(ClawTheme.accent)
                        .scaleEffect(0.8)

                    Text(currentStatus)
                        .font(.system(.callout, design: .monospaced))
                        .foregroundStyle(ClawTheme.accent)
                        .lineLimit(1)
                }

                // Recent completed steps (last 3)
                if steps.count > 1 {
                    let pastSteps = steps.dropLast().suffix(3)
                    ForEach(Array(pastSteps.enumerated()), id: \.offset) { _, step in
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(ClawTheme.accentDim)
                            Text(step.message)
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundStyle(ClawTheme.textTertiary)
                                .lineLimit(1)
                        }
                    }
                }

                // Elapsed time
                Text("\(elapsedSeconds)s elapsed")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundStyle(ClawTheme.textTertiary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(ClawTheme.serverBubble)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer(minLength: 60)
        }
    }

    private var currentStatus: String {
        steps.last?.message ?? "Connecting to agent..."
    }
}

#Preview {
    ZStack {
        ClawTheme.background.ignoresSafeArea()
        LoadingBubbleView(steps: [
            AgentStep(message: "Querying Home Assistant...", timestamp: ""),
            AgentStep(message: "Checking Tesla status...", timestamp: ""),
            AgentStep(message: "Generating response...", timestamp: ""),
        ], elapsedSeconds: 4)
        .padding()
    }
}
