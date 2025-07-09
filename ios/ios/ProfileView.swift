import SwiftUI
import Firebase

struct ProfileView: View {
    @EnvironmentObject var authService: AuthenticationService
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient matching AuthenticationView
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                if authService.isGuestMode {
                    guestModeView
                } else {
                    authenticatedUserView
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private var guestModeView: some View {
        VStack(spacing: 30) {
            // Guest User Info Section
            VStack(spacing: 16) {
                // Profile Image
                Image(systemName: "person.circle")
                    .font(.system(size: 80))
                    .foregroundColor(.gray)
                    .shadow(color: .gray.opacity(0.3), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 8) {
                    Text("Guest User")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("You're browsing as a guest")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Guest Info Card
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Limited functionality in guest mode")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue.opacity(0.1))
                        .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                )
            }
            .padding(.top, 20)
            
            Spacer()
            
            // Action Buttons Section
            VStack(spacing: 16) {
                // Sign In Button
                Button(action: {
                    Task {
                        do {
                            try await authService.signInWithGoogle()
                        } catch {
                            // Error is already handled in the service
                        }
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "person.badge.plus")
                            .font(.title3)
                        Text("Sign In with Google")
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
                
                // Exit Guest Mode Button
                Button(action: {
                    showingSignOutAlert = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.backward.circle")
                            .font(.title3)
                        Text("Exit Guest Mode")
                            .font(.headline)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray, lineWidth: 1)
                            .fill(Color.clear)
                    )
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 30)
        .alert("Exit Guest Mode", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Exit", role: .destructive) {
                do {
                    try authService.signOut()
                } catch {
                    // already handled
                }
            }
        } message: {
            Text("Are you sure you want to exit guest mode? You'll need to sign in again to use the app.")
        }
    }
    
    private var authenticatedUserView: some View {
        VStack(spacing: 30) {
            // User Info Section
            VStack(spacing: 16) {
                // Profile Image
                Image(systemName: "person.circle.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                
                if let user = authService.user {
                    VStack(spacing: 8) {
                        Text(user.displayName ?? "User")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text(user.email ?? "No email")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Account Info Card
                    VStack(spacing: 12) {
                        ProfileDetailRow(title: "User ID", value: String(user.uid.prefix(8)) + "...")
                        ProfileDetailRow(title: "Email Verified", value: user.isEmailVerified ? "Yes" : "No")
                        
                        if let creationDate = user.metadata.creationDate {
                            ProfileDetailRow(
                                title: "Member Since", 
                                value: creationDate.formatted(date: .abbreviated, time: .omitted)
                            )
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                    )
                }
            }
            .padding(.top, 20)
            
            Spacer()
            
            // App Info Section
            VStack(spacing: 16) {
                // Sign Out Button
                Button(action: {
                    showingSignOutAlert = true
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "arrow.backward.circle.fill")
                            .font(.title3)
                        Text("Sign Out")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color.red, Color.red.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                    .shadow(color: .red.opacity(0.4), radius: 8, x: 0, y: 4)
                }
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
        .padding(.horizontal, 30)
        .alert("Sign Out", isPresented: $showingSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
    
    private func signOut() {
        do {
            try authService.signOut()
        } catch {
            print("Error signing out: \(error.localizedDescription)")
        }
    }
}

struct ProfileDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
    }
} 
