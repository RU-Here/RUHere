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
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("Loading group details...")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                } else if let group = groupDetails {
                    // Group details
                    VStack(spacing: 16) {
                        // Group emoji
                        Text(group.emoji)
                            .font(.system(size: 60))
                        
                        // Group name
                        Text(group.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        // Join invitation text
                        Text("You've been invited to join this group!")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                        
                        // People in group (up to 3)
                        if !group.people.isEmpty {
                            VStack(spacing: 8) {
                                Text("Members")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                let displayPeople = Array(group.people.prefix(3))
                                ForEach(displayPeople) { person in
                                    HStack {
                                        Image(systemName: "person.circle.fill")
                                            .foregroundColor(.blue)
                                        Text(person.name)
                                            .font(.body)
                                        Spacer()
                                    }
                                }
                                
                                if group.people.count > 3 {
                                    Text("and \(group.people.count - 3) more")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                } else {
                    // Error state - group not found
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 60))
                            .foregroundColor(.orange)
                        
                        Text("Group Not Found")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("This group might have been deleted or the link is invalid.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                
                Spacer()
                
                // Join Button (only show if group details loaded successfully)
                if groupDetails != nil && !isLoadingGroupDetails {
                    if hasJoined {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.green)
                            
                            Text("Successfully joined the group!")
                                .font(.headline)
                                .foregroundColor(.green)
                            
                            Button("Done") {
                                dismiss()
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        Button(action: joinGroup) {
                            HStack {
                                if isJoining {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                        .foregroundColor(.white)
                                }
                                Text(isJoining ? "Joining..." : "Join Group")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(isJoining || !authService.canProceed)
                        .padding(.horizontal, 24)
                        
                        if !authService.canProceed {
                            Text("Please sign in to join groups")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.top, 8)
                        }
                    }
                }
                
                // Cancel Button
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.secondary)
                .padding(.bottom, 32)
            }
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