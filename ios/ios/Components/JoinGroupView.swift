import SwiftUI

extension Notification.Name {
    static let groupsUpdated = Notification.Name("groupsUpdated")
}

struct JoinGroupView: View {
    let groupId: String
    @EnvironmentObject var authService: AuthenticationService
    @EnvironmentObject var groupService: GroupService
    @Environment(\.dismiss) private var dismiss
    
    @State private var isJoining = false
    @State private var hasJoined = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var groupDetails: UserGroup?
    @State private var isLoadingGroupDetails = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()
                
                if isLoadingGroupDetails {
                    // Loading state
                    ModernCardView {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .tint(.accent)
                            Text("Loading group details...")
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                        .padding(32)
                    }
                    .padding(.horizontal, 24)
                } else if let group = groupDetails {
                    // Group details
                    ModernCardView {
                        VStack(spacing: 20) {
                            // Group emoji
                            Text(group.emoji)
                                .font(.system(size: 60))
                            
                            // Group name
                            Text(group.name)
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.primary)
                            
                            // Join invitation text
                            Text("You've been invited to join this group!")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                            
                            // People in group (up to 3)
                            if !group.people.isEmpty {
                                VStack(spacing: 12) {
                                    HStack {
                                        Image(systemName: "person.2.fill")
                                            .foregroundColor(.accent)
                                        Text("Members")
                                            .font(.headline)
                                            .fontWeight(.semibold)
                                            .foregroundColor(.primary)
                                        Spacer()
                                    }
                                    
                                    let displayPeople = Array(group.people.prefix(3))
                                    ForEach(displayPeople) { person in
                                        HStack(spacing: 12) {
                                            Image(systemName: "person.circle.fill")
                                                .foregroundColor(.accent)
                                                .font(.title3)
                                            Text(person.name)
                                                .font(.body)
                                                .fontWeight(.medium)
                                            Spacer()
                                        }
                                    }
                                    
                                    if group.people.count > 3 {
                                        Text("and \(group.people.count - 3) more")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                .padding(16)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.ultraThinMaterial)
                                )
                            }
                        }
                        .padding(24)
                    }
                    .padding(.horizontal, 24)
                } else {
                    // Error state - group not found
                    ModernCardView {
                        VStack(spacing: 20) {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            Text("Group Not Found")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            
                            Text("This group might have been deleted or the link is invalid.")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 8)
                        }
                        .padding(24)
                    }
                    .padding(.horizontal, 24)
                }
                
                Spacer()
                
                // Join Button (only show if group details loaded successfully)
                if groupDetails != nil && !isLoadingGroupDetails {
                    if hasJoined {
                        ModernCardView {
                            VStack(spacing: 16) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 50))
                                    .foregroundStyle(
                                        LinearGradient(
                                            colors: [.green, .mint],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
                                
                                Text("Successfully joined the group!")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                                    .multilineTextAlignment(.center)
                                
                                Button("Done") {
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                    impactFeedback.impactOccurred()
                                    dismiss()
                                }
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 32)
                                .padding(.vertical, 12)
                                .background(
                                    LinearGradient(
                                        colors: [Color.accent, Color.accentLight],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(25)
                                .shadow(color: Color.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .padding(24)
                        }
                        .padding(.horizontal, 24)
                    } else {
                        VStack(spacing: 12) {
                            Button(action: joinGroup) {
                                HStack(spacing: 8) {
                                    if isJoining {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .tint(.white)
                                    }
                                    Text(isJoining ? "Joining..." : "Join Group")
                                        .fontWeight(.semibold)
                                    
                                    if !isJoining {
                                        Image(systemName: "person.badge.plus")
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    LinearGradient(
                                        colors: [Color.accent, Color.accentLight],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(25)
                                .shadow(color: Color.accent.opacity(0.3), radius: 10, x: 0, y: 5)
                            }
                            .disabled(isJoining || !authService.canProceed)
                            .opacity((isJoining || !authService.canProceed) ? 0.6 : 1.0)
                            .scaleEffect((isJoining || !authService.canProceed) ? 0.98 : 1.0)
                            .animation(.easeInOut(duration: 0.2), value: isJoining)
                            .padding(.horizontal, 24)
                            
                            if !authService.canProceed {
                                Text("Please sign in to join groups")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, 24)
                            }
                        }
                    }
                }
                
                // Cancel Button
                Button("Cancel") {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                    impactFeedback.impactOccurred()
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.bottom, 32)
            }
            .background(Color.background.ignoresSafeArea())
            .navigationBarHidden(true)
            .alert("Error", isPresented: $showError) {
                Button("OK") { }
            } message: {
                Text(errorMessage)
            }
            .onAppear {
                loadGroupDetails()
            }
        }
    }
    
    private func loadGroupDetails() {
        Task {
            let group = await groupService.fetchGroupById(groupId)
            
            DispatchQueue.main.async {
                self.groupDetails = group
                self.isLoadingGroupDetails = false
                
                if group == nil {
                    // If group is nil, there was an error (handled by GroupService)
                    self.showError(message: groupService.errorMessage ?? "Failed to load group details")
                }
            }
        }
    }
    
    private func joinGroup() {
        guard authService.canProceed else { return }
        
        guard let userId = getUserId() else {
            showError(message: "Unable to get user information")
            return
        }
        
        isJoining = true
        
        Task {
            let success = await groupService.addUserToGroup(groupId: groupId, userId: userId)
            
            DispatchQueue.main.async {
                self.isJoining = false
                
                if success {
                    // Success feedback
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    self.hasJoined = true
                    
                    // Post notification that groups have been updated
                    NotificationCenter.default.post(name: .groupsUpdated, object: nil)
                } else {
                    // Show error from group service
                    self.showError(message: groupService.errorMessage ?? "Failed to join group")
                }
            }
        }
    }
    
    private func getUserId() -> String? {
        if let user = authService.user {
            return user.uid
        } else if authService.isGuestMode {
            return "guest_user"
        }
        return nil
    }
    
    private func showError(message: String) {
        self.errorMessage = message
        self.showError = true
    }
}

#Preview {
    let authService = AuthenticationService()
    return JoinGroupView(groupId: "sample-group-id")
        .environmentObject(authService)
        .environmentObject(GroupService(authService: authService))
}