import Foundation
import Firebase
import FirebaseAuth
import GoogleSignIn

@MainActor
class AuthenticationService: ObservableObject {
    @Published var user: User?
    @Published var isLoading = false
    @Published var errorMessage = ""
    @Published var isGuestMode = false
    
    // MARK: - API Configuration
    private let baseURL = "https://ru-here.vercel.app/api/geofence"
    private let apiKey = ""
    
    init() {
        user = Auth.auth().currentUser
        
        // Listen for authentication state changes
        Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            DispatchQueue.main.async {
                self?.user = user
                // If user signs out while in guest mode, reset guest mode
                if user == nil && self?.isGuestMode == true {
                    self?.isGuestMode = false
                }
            }
        }
    }
    
    // MARK: - Guest Mode
    
    func continueAsGuest() {
        isGuestMode = true
        errorMessage = ""
    }
    
    var canProceed: Bool {
        return user != nil || isGuestMode
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
            
            // Validate email domain before proceeding
            guard let email = result.user.profile?.email else {
                errorMessage = "Could not retrieve email address"
                isLoading = false
                return
            }
            
            guard email.lowercased().hasSuffix("@scarletmail.rutgers.edu") else {
                errorMessage = "Only Rutgers University (@scarletmail.rutgers.edu) accounts are allowed"
                isLoading = false
                return
            }
            
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Failed to get ID token"
                isLoading = false
                return
            }
            
            let accessToken = result.user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: accessToken)
            
            let authResult = try await Auth.auth().signIn(with: credential)
            user = authResult.user
            // Clear guest mode when user signs in
            isGuestMode = false
            
            // Call userSignedIn API endpoint
            await callUserSignedInAPI(
                userId: authResult.user.uid,
                name: result.user.profile?.name ?? "Unknown",
                pfp: result.user.profile?.imageURL(withDimension: 120)?.absoluteString ?? ""
            )
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
        isGuestMode = false
    }
    
    // MARK: - Private Helpers
    
    private func callUserSignedInAPI(userId: String, name: String, pfp: String) async {
        guard let url = URL(string: "\(baseURL)/userSignedIn") else {
            print("❌ Invalid URL for userSignedIn endpoint")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        
        let userData = [
            "userId": userId,
            "name": name,
            "pfp": pfp
        ]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: userData)
            request.httpBody = jsonData
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 userSignedIn API Status Code: \(httpResponse.statusCode)")
                
                if httpResponse.statusCode == 200 {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("✅ userSignedIn API Response: \(responseString)")
                    }
                } else {
                    if let responseString = String(data: data, encoding: .utf8) {
                        print("❌ userSignedIn API Error: \(responseString)")
                    }
                }
            }
        } catch {
            print("🌐 Network Error calling userSignedIn API: \(error.localizedDescription)")
        }
    }
    
    @MainActor
    private func getRootViewController() async -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return nil
        }
        return window.rootViewController
    }
} 
