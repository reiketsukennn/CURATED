import SwiftUI

struct ContentView: View {
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if isLoading {
                LoadingView()
                    .transition(.opacity)
            } else {
                // Konten utama aplikasi
                Text("Hello, World!")
            }
        }
        .onAppear {
            // Simulasi loading saat app pertama kali dibuka
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 0.5)) {
                    isLoading = false
                }
            }
        }
    }
}

#Preview {
    ContentView()
}