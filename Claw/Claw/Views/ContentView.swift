import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            ChatView()
                .tabItem {
                    Label("Chat", systemImage: "message.fill")
                }

            StatusView()
                .tabItem {
                    Label("Status", systemImage: "antenna.radiowaves.left.and.right")
                }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(LocationManager())
        .environmentObject(ChatViewModel())
}
