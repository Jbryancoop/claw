import SwiftUI

struct LoadingBubbleView: View {
    @State private var animating = false

    private let dotSize: CGFloat = 8
    private let dotCount = 3

    var body: some View {
        HStack {
            HStack(spacing: 6) {
                ForEach(0..<dotCount, id: \.self) { index in
                    Circle()
                        .fill(ClawTheme.accent)
                        .frame(width: dotSize, height: dotSize)
                        .offset(y: animating ? -6 : 0)
                        .animation(
                            .easeInOut(duration: 0.45)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.15),
                            value: animating
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(ClawTheme.serverBubble)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            Spacer(minLength: 60)
        }
        .onAppear {
            animating = true
        }
    }
}

#Preview {
    ZStack {
        ClawTheme.background.ignoresSafeArea()
        LoadingBubbleView()
            .padding()
    }
}
