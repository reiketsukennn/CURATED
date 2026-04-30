import SwiftUI

struct OnboardingView: View {
    @Binding var showLogin: Bool
    @State private var currentPage = 0
    @State private var isAnimating = false
    
    let totalPages = 3
    
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
        GeometryReader { geometry in
            ZStack {
                // Background Images
                TabView(selection: $currentPage) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Image("\(index + 1)")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height, alignment: .center)
                            .clipped()
                            .tag(index)
                            .ignoresSafeArea()
                            .scaleEffect(currentPage == index ? 1.05 : 1.2) // Subtle zoom effect
                            .animation(.easeOut(duration: 2.5), value: currentPage)
                    }
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                .ignoresSafeArea()
                
                VStack {
                    Spacer()
                    
                    // Bottom Control Shape
                    VStack(alignment: .leading, spacing: 24) {
                        // Text Content
                        VStack(alignment: .leading, spacing: 12) {
                            Text(titles[currentPage])
                                .font(.system(size: geometry.size.width > 500 ? 44 : 34, weight: .bold, design: .serif))
                                .foregroundColor(.white)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .bottom)).combined(with: .scale(scale: 0.9)),
                                    removal: .opacity.combined(with: .scale(scale: 1.1))
                                ))
                                .id("title_\(currentPage)")
                                .textStroke()
                            
                            Text(subtitles[currentPage])
                                .font(.system(size: geometry.size.width > 500 ? 20 : 17))
                                .foregroundColor(.white.opacity(0.85))
                                .lineLimit(2)
                                .fixedSize(horizontal: false, vertical: true)
                                .transition(.asymmetric(
                                    insertion: .opacity.combined(with: .move(edge: .bottom)).combined(with: .offset(y: 10)),
                                    removal: .opacity
                                ))
                                .id("subtitle_\(currentPage)")
                                .textStroke()
                        }
                        .padding(.horizontal, 4)
                        
                        HStack {
                            // Advanced Page Indicator
                            HStack(spacing: 10) {
                                ForEach(0..<totalPages, id: \.self) { index in
                                    Capsule()
                                        .fill(index == currentPage ? Color.white : Color.white.opacity(0.3))
                                        .frame(width: index == currentPage ? 28 : 8, height: 8)
                                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                }
                            }
                            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: currentPage)
                            
                            Spacer()
                            
                            // Next Button
                            Button(action: {
                                if currentPage < totalPages - 1 {
                                    withAnimation(.interpolatingSpring(stiffness: 120, damping: 15)) {
                                        currentPage += 1
                                    }
                                } else {
                                    withAnimation(.easeInOut(duration: 0.6)) {
                                        showLogin = true
                                    }
                                }
                            }) {
                                HStack(spacing: 10) {
                                    Text(currentPage == totalPages - 1 ? "Discover More" : "Next")
                                        .font(.system(size: 16, weight: .bold))
                                    
                                    if currentPage != totalPages - 1 {
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .bold))
                                    }
                                }
                                .padding(.horizontal, 28)
                                .padding(.vertical, 16)
                                .background(
                                    Capsule()
                                        .fill(Color(hex: "0f2c59"))
                                        .shadow(color: Color(hex: "0f2c59").opacity(0.3), radius: 15, x: 0, y: 8)
                                )
                                .foregroundColor(.white)
                            }
                            .buttonStyle(GrowingButton())
                        }
                    }
                    .padding(geometry.size.width > 500 ? 45 : 32)
                    .frame(maxWidth: 600)
                    .background(
                        RoundedRectangle(cornerRadius: 35, style: .continuous)
                            .fill(Color(hex: "b5becc").opacity(0.3))
                            .background(
                                BlurView(style: .systemThinMaterialDark)
                                    .clipShape(RoundedRectangle(cornerRadius: 35, style: .continuous))
                            )
                            .premiumShadow()
                            .overlay(
                                RoundedRectangle(cornerRadius: 35, style: .continuous)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                            )
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? geometry.safeAreaInsets.bottom : 20)
                }
                
                // Refined Header (Logo + Skip)
                VStack {
                    HStack {
                        Spacer()
                        
                        // Branding Logo (Center)
                        Text("CURATED")
                            .font(.system(size: 22, weight: .bold, design: .serif))
                            .tracking(6)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                        
                        Spacer()
                    }
                    .padding(.top, 45) // Moved up
                    Spacer()
                }
            }
        }
    }
}

#Preview {
    OnboardingView(showLogin: .constant(false))
}
