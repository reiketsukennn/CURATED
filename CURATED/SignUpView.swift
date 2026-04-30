import SwiftUI
import Combine

struct SignUpView: View {
    @Binding var isPresented: Bool
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var isLoading = false
    @State private var animateItems = false
    
    // Using the same Bali photos for consistency
    @State private var currentPhotoIndex = 0
    let baliPhotos = [
        "https://images.unsplash.com/photo-1537996194471-e657df975ab4?auto=format&fit=crop&w=1200&q=80",
        "https://images.unsplash.com/photo-1506477331477-33d6d8db4200?auto=format&fit=crop&w=1200&q=80",
        "https://images.unsplash.com/photo-1518548419970-58e3b4079ab2?auto=format&fit=crop&w=1200&q=80",
        "https://images.unsplash.com/photo-1552674605-db6ffd4facb5?auto=format&fit=crop&w=1200&q=80"
    ]
    
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // MARK: - Background Slideshow (Truly Full Screen)
            ZStack {
                ForEach(0..<baliPhotos.count, id: \.self) { index in
                    AsyncImage(url: URL(string: baliPhotos[index])) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                            .scaleEffect(currentPhotoIndex == index ? 1.05 : 1.1)
                    } placeholder: {
                        Color(hex: "0f2c59")
                    }
                    .opacity(currentPhotoIndex == index ? 1 : 0)
                    .animation(.easeInOut(duration: 1.5), value: currentPhotoIndex)
                }
            }
            .ignoresSafeArea()
            .overlay(Color.black.opacity(0.25).ignoresSafeArea())
            
            // MARK: - Interactive Content
            GeometryReader { geometry in
                let isShortDevice = geometry.size.height < 700
                
                ZStack {
                    // Navigation Back Button
                    VStack {
                        HStack {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.8)) {
                                    isPresented = false
                                }
                            }) {
                                Image(systemName: "chevron.left")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(
                                        Circle()
                                            .fill(Color(hex: "0f2c59").opacity(0.4))
                                            .background(BlurView(style: .systemThinMaterialDark).clipShape(Circle()))
                                            .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
                                    )
                            }
                            .buttonStyle(GrowingButton())
                            .padding(.leading, 24)
                            .padding(.top, geometry.safeAreaInsets.top > 0 ? 10 : 40)
                            Spacer()
                        }
                        Spacer()
                    }
                    .zIndex(10)
                    
                    // Centered Fixed Sign Up Card
                    VStack {
                        Spacer()
                        
                        VStack(spacing: isShortDevice ? 16 : 24) {
                            // Header
                            VStack(spacing: 6) {
                                Text("Create Account")
                                    .font(.system(size: isShortDevice ? 28 : 32, weight: .bold, design: .serif))
                                    .foregroundColor(Color(hex: "FAFAFA"))
                                    .multilineTextAlignment(.center)
                                    .textStroke()
                                
                                Text("Join CURATED and start your journey through Bali's best spots.")
                                    .font(.system(size: isShortDevice ? 13 : 15))
                                    .foregroundColor(.white.opacity(0.85))
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .textStroke()
                            }
                            .frame(maxWidth: .infinity)
                            
                            // Input Fields
                            VStack(spacing: isShortDevice ? 12 : 16) {
                                InputField(icon: "person.fill", placeholder: "Username", text: $name)
                                    .onChange(of: name) { newValue in
                                        // 1. Remove spaces (ensure single word)
                                        let filtered = newValue.replacingOccurrences(of: " ", with: "")
                                        
                                        // 2. Limit to 6 characters
                                        let limited = String(filtered.prefix(6))
                                        
                                        // 3. Capitalize first letter, lower the rest
                                        if !limited.isEmpty {
                                            name = limited.prefix(1).uppercased() + limited.dropFirst().lowercased()
                                        } else {
                                            name = limited
                                        }
                                    }
                                
                                InputField(icon: "envelope.fill", placeholder: "Email", text: $email)
                                
                                InputField(icon: "key.fill", placeholder: "Password", text: $password, isSecure: !isPasswordVisible) {
                                    Button(action: { isPasswordVisible.toggle() }) {
                                        Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                }
                            }
                            
                            // Actions
                            VStack(spacing: isShortDevice ? 16 : 20) {
                                Button(action: {
                                    withAnimation {
                                        isLoading = true
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            isLoading = false
                                        }
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        if isLoading {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        }
                                        Text(isLoading ? "Creating Account..." : "Sign Up")
                                            .font(.system(size: 17, weight: .bold))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, isShortDevice ? 14 : 16)
                                    .background(
                                        Capsule()
                                            .fill(Color(hex: "0f2c59"))
                                            .shadow(color: Color(hex: "0f2c59").opacity(0.3), radius: 15, x: 0, y: 8)
                                    )
                                    .foregroundColor(.white)
                                }
                                .disabled(isLoading)
                                .buttonStyle(GrowingButton())
                                
                                // Login Link
                                HStack(spacing: 5) {
                                    Text("Already have an account?")
                                        .font(.system(size: 14))
                                        .foregroundColor(.white.opacity(0.7))
                                    
                                    Button(action: {
                                        withAnimation {
                                            isPresented = false
                                        }
                                    }) {
                                        Text("Login")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(Color(hex: "0f2c59"))
                                    }
                                }
                            }
                        }
                        .padding(isShortDevice ? 22 : 28)
                        .background(
                            RoundedRectangle(cornerRadius: 30, style: .continuous)
                                .fill(Color(hex: "b5becc").opacity(0.35))
                                .background(
                                    BlurView(style: .systemThinMaterialDark)
                                        .clipShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
                                )
                                .premiumShadow()
                                .overlay(
                                    RoundedRectangle(cornerRadius: 30, style: .continuous)
                                        .stroke(Color.white.opacity(0.15), lineWidth: 1.5)
                                )
                        )
                        .frame(maxWidth: 500)
                        .padding(.horizontal, 24)
                        .offset(y: animateItems ? 0 : 20)
                        .opacity(animateItems ? 1 : 0)
                        
                        Spacer()
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                animateItems = true
            }
        }
        .onReceive(timer) { _ in
            withAnimation {
                currentPhotoIndex = (currentPhotoIndex + 1) % baliPhotos.count
            }
        }
    }
}

#Preview {
    SignUpView(isPresented: .constant(true))
}
