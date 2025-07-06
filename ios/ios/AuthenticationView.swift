import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject var authService: AuthenticationService
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // App Logo/Header Section
                    VStack(spacing: 16) {
                        // App Icon
                        Image(systemName: "location.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue)
                            .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                        
                        // App Name
                        Text("RUHere")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        // Subtitle
                        Text("Find your friends wherever you are")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    
                    Spacer()
                    
                    // Authentication Section
                    VStack(spacing: 24) {
                        // Welcome text
                        VStack(spacing: 8) {
                            Text("Welcome!")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                            
                            Text("Sign in to see where your friends are")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        
                        // Error Message
                        if !authService.errorMessage.isEmpty {
                            Text(authService.errorMessage)
                                .foregroundColor(.red)
                                .font(.callout)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.red.opacity(0.1))
                                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                                )
                        }
                        
                        // Google Sign In Button
                        Button(action: {
                            Task {
                                await handleGoogleSignIn()
                            }
                        }) {
                            HStack(spacing: 12) {
                                if authService.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.9)
                                } else {
                                    Image(systemName: "globe")
                                        .font(.title3)
                                }
                                
                                Text("Continue with Google")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color.blue, Color.blue.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                            .shadow(color: .blue.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .disabled(authService.isLoading)
                        .scaleEffect(authService.isLoading ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: authService.isLoading)
                        
                        // Privacy Notice
                        VStack(spacing: 4) {
                            Text("By continuing, you agree to our")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 4) {
                                Button("Terms of Service") {
                                    // TODO: Show terms
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                                
                                Text("and")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Button("Privacy Policy") {
                                    // TODO: Show privacy policy
                                }
                                .font(.caption)
                                .foregroundColor(.blue)
                            }
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
    }
    
    private func handleGoogleSignIn() async {
        do {
            try await authService.signInWithGoogle()
        } catch {
            // Error is already handled in the service
        }
    }
} 