import SwiftUI
import Combine
import AuthenticationServices
import FirebaseAuth
import FirebaseCore

struct LoginView: View {
    @Binding var showLogin: Bool
    @Binding var hasCompletedOnboarding: Bool
    @EnvironmentObject var authManager: AuthManager
    @State private var isSignUpMode = true
    
    // Form States
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var agreeToTerms = false
    @State private var showTermsSheet = false
    
    @State private var isLoading = false
    
    // Alerts & Sheets
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // Colors
    private let backgroundColor = Color(hex: "FDFBF7")
    private let accentColor = Color.black
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Header Section
                    HStack(alignment: .center, spacing: 12) {
                        Button(action: {
                            if isSignUpMode {
                                withAnimation(.easeInOut) {
                                    showLogin = false
                                }
                            } else {
                                withAnimation(.spring()) {
                                    isSignUpMode = true
                                }
                            }
                        }) {
                            Image(systemName: "arrow.left")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(accentColor)
                                .padding(12)
                                .background(Color.white.opacity(0.01))
                        }
                        
                        Text(isSignUpMode ? "Create Account" : "Login")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(accentColor)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Adjusted spacer to push content slightly up (from 0.24 to 0.15)
                    Spacer(minLength: UIScreen.main.bounds.height * 0.15)
                    
                    // Form Section
                    VStack(alignment: .center, spacing: 20) {
                        if isSignUpMode {
                            ModernInputField(icon: "person.fill", placeholder: "Username", text: $username)
                        }
                        
                        ModernInputField(icon: "envelope.fill", placeholder: "Email", text: $email)
                            .keyboardType(.emailAddress)
                        
                        VStack(alignment: .trailing, spacing: 12) {
                            ModernInputField(icon: "key.fill", placeholder: "Password", text: $password, isSecure: !isPasswordVisible, accessory: AnyView(
                                Button(action: { isPasswordVisible.toggle() }) {
                                    Image(systemName: isPasswordVisible ? "eye" : "eye.slash")
                                        .foregroundColor(accentColor.opacity(0.3))
                                }
                            ))
                            
                            if !isSignUpMode {
                                Button(action: { handleResetPassword() }) {
                                    Text("Forgot Password?")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(Color(hex: "666666"))
                                }
                                .padding(.trailing, 4)
                            }
                        }
                        
                        if isSignUpMode {
                            HStack(spacing: 12) {
                                Button(action: { agreeToTerms.toggle() }) {
                                    Image(systemName: agreeToTerms ? "checkmark.square.fill" : "square")
                                        .font(.system(size: 18))
                                        .foregroundColor(agreeToTerms ? accentColor : accentColor.opacity(0.3))
                                }
                                
                                HStack(spacing: 4) {
                                    Text("I agree to the")
                                        .font(.system(size: 13))
                                        .foregroundColor(Color(hex: "666666"))
                                    
                                    Button(action: { showTermsSheet = true }) {
                                        Text("Terms & Policy")
                                            .font(.system(size: 13, weight: .bold))
                                            .foregroundColor(accentColor)
                                            .underline()
                                    }
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 4)
                            .padding(.top, 4)
                        }
                        
                        // Main Action Button
                        Button(action: { isSignUpMode ? handleSignUp() : handleLogin() }) {
                            ZStack {
                                if isLoading {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text(isSignUpMode ? "Sign Up" : "Login")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 58)
                            .background(accentColor)
                            .clipShape(Capsule())
                            .shadow(color: accentColor.opacity(0.15), radius: 10, x: 0, y: 5)
                        }
                        .disabled(isLoading || (isSignUpMode && !agreeToTerms))
                        .padding(.top, 10)
                        
                        // Separator
                        HStack(spacing: 15) {
                            Rectangle().frame(height: 1).foregroundColor(accentColor.opacity(0.08))
                            Text("OR").font(.system(size: 11, weight: .bold)).foregroundColor(accentColor.opacity(0.3))
                            Rectangle().frame(height: 1).foregroundColor(accentColor.opacity(0.08))
                        }
                        .padding(.vertical, 15)
                        
                        // Social Buttons
                        HStack(spacing: 12) {
                            socialCircleButton(brand: .apple)
                            socialCircleButton(brand: .google)
                            socialCircleButton(brand: .instagram)
                        }
                        
                        // Footer
                        HStack(spacing: 4) {
                            Text(isSignUpMode ? "Already have an account?" : "New to CURATED?")
                                .font(.system(size: 14))
                                .foregroundColor(Color(hex: "666666"))
                            
                            Button(action: {
                                withAnimation { isSignUpMode.toggle() }
                            }) {
                                Text(isSignUpMode ? "Login" : "Sign Up")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(accentColor)
                                    .underline()
                            }
                        }
                        .padding(.top, 15)
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 40)
                }
            }
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Notice"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
        .sheet(isPresented: $showTermsSheet) {
            TermsAndPolicyView()
        }
        .onAppear {
            isSignUpMode = true
        }
    }
    
    enum SocialBrand { case apple, google, instagram }
    
    private func socialCircleButton(brand: SocialBrand) -> some View {
        Button(action: { handleSocialAuth(brand: brand) }) {
            ZStack {
                Circle()
                    .stroke(accentColor.opacity(0.1), lineWidth: 1)
                    .frame(width: 54, height: 54)
                
                if brand == .instagram {
                    LinearGradient(
                        colors: [Color(hex: "833AB4"), Color(hex: "FD1D1D"), Color(hex: "F77737")],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .mask(
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.black, lineWidth: 2)
                                .frame(width: 24, height: 24)
                            Circle()
                                .stroke(Color.black, lineWidth: 2)
                                .frame(width: 11, height: 11)
                            Circle()
                                .fill(Color.black)
                                .frame(width: 3, height: 3)
                                .offset(x: 7, y: -7)
                        }
                    )
                    .frame(width: 24, height: 24)
                } else if brand == .google {
                    ZStack {
                        Text("G").font(.system(size: 22, weight: .black))
                            .foregroundStyle(LinearGradient(colors: [.blue, .red, .yellow, .green], startPoint: .topLeading, endPoint: .bottomTrailing))
                    }
                } else {
                    Image(systemName: "applelogo").font(.system(size: 22)).foregroundColor(accentColor)
                }
            }
            .frame(width: 54, height: 54)
            .background(Color.white.clipShape(Circle()))
            .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 3)
        }
    }
    
    private func handleLogin() {
        isLoading = true
        authManager.login(email: email, password: password) { result in
            isLoading = false
            DispatchQueue.main.async {
                switch result {
                case .success: withAnimation { showLogin = false }
                case .failure(let error):
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
    
    private func handleSignUp() {
        isLoading = true
        authManager.signUp(email: email, password: password, username: username) { result in
            isLoading = false
            DispatchQueue.main.async {
                switch result {
                case .success:
                    withAnimation { 
                        showLogin = false 
                    }
                case .failure(let error):
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
    
    private func handleResetPassword() {
        if email.isEmpty { alertMessage = "Enter email first."; showAlert = true; return }
        authManager.resetPassword(email: email) { _ in
            alertMessage = "Reset link sent."; showAlert = true
        }
    }
    
    private func handleSocialAuth(brand: SocialBrand) {
        // Implement
    }
}

struct ModernInputField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    var isSecure: Bool = false
    var accessory: AnyView? = nil
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(.black.opacity(0.45))
                .frame(width: 20)
            
            if isSecure {
                SecureField("", text: $text, prompt: Text(placeholder).foregroundColor(.black.opacity(0.45)))
                    .font(.system(size: 15))
            } else {
                TextField("", text: $text, prompt: Text(placeholder).foregroundColor(.black.opacity(0.45)))
                    .font(.system(size: 15))
                    .autocapitalization(.none)
            }
            
            if let accessory = accessory {
                accessory
            }
        }
        .padding(.horizontal, 16)
        .frame(height: 56)
        .background(Color.white)
        .cornerRadius(18)
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(Color.black.opacity(0.05), lineWidth: 1))
    }
}

#Preview {
    LoginView(showLogin: .constant(true), hasCompletedOnboarding: .constant(false))
        .environmentObject(AuthManager())
}
