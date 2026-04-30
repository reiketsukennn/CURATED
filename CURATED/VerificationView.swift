import SwiftUI
import Combine
import FirebaseAuth

struct VerificationView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // Background logic
    @State private var currentPhotoIndex = 0
    let baliPhotos = [
        "https://images.unsplash.com/photo-1537996194471-e657df975ab4?auto=format&fit=crop&w=1200&q=80",
        "https://images.unsplash.com/photo-1506477331477-33d6d8db4200?auto=format&fit=crop&w=1200&q=80",
        "https://images.unsplash.com/photo-1518548419970-58e3b4079ab2?auto=format&fit=crop&w=1200&q=80",
        "https://images.unsplash.com/photo-1552674605-db6ffd4facb5?auto=format&fit=crop&w=1200&q=80"
    ]
    
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    // Timer to poll verification status automatically
    let verificationTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Background
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
            .overlay(Color.black.opacity(0.3).ignoresSafeArea())
            
            // Back Button (Change Email)
            VStack {
                HStack {
                    Button(action: {
                        authManager.signOut()
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.left.circle.fill")
                                .font(.system(size: 20))
                            Text("Change Email")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 16)
                        .background(
                            Capsule()
                                .fill(Color(hex: "0f2c59").opacity(0.6))
                                .background(BlurView(style: .systemThinMaterialDark).clipShape(Capsule()))
                        )
                    }
                    .buttonStyle(GrowingButton())
                    .padding(.leading, 24)
                    .padding(.top, 60)
                    Spacer()
                }
                Spacer()
            }
            .zIndex(10)
            
            // Card
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: "envelope.badge.shield.half.filled")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .symbolRenderingMode(.hierarchical)
                    
                    Text("Check Your Email")
                        .font(.system(size: 32, weight: .bold, design: .serif))
                        .foregroundColor(.white)
                        .textStroke()
                    
                    if let email = authManager.userSession?.email {
                        Text(email)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(hex: "0f2c59"))
                            .padding(.vertical, 4)
                            .padding(.horizontal, 12)
                            .background(Capsule().fill(Color.white.opacity(0.8)))
                    }
                    
                    Text("We've sent a verification link to the email above. Click it to verify, and we'll automatically detect it here.")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .textStroke()
                }
                
                VStack(spacing: 20) {
                    // Main Action: Open Email (Requested earlier)
                    Button(action: {
                        openEmailApp()
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.open.fill")
                            Text("Open Email App")
                                .font(.system(size: 17, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            Capsule()
                                .fill(Color(hex: "0f2c59"))
                                .shadow(color: Color(hex: "0f2c59").opacity(0.3), radius: 15, x: 0, y: 8)
                        )
                        .foregroundColor(.white)
                    }
                    .buttonStyle(GrowingButton())
                    .disabled(isLoading)

                    // Manual Check Button (For instant feedback)
                    Button(action: {
                        isLoading = true
                        authManager.reloadUser()
                        // Add a small delay for UI feel
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            isLoading = false
                            if authManager.userSession?.isEmailVerified == false {
                                alertMessage = "We haven't received the verification yet. Please check your inbox or spam folder."
                                showAlert = true
                            }
                        }
                    }) {
                        Text("I've Verified My Email")
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                            .underline(true, color: .white.opacity(0.5))
                            .padding(8)
                    }
                }
            }
            .padding(32)
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
            .padding(24)
            .frame(maxWidth: 500)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Notice"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onReceive(timer) { _ in
            withAnimation {
                currentPhotoIndex = (currentPhotoIndex + 1) % baliPhotos.count
            }
        }
        .onReceive(verificationTimer) { _ in
            // Auto-check every 2 seconds if user is verified
            authManager.reloadUser()
        }
    }
    
    private func openEmailApp() {
        // 1. Try to open Gmail App specifically
        let gmailAppUrl = URL(string: "googlegmail://")!
        // 2. Fallback to Gmail Web in Safari
        let gmailWebUrl = URL(string: "https://mail.google.com")!
        // 3. Fallback to default iOS Mail app
        let defaultMailUrl = URL(string: "message://")!
        
        if UIApplication.shared.canOpenURL(gmailAppUrl) {
            UIApplication.shared.open(gmailAppUrl)
        } else if UIApplication.shared.canOpenURL(defaultMailUrl) {
            UIApplication.shared.open(defaultMailUrl)
        } else {
            // If no apps, open Gmail in Browser
            UIApplication.shared.open(gmailWebUrl)
        }
    }
    
    private func handleResendLink() {
        isLoading = true
        authManager.resendVerificationLink { result in
            isLoading = false
            switch result {
            case .success:
                alertMessage = "A new verification link has been sent to your email."
                showAlert = true
            case .failure(let error):
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
}

#Preview {
    VerificationView()
        .environmentObject(AuthManager())
}
