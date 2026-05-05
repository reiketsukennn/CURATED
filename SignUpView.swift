import SwiftUI
import Combine
import AuthenticationServices

struct SignUpView: View {
    @Binding var isPresented: Bool
    @EnvironmentObject var authManager: AuthManager
    
    @State private var username = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isPasswordVisible = false
    @State private var isLoading = false
    
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    private let backgroundColor = Color(hex: "FDFBF7")
    private let accentColor = Color.black
    
    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    // Header Section
                    HStack(alignment: .center, spacing: 18) {
                        Button(action: {
                            withAnimation { isPresented = false }
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(accentColor)
                        }
                        
                        Text("Create Account")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(accentColor)
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    
                    // Adjusted spacer
                    Spacer(minLength: UIScreen.main.bounds.height * 0.15)
                    
                    // Form Section
                    VStack(alignment: .center, spacing: 20) {
                        ModernInputField(icon: "person.fill", placeholder: "Username", text: $username)
                        
                        ModernInputField(icon: "envelope.fill", placeholder: "Email", text: $email)
                            .keyboardType(.emailAddress)
                        
                        ModernInputField(icon: "key.fill", placeholder: "Password", text: $password, isSecure: !isPasswordVisible, accessory: AnyView(
                            Button(action: { isPasswordVisible.toggle() }) {
                                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                    .foregroundColor(accentColor.opacity(0.3))
                            }
                        ))
                        
                        // Terms removed
                        
                        // Main Action Button
                        Button(action: { handleSignUp() }) {
                            ZStack {
                                if isLoading {
                                    ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                } else {
                                    Text("Sign Up")
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
                        .disabled(isLoading)
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
                            Text("Already have an account?")
                                .font(.system(size: 14))
                                .foregroundColor(accentColor.opacity(0.5))
                            
                            Button(action: {
                                withAnimation { isPresented = false }
                            }) {
                                Text("Login")
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
    }
    
    enum SocialBrand { case apple, google, instagram }
    
    private func socialCircleButton(brand: SocialBrand) -> some View {
        Button(action: { /* implement */ }) {
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
    
    private func handleSignUp() {
        isLoading = true
        authManager.signUp(email: email, password: password, username: username) { result in
            isLoading = false
            DispatchQueue.main.async {
                switch result {
                case .success:
                    withAnimation { isPresented = false }
                case .failure(let error):
                    alertMessage = error.localizedDescription
                    showAlert = true
                }
            }
        }
    }
}

#Preview {
    SignUpView(isPresented: .constant(true)).environmentObject(AuthManager())
}
