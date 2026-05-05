import SwiftUI
import Combine
import FirebaseAuth

struct VerificationView: View {
    @EnvironmentObject var authManager: AuthManager
    @State private var isLoading = false
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // Timer to poll verification status automatically
    let verificationTimer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    private let backgroundColor = Color(hex: "FDFBF7")
    private let accentColor = Color.black
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Top Navigation
                HStack {
                    Button(action: {
                        authManager.signOut()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(accentColor)
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Spacer(minLength: 20)
                
                // Header
                VStack(spacing: 12) {
                    Text("CURATED")
                        .font(.system(size: 24, weight: .black))
                        .foregroundColor(accentColor)
                    
                    Text("Verify Email")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(accentColor)
                    
                    Text("Please enter the code we just sent to email\n\(authManager.userSession?.email ?? "your@email.com")")
                        .font(.system(size: 14))
                        .foregroundColor(accentColor.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                }
                .padding(.horizontal, 40)
                
                // Code Boxes
                HStack(spacing: 15) {
                    ForEach(0..<4) { _ in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white)
                            .frame(width: 60, height: 60)
                            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(accentColor.opacity(0.05), lineWidth: 1)
                            )
                            .overlay(
                                Circle()
                                    .fill(accentColor.opacity(0.1))
                                    .frame(width: 8, height: 8)
                            )
                    }
                }
                .padding(.vertical, 20)
                
                VStack(spacing: 16) {
                    Text("Didn't receive OTP?")
                        .font(.system(size: 14))
                        .foregroundColor(accentColor.opacity(0.5))
                    
                    Button(action: { handleResendLink() }) {
                        Text("Resend code")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(accentColor)
                            .underline()
                    }
                }
                
                Spacer()
                
                // Main Action
                Button(action: { 
                    isLoading = true
                    authManager.reloadUser()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        isLoading = false
                        if authManager.userSession?.isEmailVerified == false {
                            alertMessage = "We haven't detected your verification yet."
                            showAlert = true
                        }
                    }
                }) {
                    ZStack {
                        if isLoading {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Verify")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(accentColor)
                    .clipShape(Capsule())
                    .shadow(color: accentColor.opacity(0.2), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Notice"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .onReceive(verificationTimer) { _ in
            authManager.reloadUser()
        }
    }
    
    private func handleResendLink() {
        isLoading = true
        authManager.resendVerificationLink { result in
            isLoading = false
            switch result {
            case .success:
                alertMessage = "A new verification link has been sent."
                showAlert = true
            case .failure(let error):
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
}

#Preview {
    VerificationView().environmentObject(AuthManager.shared)
}
