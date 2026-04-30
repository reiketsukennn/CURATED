import SwiftUI
import AVKit
import Combine
import AuthenticationServices
import FirebaseAuth

struct LoginView: View {
    @Binding var showLogin: Bool
    @EnvironmentObject var authManager: AuthManager
    @State private var isSignUpMode = false
    
    // Shared Form States
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var rememberMe = true
    
    @State private var isLoading = false
    @State private var animateItems = false
    
    // Alerts
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
    
    var body: some View {
        ZStack {
            // MARK: - Shared Background
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
            
            // Navigation Layer moved to bottom to ensure z-index priority
            
            // MARK: - Auth Card Layer
            GeometryReader { geometry in
                let isShortDevice = geometry.size.height < 700
                
                VStack {
                    Spacer()
                    
                    ZStack {
                        if !isSignUpMode {
                            loginCard(isShortDevice: isShortDevice)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .leading).combined(with: .opacity),
                                    removal: .move(edge: .leading).combined(with: .opacity)
                                ))
                        } else {
                            signUpCard(isShortDevice: isShortDevice)
                                .transition(.asymmetric(
                                    insertion: .move(edge: .trailing).combined(with: .opacity),
                                    removal: .move(edge: .trailing).combined(with: .opacity)
                                ))
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
            }
            .zIndex(1)
            // MARK: - Navigation Layer (Highest)
            GeometryReader { geometry in
                VStack {
                    HStack {
                        Button(action: {
                            if isSignUpMode {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                                    isSignUpMode = false
                                }
                            } else {
                                withAnimation(.easeInOut(duration: 0.6)) {
                                    showLogin = false
                                }
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
            }
            .zIndex(999)
        }
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Notice"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
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
    
    // MARK: - Login Card View
    private func loginCard(isShortDevice: Bool) -> some View {
        VStack(spacing: isShortDevice ? 16 : 24) {
            // Header
            VStack(spacing: 6) {
                Text("Login")
                    .font(.system(size: isShortDevice ? 28 : 32, weight: .bold, design: .serif))
                    .foregroundColor(Color(hex: "FAFAFA"))
                    .multilineTextAlignment(.center)
                    .textStroke()
                
                Text("Sign in to your account and explore more of Bali's hidden gems.")
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
                InputField(icon: "envelope.fill", placeholder: "Email", text: $email)
                    .keyboardType(.emailAddress)
                
                VStack(alignment: .trailing, spacing: 8) {
                    InputField(icon: "key.fill", placeholder: "Password", text: $password, isSecure: !isPasswordVisible) {
                        Button(action: { isPasswordVisible.toggle() }) {
                            Image(systemName: isPasswordVisible ? "eye.slash.fill" : "eye.fill")
                                .foregroundColor(.white.opacity(0.6))
                        }
                    }
                    
                    HStack {
                        // Remember Me Toggle
                        Button(action: { rememberMe.toggle() }) {
                            HStack(spacing: 6) {
                                Image(systemName: rememberMe ? "checkmark.square.fill" : "square")
                                Text("Remember Me")
                            }
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            handleResetPassword()
                        }) {
                            Text("Forgot Password?")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
            }
            
            // Actions
            VStack(spacing: isShortDevice ? 16 : 20) {
                Button(action: {
                    handleLogin()
                }) {
                    HStack(spacing: 12) {
                        if isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        }
                        Text(isLoading ? "Authenticating..." : "Login")
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
                .disabled(isLoading || email.isEmpty || password.isEmpty)
                .buttonStyle(GrowingButton())
                
                // Social Login Section
                HStack {
                    VStack { Divider().background(Color.white.opacity(0.4)) }
                    Text("OR")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    VStack { Divider().background(Color.white.opacity(0.4)) }
                }
                .padding(.vertical, 8)
                
                // MARK: - Premium Branded Social Icons (Compact 32x32)
                HStack(spacing: 20) {
                    // Apple Icon
                    Button(action: {
                        isLoading = true
                        
                        // Define what happens when the Delegate calls back
                        authManager.appleSignInCompletion = { result in
                            isLoading = false
                            switch result {
                            case .success:
                                // Transition handled by ContentView
                                break
                            case .failure(let error):
                                // Ignore user cancellation error
                                if (error as NSError).code == 1001 { return }
                                alertMessage = error.localizedDescription
                                showAlert = true
                            }
                        }
                        
                        let provider = ASAuthorizationAppleIDProvider()
                        let request = provider.createRequest()
                        authManager.configureAppleSignInRequest(request)
                        
                        let controller = ASAuthorizationController(authorizationRequests: [request])
                        controller.delegate = authManager
                        controller.presentationContextProvider = authManager
                        controller.performRequests()
                    }) {
                        if isLoading {
                             ZStack {
                                 Circle()
                                     .fill(Color.black)
                                     .frame(width: 32, height: 32)
                                     .premiumShadow()
                                 
                                 ProgressView()
                                     .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                     .scaleEffect(0.6)
                             }
                        } else {
                            Image(systemName: "applelogo")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(Color.black)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                        }
                    }
                    .buttonStyle(GrowingButton())
                    .disabled(isLoading)
                    .buttonStyle(GrowingButton())
                    
                    // Google Icon (Original Design)
                    Button(action: {
                        isLoading = true
                        authManager.signInWithGoogle { result in
                            isLoading = false
                            switch result {
                            case .success:
                                // Transition handled by ContentView + AuthManager
                                break
                            case .failure(let error):
                                alertMessage = error.localizedDescription
                                showAlert = true
                            }
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.white)
                                .frame(width: 32, height: 32)
                            
                            if isLoading {
                                ProgressView()
                                    .scaleEffect(0.7)
                            } else {
                                Text("G")
                                    .font(.system(size: 14, weight: .black))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.red, .yellow, .green, .blue],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                            }
                        }
                        .shadow(color: Color.black.opacity(0.1), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(GrowingButton())
                    .disabled(isLoading)
                    
                    // Facebook Icon (Brand Blue)
                    Button(action: {
                        alertMessage = "Facebook login is currently unavailable."
                        showAlert = true
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "1877F2"))
                                .frame(width: 32, height: 32)
                            
                            Text("f")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .offset(x: 1, y: 2)
                        }
                        .shadow(color: Color.black.opacity(0.15), radius: 6, x: 0, y: 3)
                    }
                    .buttonStyle(GrowingButton())
                }
                .padding(.vertical, 8)
                .padding(.bottom, 6)
                
                // Sign Up Link
                HStack(spacing: 5) {
                    Text("New to CURATED?")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            isSignUpMode = true
                        }
                    }) {
                        Text("Sign Up")
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
    }
    
    // MARK: - Sign Up Card View
    private func signUpCard(isShortDevice: Bool) -> some View {
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
                InputField(icon: "person.fill", placeholder: "Username", text: $username)
                    .onChange(of: username) { newValue in
                        let filtered = newValue.replacingOccurrences(of: " ", with: "")
                        let limited = String(filtered.prefix(6))
                        if !limited.isEmpty {
                            username = limited.prefix(1).uppercased() + limited.dropFirst().lowercased()
                        } else {
                            username = limited
                        }
                    }
                
                InputField(icon: "envelope.fill", placeholder: "Email", text: $email)
                    .keyboardType(.emailAddress)
                
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
                    handleSignUp()
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
                .disabled(isLoading || username.count < 3 || email.isEmpty || password.isEmpty)
                .buttonStyle(GrowingButton())
                
                // Login Link
                HStack(spacing: 5) {
                    Text("Already have an account?")
                        .font(.system(size: 14))
                        .foregroundColor(.white.opacity(0.7))
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            isSignUpMode = false
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
    }
    
    // MARK: - Logic Handlers
    private func handleLogin() {
        isLoading = true
        authManager.login(email: email, password: password) { result in
            isLoading = false
                DispatchQueue.main.async {
                    switch result {
                    case .success:
                        // Save preference
                        UserDefaults.standard.set(rememberMe, forKey: "rememberMe")
                        
                        // View transition is handled by ContentView checking session.isEmailVerified
                        withAnimation {
                            showLogin = false
                        }
                    case .failure(let error):
                        // Handle "User Not Found" specifically
                        let nsError = error as NSError
                        let isUserNotFound = (nsError.code == 17011) || 
                                             (AuthErrorCode(rawValue: nsError.code) == .userNotFound)
                        
                        if isUserNotFound {
                            alertMessage = "Akun ini belum terdaftar. Mohon Sign Up dulu."
                        } else {
                            alertMessage = error.localizedDescription
                        }
                        showAlert = true
                    }
                }
        }
    }
    
    private func handleSignUp() {
        isLoading = true
        authManager.signUp(email: email, password: password, username: username) { result in
            isLoading = false
            switch result {
            case .success:
                // We do NOTHING here. AuthManager's listener will detect the new session
                // and ContentView will automatically show the VerificationView.
                break
            case .failure(let error):
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
    
    private func handleResetPassword() {
        if email.isEmpty {
            alertMessage = "Please enter your email address first."
            showAlert = true
            return
        }
        
        authManager.resetPassword(email: email) { result in
            switch result {
            case .success:
                alertMessage = "Reset link has been sent to your email."
                showAlert = true
            case .failure(let error):
                alertMessage = error.localizedDescription
                showAlert = true
            }
        }
    }
}

import FirebaseCore

#Preview {
    // Ensure Firebase is configured for Previews
    if FirebaseApp.app() == nil {
        FirebaseApp.configure()
    }
    
    return LoginView(showLogin: .constant(true))
        .environmentObject(AuthManager())
}
