import SwiftUI

struct OnboardingView: View {
    @Binding var showLogin: Bool
    @State private var currentPage = 0
    @State private var startAnimation = false
    
    let totalPages = 3
    
    // Names of the isolated images (to be added to Assets.xcassets)
    let imageNames = [
        "isolated_balinese_dish",
        "isolated_symmetric_coffee",
        "isolated_sunset_sipping"
    ]
    
    // Updated titles to Sentence Case
    let titles = [
        "Island Flavors",
        "Coastal Coffee",
        "Sunset Sipping"
    ]
    
    let subtitles = [
        "Discover hidden gems in the heart of Bali's vibrant cafe scene.",
        "Curated spots for your perfect hand-poured morning brew.",
        "The most aesthetic retreats with views you'll never forget."
    ]
    
    var body: some View {
        ZStack {
            // 1. HomeView Background Color
            Color(hex: "FDFBF7")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 2. Top Branding
                Text("CURATED")
                    .font(.system(size: 26, weight: .black))
                    .foregroundColor(.black)
                    .padding(.top, 30)
                    .opacity(startAnimation ? 1 : 0)
                    .offset(y: startAnimation ? 0 : -20)
                
                Spacer()
                
                // 3. Floating Image (No Background)
                ZStack {
                    TabView(selection: $currentPage) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Image(imageNames[index])
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 500, height: 500)
                                .frame(maxWidth: .infinity)
                                .offset(y: index == 1 ? 0 : 25)
                                .tag(index)
                                .opacity(startAnimation ? 1 : 0)
                                .scaleEffect(startAnimation ? 1 : 0.9)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .frame(height: 520)
                }
                
                Spacer()
                
                // 4. Text Content + Page Indicator
                VStack(alignment: .center, spacing: 25) {
                    VStack(alignment: .center, spacing: 18) {
                        Text(titles[currentPage])
                            .font(.system(size: 28, weight: .black))
                            .foregroundColor(.black)
                            .id("title_\(currentPage)")
                        
                        Text(subtitles[currentPage])
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .lineSpacing(8)
                            .padding(.horizontal, 40)
                            .id("subtitle_\(currentPage)")
                    }
                    .opacity(startAnimation ? 1 : 0)
                    .offset(y: startAnimation ? 0 : 20)
                    
                    // Page Indicator
                    HStack(spacing: 12) {
                        ForEach(0..<totalPages, id: \.self) { index in
                            Capsule()
                                .fill(index == currentPage ? Color.black : Color.black.opacity(0.15))
                                .frame(width: index == currentPage ? 28 : 8, height: 8)
                        }
                    }
                    .animation(.spring(), value: currentPage)
                    .opacity(startAnimation ? 1 : 0)
                }
                .padding(.bottom, 30)
                
                // 5. Solid Black Control Shape
                VStack(spacing: 0) {
                    Button(action: {
                        if currentPage < totalPages - 1 {
                            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                currentPage += 1
                            }
                        } else {
                            withAnimation(.easeInOut(duration: 0.8)) {
                                showLogin = true
                            }
                        }
                    }) {
                        Text(currentPage == totalPages - 1 ? "Get Started" : "Next")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                    }
                }
                .background(
                    Color.black
                        .clipShape(Capsule())
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
                .opacity(startAnimation ? 1 : 0)
                .offset(y: startAnimation ? 0 : 30)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.3)) {
                startAnimation = true
            }
        }
    }
}

#Preview {
    // Correcting the preview to show OnboardingView directly
    OnboardingView(showLogin: .constant(false))
}
