import SwiftUI

struct SplashScreenView: View {
    @State private var opacity = 0.0
    @State private var shimmerOffset: CGFloat = -1.0
    
    var body: some View {
        ZStack {
            Color(hex: "FAFAFA")
                .ignoresSafeArea()
            
            Text("CURATED")
                .font(.system(size: 30, weight: .bold, design: .serif))
                .tracking(8)
                .foregroundColor(Color(hex: "0f2c59"))
                .overlay(
                    GeometryReader { geo in
                        LinearGradient(
                            gradient: Gradient(colors: [.clear, .white.opacity(0.8), .clear]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .rotationEffect(.degrees(30))
                        .offset(x: shimmerOffset * geo.size.width * 2)
                        .mask(
                            Text("CURATED")
                                .font(.system(size: 30, weight: .bold, design: .serif))
                                .tracking(8)
                        )
                    }
                )
                .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeIn(duration: 0.8)) {
                self.opacity = 1.0
            }
            
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                self.shimmerOffset = 0.5
            }
        }
    }
}

#Preview {
    SplashScreenView()
}
