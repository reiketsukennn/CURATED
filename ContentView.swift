import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authManager: AuthManager
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    
    @State private var showLogin = false
    
    var body: some View {
        ZStack {
            // Global background to prevent flashes during transitions
            Color(hex: "FDFBF7").ignoresSafeArea()
            
            if authManager.userSession != nil {
                HomeView()
                    .transition(.opacity)
            } else {
                if showLogin {
                    LoginView(showLogin: $showLogin, hasCompletedOnboarding: $hasCompletedOnboarding)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .id("login_flow")
                        .zIndex(2)
                } else if !hasCompletedOnboarding {
                    OnboardingView(showLogin: $showLogin)
                        .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                        .id("onboarding")
                        .zIndex(1)
                } else {
                    LoginView(showLogin: $showLogin, hasCompletedOnboarding: $hasCompletedOnboarding)
                        .transition(.opacity)
                        .id("login_root")
                        .zIndex(1)
                }
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: showLogin)
        .animation(.easeInOut, value: hasCompletedOnboarding)
        .animation(.easeInOut, value: authManager.userSession != nil)
    }
}

#Preview {
    // For Preview, we want to see the whole sequence every time
    ContentView()
        .environmentObject(AuthManager.shared)
        .onAppear {
            UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
        }
}