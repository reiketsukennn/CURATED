import SwiftUI

struct SplashScreenView: View {
    @State private var textOpacity = 0.0
    @State private var textScale: CGFloat = 0.95
    
    var body: some View {
        ZStack {
            // 1. Minimalist Black Background
            Color.black
                .ignoresSafeArea()
            
            // 2. Clean Centered Logo
            Text("CURATED")
                .font(.system(size: 24, weight: .black))
                .foregroundColor(.white)
                .shadow(color: .white.opacity(0.3), radius: 15, x: 0, y: 0) // Soft Glow/Shadow
                .opacity(textOpacity)
                .scaleEffect(textScale)
        }
        .onAppear {
            // Smooth Fade-in
            withAnimation(.easeOut(duration: 1.2)) {
                textOpacity = 1.0
                textScale = 1.0
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
