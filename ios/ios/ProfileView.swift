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
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
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