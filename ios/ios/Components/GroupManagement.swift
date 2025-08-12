import SwiftUI

struct ModernGroupsSection: View {
    let groups: [UserGroup]
    @Binding var selectedGroup: UserGroup?
    let currentGeofence: String?
    @Binding var showingCreateGroup: Bool
    let isLoading: Bool
    let errorMessage: String?
    
    var body: some View {
        VStack(spacing: 8) {
            
            if isLoading {
                HStack {
                    ProgressView()
                        .scaleEffect(1.0)
                    Text("Loading groups...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(height: 80)
                .padding(.horizontal, 16)
            } else if let errorMessage = errorMessage {
                VStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.headline)
                        .foregroundColor(.orange)
                    Text("Error loading groups")
                        .font(.subheadline)
                    Text(errorMessage)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(height: 80)
                .padding(.horizontal, 16)
            } else if groups.isEmpty {
                // Empty state when user has no groups
                VStack(spacing: 16) {
                    Image(systemName: "person.2.circle")
                        .font(.system(size: 40))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accent, Color.accentLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    VStack(spacing: 8) {
                        Text("No Groups Yet")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                        
                        Text("Create your first group to start connecting with friends")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 16)
                    }
                    
                    Button(action: {
                        showingCreateGroup = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "plus.circle.fill")
                            Text("Create Your First Group")
                        }
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 10)
                        .background(
                            LinearGradient(
                                colors: [Color.accent, Color.accentLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(18)
                        .shadow(color: Color.accent.opacity(0.2), radius: 6, x: 0, y: 3)
                    }
                }
                .frame(height: 140)
                .padding(.horizontal, 16)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(groups) { group in
                            ModernGroupCard(
                                group: group,
                                isSelected: selectedGroup?.id == group.id,
                                currentGeofence: currentGeofence
                            ) {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    selectedGroup = selectedGroup?.id == group.id ? nil : group
                                }
                            }
                            .padding(.vertical, 6)
                        }
                        
                        // Add New Group Button
                        ModernAddGroupCard {
                            showingCreateGroup = true
                        }
                        .padding(.vertical, 6)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                }
            }
        }
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.systemBackground).opacity(0.7))
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 28)
    }
}

struct ModernGroupCard: View {
    let group: UserGroup
    let isSelected: Bool
    let currentGeofence: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            action()
        }) {
            HStack(spacing: 8) {
                Text(group.emoji)
                    .font(.system(size: 20))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(group.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                        .fixedSize(horizontal: true, vertical: false)
                    
                    if let currentGeofence = currentGeofence {
                        let peopleInCurrentGeofence = group.people.filter { $0.areaCode == currentGeofence }.count
                        Text("\(peopleInCurrentGeofence) here")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundColor(isSelected ? .white.opacity(0.85) : .accent)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground).opacity(0.7))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: isSelected
                                    ? [Color.accent.opacity(0.85), Color.accentLight.opacity(0.7)]
                                    : [Color.clear, Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.accent : Color.clear, lineWidth: isSelected ? 1 : 0)
                    )
                    .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
        .allowsHitTesting(true)
    }
}

struct ModernAddGroupCard: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.accent)
                
                Text("New Group")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .frame(height: 56)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
            )
        }
    }
}

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var groupService: GroupService
    @EnvironmentObject var authService: AuthenticationService
    @State private var groupName = ""
    @State private var selectedEmoji = "🏠"
    @State private var isCreating = false

    
    private let availableEmojis = [
        "🏠", "🏢", "🎓", "🍕", "☕️", "🛒", "🍔", "🏛️",
        "🚗", "✈️", "🚇", "🏃‍♂️", "💼", "🎭", "🎪", "🌮"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 32) {
                    // Header
                    VStack(spacing: 24) {
                    Text("Create New Group")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accent, Color.accentLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    // Emoji Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose an Icon")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                            ForEach(availableEmojis, id: \.self) { emoji in
                                Button(action: {
                                    selectedEmoji = emoji
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                }) {
                                    let isSelected = selectedEmoji == emoji
                                    let backgroundColor = isSelected ? Color.accent.opacity(0.15) : Color.background.opacity(0.8)
                                    let borderColor = isSelected ? Color.accent : Color.clear
                                    
                                    Text(emoji)
                                        .font(.title2)
                                        .frame(width: 44, height: 44)
                                        .background(backgroundColor)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(borderColor, lineWidth: 2)
                                        )
                                        .scaleEffect(isSelected ? 1.1 : 1.0)
                                        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Form Section
                ModernCardView {
                    VStack(spacing: 24) {
                        // Group Name
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "textformat")
                                    .foregroundColor(.accent)
                                Text("Group Name")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            
                            TextField("Enter group name", text: $groupName)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                                .font(.body)
                        }
                        
                        Divider()
                            .background(.quaternary)
                        
                        // Info about adding people
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "person.badge.plus")
                                    .foregroundColor(.accent)
                                Text("Adding People")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.primary)
                            }
                            
                            Text("People can join this group using invite links after creation.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.leading)
                        }
                    }
                    .padding(24)
                }
                .padding(.horizontal, 20)
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: createGroup) {
                        let isDisabled = groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating
                        let buttonOpacity = isDisabled ? 0.6 : 1.0
                        
                        HStack {
                            if isCreating {
                                ProgressView()
                                    .scaleEffect(0.8)
                                    .foregroundColor(.white)
                                Text("Creating...")
                                    .fontWeight(.semibold)
                            } else {
                                Text("Create Group")
                                    .fontWeight(.semibold)
                                
                                Image(systemName: "arrow.right")
                            }
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                colors: [Color.accent, Color.accentLight],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(25)
                        .shadow(color: Color.accent.opacity(0.3), radius: 10, x: 0, y: 5)
                        .opacity(buttonOpacity)
                        .scaleEffect(isDisabled ? 0.98 : 1.0)
                        .animation(.easeInOut(duration: 0.2), value: isDisabled)
                    }
                    .disabled(groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isCreating)
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
                }
                .padding(.top, 20)
            }
            .background(Color.background.ignoresSafeArea())
        }
    }
    
    private func createGroup() {
        let trimmedName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !isCreating else { return }
        
        guard let userId = getUserId() else {
            print("No user ID available")
            return
        }
        
        isCreating = true
        
        Task {
            let success = await groupService.createGroup(
                name: trimmedName,
                emoji: selectedEmoji,
                adminUserId: userId
            )
            
            DispatchQueue.main.async {
                self.isCreating = false
                
                if success {
                    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                    impactFeedback.impactOccurred()
                    self.dismiss()
                }
                // Error handling is done in the GroupService
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
} 

// MARK: - Manage Group (Admin Only)
struct ManageGroupView: View {
    let group: UserGroup
    @EnvironmentObject var groupService: GroupService
    @EnvironmentObject var authService: AuthenticationService
    @Environment(\.dismiss) private var dismiss

    @State private var newGroupName: String
    @State private var newEmoji: String
    // Auto-save instead of explicit save button
    @State private var isRemoving = false
    @State private var errorMessage: String?
    @State private var members: [Person]
    @State private var removingIds: Set<String> = []
    @State private var showRemovedBanner = false
    @State private var lastRemovedName: String = ""
    @State private var updateInfoTask: Task<Void, Never>? = nil
    @State private var pollingTask: Task<Void, Never>? = nil

    init(group: UserGroup) {
        self.group = group
        _newGroupName = State(initialValue: group.name)
        _newEmoji = State(initialValue: group.emoji)
        _members = State(initialValue: group.people)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    groupInfoSection
                    membersSection
                    errorSection
                    actionsSection
                }
                .padding(.top, 20)
            }
            .background(Color.background.ignoresSafeArea())
            .navigationTitle("Manage Group")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .top) { removedBannerOverlay }
            // Keep UI in sync with backend changes
            .onReceive(groupService.$groups) { groups in
                guard let latest = groups.first(where: { $0.id == group.id }) else { return }
                if latest.name != newGroupName { newGroupName = latest.name }
                if latest.emoji != newEmoji { newEmoji = latest.emoji }
                if latest.people.map({ $0.id }) != members.map({ $0.id }) {
                    withAnimation { members = latest.people }
                }
            }
            .task {
                // Poll for updates while this view is presented
                guard let uid = requesterId() else { return }
                pollingTask?.cancel()
                pollingTask = Task {
                    while !Task.isCancelled {
                        await groupService.fetchGroups(for: uid)
                        try? await Task.sleep(nanoseconds: 3_000_000_000) // 3s
                    }
                }
            }
            .onDisappear {
                pollingTask?.cancel()
                pollingTask = nil
                updateInfoTask?.cancel()
                updateInfoTask = nil
            }
        }
    }

    private func requesterId() -> String? {
        if let user = authService.user { return user.uid }
        if authService.isGuestMode { return "guest_user" }
        return nil
    }

    private func scheduleGroupInfoUpdate() {
        guard let requesterId = requesterId() else { return }
        let nameValue = newGroupName.trimmingCharacters(in: .whitespacesAndNewlines)
        let emojiValue = newEmoji.trimmingCharacters(in: .whitespacesAndNewlines)
        updateInfoTask?.cancel()
        updateInfoTask = Task { [nameValue, emojiValue] in
            try? await Task.sleep(nanoseconds: 600_000_000) // 0.6s debounce
            _ = await groupService.updateGroupInfo(groupId: group.id, name: nameValue, emoji: emojiValue, requesterId: requesterId)
        }
    }

    private func remove(person: Person) async {
        guard let requesterId = requesterId() else { return }
        await MainActor.run { removingIds.insert(person.id) }
        let success = await groupService.removeUserFromGroup(groupId: group.id, userId: person.id, requesterId: requesterId)
        await MainActor.run {
            removingIds.remove(person.id)
            if success {
                let impact = UINotificationFeedbackGenerator()
                impact.notificationOccurred(.success)
                withAnimation {
                    members.removeAll { $0.id == person.id }
                }
                lastRemovedName = person.name
                withAnimation { showRemovedBanner = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                    withAnimation { showRemovedBanner = false }
                }
            } else {
                let impact = UINotificationFeedbackGenerator()
                impact.notificationOccurred(.error)
                errorMessage = groupService.errorMessage
            }
        }
    }
}

// MARK: - Small subviews to simplify type-checking
private extension ManageGroupView {
    @ViewBuilder var groupInfoSection: some View {
        ModernCardView {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 8) {
                    Image(systemName: "pencil.circle.fill").foregroundColor(.accent)
                    Text("Group Info").font(.headline).fontWeight(.semibold)
                }

                TextField("Group name", text: $newGroupName)
                    .onChange(of: newGroupName) { _, _ in
                        scheduleGroupInfoUpdate()
                    }
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                HStack {
                    Text("Emoji").foregroundColor(.secondary)
                    Spacer()
                    TextField("Emoji", text: $newEmoji)
                        .onChange(of: newEmoji) { _, _ in
                            scheduleGroupInfoUpdate()
                        }
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }
            .padding(16)
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder var membersSection: some View {
        ModernCardView {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "person.2.fill").foregroundColor(.accent)
                    Text("Members (\(members.count))").font(.headline).fontWeight(.semibold)
                }

                ForEach(members, id: \.id) { person in
                    VStack {
                        MemberRowView(
                            person: person,
                            isAdmin: person.id == group.admin,
                            isRemoving: removingIds.contains(person.id),
                            onRemove: {
                                Task { await remove(person: person) }
                            }
                        )
                        Divider().background(.quaternary)
                    }
                    .transition(.opacity.combined(with: .move(edge: .trailing)))
                }
            }
            .padding(16)
        }
        .padding(.horizontal, 20)
    }

    @ViewBuilder var errorSection: some View {
        if let errorMessage = errorMessage {
            Text(errorMessage)
                .font(.callout)
                .foregroundColor(.red)
                .padding(.horizontal, 24)
        }
    }

    @ViewBuilder var actionsSection: some View {
        VStack(spacing: 12) {
            Button("Done") { dismiss() }
                .font(.headline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, minHeight: 50)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 24)
    }

    @ViewBuilder var removedBannerOverlay: some View {
        if showRemovedBanner {
            RemovedBanner(name: lastRemovedName)
                .padding(.top, 12)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
}

// MARK: - Small subviews to simplify type-checking
private struct MemberRowView: View {
    let person: Person
    let isAdmin: Bool
    let isRemoving: Bool
    let onRemove: () -> Void

    var body: some View {
        HStack {
            Text(person.name)
                .fontWeight(.medium)
            Spacer()
            if !isAdmin {
                if isRemoving {
                    ProgressView().scaleEffect(0.9)
                } else {
                    Button(action: onRemove) {
                        Image(systemName: "minus.circle.fill").foregroundColor(.red)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

private struct RemovedBanner: View {
    let name: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
            Text("Removed \(name)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
        )
    }
}