import SwiftUI
import FirebaseCore
import FirebaseAuth
import GoogleSignIn

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

// ... (Existing code)
@main
struct CuratedApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var languageManager = LanguageManager.shared // 1. Init Manager
    @State private var showSplash = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showSplash {
                    SplashScreenView()
                        .transition(.opacity)
                        .zIndex(2)
                }
                
                if !showSplash {
                    ContentView()
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .environmentObject(authManager)
            .environmentObject(languageManager) // 2. Inject Manager
            .environment(\.locale, languageManager.locale) // 3. Force Locale change
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        showSplash = false
                    }
                }
            }
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}
// ... (LoadingView)

// Simple Loading View for the 'System'
struct LoadingView: View {
    var body: some View {
        ZStack {
            Color(hex: "FAFAFA").ignoresSafeArea()
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: Color(hex: "0f2c59")))
                .scaleEffect(1.5)
        }
    }
}