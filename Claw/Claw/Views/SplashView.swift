import SwiftUI

/// A single diagonal claw scratch mark shape
struct ClawScratchLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        return path
    }
}

struct SplashView: View {
    @State private var line1Progress: CGFloat = 0
    @State private var line2Progress: CGFloat = 0
    @State private var line3Progress: CGFloat = 0
    @State private var textOpacity: Double = 0
    @State private var glowOpacity: Double = 0

    private let lineWidth: CGFloat = 5
    private let scratchLength: CGFloat = 120
    private let spacing: CGFloat = 22

    var body: some View {
        ZStack {
            ClawTheme.background
                .ignoresSafeArea()

            VStack(spacing: 32) {
                // Claw scratch marks
                ZStack {
                    // Glow layer behind the lines
                    scratchMarks(
                        p1: line1Progress,
                        p2: line2Progress,
                        p3: line3Progress
                    )
                    .blur(radius: 12)
                    .opacity(glowOpacity * 0.5)

                    // Main lines
                    scratchMarks(
                        p1: line1Progress,
                        p2: line2Progress,
                        p3: line3Progress
                    )
                }
                .frame(width: scratchLength + spacing * 2, height: scratchLength)

                // "CLAW" text
                Text("CLAW")
                    .font(.system(size: 36, weight: .bold, design: .monospaced))
                    .foregroundStyle(ClawTheme.accent)
                    .opacity(textOpacity)
                    .shadow(color: ClawTheme.accent.opacity(0.4), radius: 8)
            }
        }
        .onAppear {
            // Line 1 draws
            withAnimation(.easeOut(duration: 0.4)) {
                line1Progress = 1
            }
            // Line 2 draws after a delay
            withAnimation(.easeOut(duration: 0.4).delay(0.25)) {
                line2Progress = 1
            }
            // Line 3 draws after a longer delay
            withAnimation(.easeOut(duration: 0.4).delay(0.5)) {
                line3Progress = 1
            }
            // Glow builds up
            withAnimation(.easeIn(duration: 0.8).delay(0.3)) {
                glowOpacity = 1
            }
            // Text fades in after lines finish
            withAnimation(.easeIn(duration: 0.6).delay(1.1)) {
                textOpacity = 1
            }
        }
    }

    @ViewBuilder
    private func scratchMarks(p1: CGFloat, p2: CGFloat, p3: CGFloat) -> some View {
        Canvas { context, size in
            let centerX = size.width / 2
            let offsets: [CGFloat] = [-spacing, 0, spacing]
            let progresses = [p1, p2, p3]

            for (i, offset) in offsets.enumerated() {
                let startX = centerX + offset - scratchLength / 2 * 0.3
                let startY: CGFloat = 0
                let endX = centerX + offset + scratchLength / 2 * 0.3
                let endY = size.height

                var path = Path()
                path.move(to: CGPoint(x: startX, y: startY))
                path.addLine(to: CGPoint(x: endX, y: endY))

                let trimmed = path.trimmedPath(from: 0, to: progresses[i])

                context.stroke(
                    trimmed,
                    with: .color(ClawTheme.accent),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
            }
        }
    }
}

#Preview {
    SplashView()
}
