import Foundation
import Firebase
import FirebaseAuth
import GoogleSignIn

@MainActor
class AuthenticationService: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage = ""
    
    init() {
        user = Auth.auth().currentUser
        
        // Listen for authentication state changes
        Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            DispatchQueue.main.async {
                self?.user = user
            }
        }
    }
    
    // MARK: - Google Sign-In
    
    func signInWithGoogle() async throws {
        isLoading = true
        errorMessage = ""
        
        guard let presentingViewController = await getRootViewController() else {
            errorMessage = "Could not find presenting view controller"
            isLoading = false
            return
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController)
            
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Failed to get ID token"
                isLoading = false
                return
            }
            
            let accessToken = result.user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            let authResult = try await Auth.auth().signIn(with: credential)
            user = authResult.user
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
        
        isLoading = false
    }
    
    // MARK: - Sign Out
    
    func signOut() throws {
        try Auth.auth().signOut()
        user = nil
    }
    
    // MARK: - Private Helpers
    
    @MainActor
    private func getRootViewController() async -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        return window.rootViewController
    }
} 
