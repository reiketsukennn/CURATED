import SwiftUI

struct LoadingView: View {
    @State private var opacity: Double = 0.0
    @State private var scale: CGFloat = 0.95
    
    // Font mewah seperti brand luxury (LV, hotel mewah, resort)
    // Menggunakan font serif elegan yang tersedia di iOS
    private var luxuryFont1: Font {
        // Coba font Didot dulu (mirip LV), jika tidak ada pakai Baskerville atau serif system
        return .system(size: 36, weight: .ultraLight, design: .serif)

    }
    
    private var luxuryFont2: Font {
        // Coba font Didot dulu (mirip LV), jika tidak ada pakai Baskerville atau serif system
        return .system(size: 20, weight: .ultraLight, design: .serif)
    }
    
    
    // Nama aplikasi - bisa diganti sesuai kebutuhan
    var appName: String = "CURATED"
    
    var body: some View {
        ZStack {
            // Background elegan - putih bersih
            Color.white
                .ignoresSafeArea()
            
            // Teks loading dengan font mewah
            VStack(spacing: 0) {
                Text(appName)
                    .font(luxuryFont1)
                    .foregroundColor(.blue)
                    .kerning(10) // Letter spacing untuk efek mewah (tersedia sejak iOS 14.0)
                    .opacity(opacity)
                    .scaleEffect(scale)
                
                // Garis dekoratif tipis di bawah - elegan dan minimalis
                HStack {
                    
                    Rectangle()
                        .fill(Color.blue.opacity(0.4))
                        .frame(width: 120, height: 0.5)
                        .padding(.top, 24)
                        .opacity(opacity)
                    
                    Text("BALI")
                        .font(luxuryFont2)
                        .foregroundColor(.blue)
                        .padding()
                        .offset(y: 10)
                    
                    Rectangle()
                        .fill(Color.blue.opacity(0.4))
                        .frame(width: 120, height: 0.5)
                        .padding(.top, 24)
                        .opacity(opacity)
                    
                    
                }
            }
        }
        .onAppear {
            // Animasi fade in yang halus dan elegan
            withAnimation(.easeInOut(duration: 1.2)) {
                opacity = 1.0
                scale = 1.0
            }
        }
    }
}

#Preview {
    LoadingView()
}
