import Foundation
import SwiftUI
import Combine
import AuthenticationServices
import CryptoKit
import UIKit

#if canImport(FirebaseCore) && canImport(FirebaseAuth) && canImport(FirebaseFirestore)
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
#endif

#if canImport(GoogleSignIn)
import GoogleSignIn
#endif

#if canImport(FirebaseAppleAuth)
import FirebaseAppleAuth
#endif

#if canImport(FirebaseCore) && canImport(FirebaseAuth) && canImport(FirebaseFirestore)
class AuthManager: NSObject, ObservableObject {
    static let shared = AuthManager()
    
    @Published var userSession: FirebaseAuth.User?
    @Published var currentUser: UserProfile?
    @Published var isInitialLoading = true
    
    private let db = Firestore.firestore()
    private var handler: AuthStateDidChangeListenerHandle?
    
    override init() {
        super.init()
        
        // Check Remember Me Preference
        // Default to true if not set (standard mobile behavior)
        let rememberMe = UserDefaults.standard.object(forKey: "rememberMe") as? Bool ?? true
        
        if !rememberMe {
            print("AuthManager: Remember Me is false, signing out...")
            try? Auth.auth().signOut()
        }
        
        setupAuthStateListener()
    }
    
    func setupAuthStateListener() {
        handler = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            DispatchQueue.main.async {
                self?.userSession = user
                self?.isInitialLoading = false
                
                if let user = user {
                    // Force reload to get fresh isEmailVerified status from server
                    print("DEBUG: Reloading user profile to check verification status...")
                    user.reload { error in
                        if let error = error {
                            print("DEBUG: Error reloading user: \(error.localizedDescription)")
                        } else {
                            // Update the published property with the refreshed user object
                            self?.userSession = Auth.auth().currentUser
                            print("DEBUG: User reloaded. Verified: \(Auth.auth().currentUser?.isEmailVerified ?? false)")
                        }
                    }
                    self?.fetchCurrentUser()
                }
            }
        }
    }
    
    struct UserProfile: Codable {
        let uid: String
        let username: String
        let email: String
    }
    
    // MARK: - Sign Up
    func signUp(email: String, password: String, username: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let user = result?.user else { return }
            let uid = user.uid
            
            // 1. Send Verification Link with ActionCodeSettings
            print("DEBUG: Attempting to send verification email to \(email)...")
            
            let actionCodeSettings = ActionCodeSettings()
            // IMPORTANT: This URL must be whitelisted in Firebase Console -> Authentication -> Settings -> Authorized Domains
            actionCodeSettings.url = URL(string: "https://curated-app.firebaseapp.com/?link=https://curated-app.firebaseapp.com/verify?uid=\(uid)")
            actionCodeSettings.handleCodeInApp = true
            
            // Dynamic Bundle ID to prevent configuration errors
            let bundleID = Bundle.main.bundleIdentifier ?? "com.curated.app"
            actionCodeSettings.setIOSBundleID(bundleID)
            print("DEBUG: Using Bundle ID for verification: \(bundleID)")
            
            user.sendEmailVerification(with: actionCodeSettings) { error in
                if let error = error {
                    print("DEBUG: CRITICAL ERROR - Email Verification Failed: \(error.localizedDescription)")
                } else {
                    print("DEBUG: SUCCESS - Verification Email Dispatched to \(email)")
                    print("DEBUG: Please check SPAM/INBOX for a 'Verify your email' link.")
                }
            }
            
            // 2. Save User Data to Firestore in parallel
            let data: [String: Any] = [
                "uid": uid,
                "username": username,
                "email": email,
                "createdAt": FieldValue.serverTimestamp()
            ]
            
            print("DEBUG: Saving user data to Firestore...")
            self.db.collection("users").document(uid).setData(data) { error in
                if let error = error {
                    print("DEBUG: Firestore save error (continuing anyway): \(error.localizedDescription)")
                } else {
                    print("DEBUG: Firestore data saved successfully.")
                }
                
                self.fetchCurrentUser()
                completion(.success(true))
            }
        }
    }
    
    // MARK: - Resend Verification Link
    // MARK: - Resend Verification Link
    func resendVerificationLink(completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let user = Auth.auth().currentUser else { return }
        
        // Use the same robust ActionCodeSettings as SignUp
        let actionCodeSettings = ActionCodeSettings()
        actionCodeSettings.url = URL(string: "https://curated-app.firebaseapp.com/?link=https://curated-app.firebaseapp.com/verify?uid=\(user.uid)")
        actionCodeSettings.handleCodeInApp = true
        
        let bundleID = Bundle.main.bundleIdentifier ?? "com.curated.app"
        actionCodeSettings.setIOSBundleID(bundleID)
        
        user.sendEmailVerification(with: actionCodeSettings) { error in
            if let error = error {
                print("DEBUG: Resend Verification Error: \(error.localizedDescription)")
                completion(.failure(error))
            } else {
                print("DEBUG: Verification Email Resent Successfully to \(user.email ?? "unknown")")
                completion(.success(true))
            }
        }
    }
    
    // MARK: - Login
    func login(email: String, password: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            self.userSession = result?.user
            self.fetchCurrentUser()
            completion(.success(true))
        }
    }
    
    // MARK: - Reset Password
    func resetPassword(email: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(true))
            }
        }
    }
    
    // MARK: - Sign Out
    func signOut() {
        try? Auth.auth().signOut()
        self.userSession = nil
        self.currentUser = nil
    }
    
    // MARK: - Debug/Reset for Development
    func resetAppForTesting() {
        signOut()
        UserDefaults.standard.set(false, forKey: "hasCompletedOnboarding")
    }
    
    // MARK: - Helpers
    func fetchCurrentUser() {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        
        db.collection("users").document(uid).getDocument { snapshot, error in
            if let data = snapshot?.data() {
                let uid = data["uid"] as? String ?? ""
                let username = data["username"] as? String ?? ""
                let email = data["email"] as? String ?? ""
                
                DispatchQueue.main.async {
                    self.currentUser = UserProfile(uid: uid, username: username, email: email)
                }
            }
        }
    }
    
    // MARK: - Apple Sign In
    var currentNonce: String?
    var appleSignInCompletion: ((Result<Bool, Error>) -> Void)? // Callback for UI
    
    func configureAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {
        request.requestedScopes = [.fullName, .email]
        let nonce = CryptoUtils.randomNonceString()
        currentNonce = nonce
        request.nonce = CryptoUtils.sha256(nonce)
    }
    
    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let authorization):
            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                guard let nonce = currentNonce else {
                    fatalError("Invalid state: A login callback was received, but no login request was sent.")
                }
                guard let appleIDToken = appleIDCredential.identityToken else {
                    print("Unable to fetch identity token")
                    self.appleSignInCompletion?(.failure(NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identity token"])))
                    return
                }
                guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                    print("Unable to serialize token string from data: \(appleIDToken.debugDescription)")
                    self.appleSignInCompletion?(.failure(NSError(domain: "AuthManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid token string"])))
                    return
                }
                
                var credential: AuthCredential? = nil
                
                #if canImport(FirebaseAppleAuth)
                // Standard Apple Sign In Credential Creation
                credential = AppleAuthProvider.credential(withIDToken: idTokenString,
                                                          rawNonce: nonce)
                #else
                print("ERROR: FirebaseAppleAuth module is missing. Please add it to your target dependencies.")
                self.appleSignInCompletion?(.failure(NSError(domain: "AuthManager", code: -3, userInfo: [NSLocalizedDescriptionKey: "FirebaseAppleAuth missing"])))
                #endif
                
                guard let finalCredential = credential else { return }
                
                // Sign in with Firebase
                Auth.auth().signIn(with: finalCredential) { [weak self] (authResult, error) in
                    if let error = error {
                        print("Error signing in with Apple: \(error.localizedDescription)")
                        self?.appleSignInCompletion?(.failure(error))
                        return
                    }
                    
                    guard let self = self else { return }
                    
                    // User is signed in
                    // If we have a name, we might want to update the profile
                    if let fullName = appleIDCredential.fullName {
                        let givenName = fullName.givenName ?? ""
                        let familyName = fullName.familyName ?? ""
                        let username = "\(givenName) \(familyName)".trimmingCharacters(in: .whitespaces)
                        
                        if !username.isEmpty {
                            self.updateUserProfile(username: username)
                        }
                    }
                    
                    DispatchQueue.main.async {
                        self.userSession = authResult?.user
                        self.fetchCurrentUser()
                        
                        // Force save user data to Firestore
                        if let uid = authResult?.user.uid, let email = authResult?.user.email {
                            let data: [String: Any] = [
                                "uid": uid,
                                "email": email,
                                "lastLogin": FieldValue.serverTimestamp()
                            ]
                            // Merge to avoid overwriting existing data
                            self.db.collection("users").document(uid).setData(data, merge: true) { err in
                                if let err = err {
                                    print("DEBUG: Apple Sign In Firestore Write Error: \(err)")
                                } else {
                                    print("DEBUG: Apple Sign In Firestore Write Success")
                                }
                            }
                        }
                        
                        // Notify UI of success
                        self.appleSignInCompletion?(.success(true))
                    }
                }
            }
        case .failure(let error):
            print("Apple Sign In failed: \(error.localizedDescription)")
            // If user canceled, we might want to ignore or show error
            // Error code 1001 is "The operation was canceled."
            if (error as NSError).code == 1001 {
                print("User canceled Apple Sign In.")
                appleSignInCompletion?(.failure(error)) // Optional: could silence this
            } else {
                appleSignInCompletion?(.failure(error))
            }
        }
    }
    
    private func updateUserProfile(username: String) {
        guard let changeRequest = Auth.auth().currentUser?.createProfileChangeRequest() else { return }
        changeRequest.displayName = username
        changeRequest.commitChanges { error in
            if let error = error {
                print("Error updating profile: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Google Sign In
    @MainActor
    func signInWithGoogle(completion: @escaping (Result<Bool, Error>) -> Void) {
        guard let clientID = FirebaseApp.app()?.options.clientID else {
            completion(.failure(NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Missing Client ID"])))
            return
        }
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first?.rootViewController else {
            print("Google Sign In: No root view controller found")
            completion(.failure(NSError(domain: "AuthManager", code: -2, userInfo: [NSLocalizedDescriptionKey: "Root VC not found"])))
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController) { [weak self] result, error in
            if let error = error {
                print("Google Sign In Error: \(error.localizedDescription)")
                completion(.failure(error))
                return
            }
            
            guard let user = result?.user,
                  let idToken = user.idToken?.tokenString else {
                print("Google Sign In: Unable to get ID Token")
                completion(.failure(NSError(domain: "AuthManager", code: -3, userInfo: [NSLocalizedDescriptionKey: "Missing ID Token"])))
                return
            }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: user.accessToken.tokenString)
            
            Auth.auth().signIn(with: credential) { authResult, error in
                if let error = error {
                    print("Firebase Google Sign In Error: \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                
                guard let self = self else { return }
                
                // Ensure UI updates on Main Thread
                DispatchQueue.main.async {
                    // User signed in
                    self.userSession = authResult?.user
                    self.fetchCurrentUser()
                    
                    // Save user data
                    if let uid = authResult?.user.uid, let email = authResult?.user.email {
                        let data: [String: Any] = [
                            "uid": uid,
                            "email": email,
                            "lastLogin": FieldValue.serverTimestamp()
                        ]
                        
                        // Merge to avoid overwriting existing non-auth data, but ensure email/uid is set
                        self.db.collection("users").document(uid).setData(data, merge: true) { err in
                            if let err = err {
                                print("DEBUG: Error writes to Firestore: \(err)")
                            } else {
                                print("DEBUG: Firestore Google Save Success")
                            }
                        }
                    }
                    
                    completion(.success(true))
                }
            }
        }
    }
    
    func reloadUser() {
        Auth.auth().currentUser?.reload { _ in
            self.userSession = Auth.auth().currentUser
        }
    }
}

// MARK: - Apple Sign In Delegates
extension AuthManager: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        handleAppleSignInCompletion(.success(authorization))
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        handleAppleSignInCompletion(.failure(error))
    }
    
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return ASPresentationAnchor()
        }
        return window
    }
}
#else

// Fallback stub so the app can compile without Firebase dependencies.
class AuthManager: NSObject, ObservableObject {
    static let shared = AuthManager()

    @Published var userSession: Any? = nil
    @Published var currentUser: UserProfile? = nil
    @Published var isInitialLoading = false

    struct UserProfile: Codable {
        let uid: String
        let username: String
        let email: String
    }

    override init() {
        super.init()
        print("AuthManager: Firebase modules not available. Running in stub mode.")
    }

    func signUp(email: String, password: String, username: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.failure(NSError(domain: "AuthManager", code: -100, userInfo: [NSLocalizedDescriptionKey: "Firebase not available in this build."])))
    }

    func resendVerificationLink(completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.failure(NSError(domain: "AuthManager", code: -100, userInfo: [NSLocalizedDescriptionKey: "Firebase not available in this build."])))
    }

    func login(email: String, password: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.failure(NSError(domain: "AuthManager", code: -100, userInfo: [NSLocalizedDescriptionKey: "Firebase not available in this build."])))
    }

    func resetPassword(email: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.failure(NSError(domain: "AuthManager", code: -100, userInfo: [NSLocalizedDescriptionKey: "Firebase not available in this build."])))
    }

    func signOut() {}
    func resetAppForTesting() {}
    func fetchCurrentUser() {}

    var currentNonce: String?
    var appleSignInCompletion: ((Result<Bool, Error>) -> Void)?

    func configureAppleSignInRequest(_ request: ASAuthorizationAppleIDRequest) {}

    func handleAppleSignInCompletion(_ result: Result<ASAuthorization, Error>) {
        if case .failure(let error) = result {
            self.appleSignInCompletion?(.failure(error))
        } else {
            self.appleSignInCompletion?(.failure(NSError(domain: "AuthManager", code: -100, userInfo: [NSLocalizedDescriptionKey: "Firebase not available in this build."])))
        }
    }

    @MainActor
    func signInWithGoogle(completion: @escaping (Result<Bool, Error>) -> Void) {
        completion(.failure(NSError(domain: "AuthManager", code: -100, userInfo: [NSLocalizedDescriptionKey: "Google Sign-In not available in this build."])))
    }

    func reloadUser() {}
}

extension AuthManager: ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) { }
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) { }
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor { return ASPresentationAnchor() }
}

#endif

