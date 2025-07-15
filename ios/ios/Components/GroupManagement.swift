import SwiftUI

struct ModernGroupsSection: View {
    let groups: [UserGroup]
    @Binding var selectedGroup: UserGroup?
    let currentGeofence: String?
    @Binding var showingCreateGroup: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Groups")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
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
                        .padding(.vertical, 10) // Extra space for scaling and shadow
                    }
                    
                    // Add New Group Button
                    ModernAddGroupCard {
                        showingCreateGroup = true
                    }
                    .padding(.vertical, 10) // Consistent spacing
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 5) // Additional space for shadows
            }
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 34) // Safe area bottom padding
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
            VStack(spacing: 12) {
                Text(group.emoji)
                    .font(.system(size: 32))
                
                VStack(spacing: 4) {
                    Text(group.name)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(isSelected ? .white : .primary)
                        .multilineTextAlignment(.center)
                    
                    if let currentGeofence = currentGeofence {
                        let peopleInCurrentGeofence = group.people.filter { $0.areaCode == currentGeofence }.count
                        Text("\(peopleInCurrentGeofence) here")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(isSelected ? .white.opacity(0.8) : .accent)
                    } else {
                        Text("Enter a location")
                            .font(.caption)
                            .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .frame(width: 140, height: 120)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(isSelected ? .thinMaterial : .ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: isSelected 
                                    ? [Color.accent.opacity(0.8), Color.accentLight.opacity(0.6)]
                                    : [Color.clear, Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? Color.accent : Color.clear, lineWidth: isSelected ? 2 : 0)
                    )
                    .shadow(color: isSelected ? Color.accent.opacity(0.4) : .black.opacity(0.08), radius: isSelected ? 15 : 8, x: 0, y: isSelected ? 8 : 4)
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
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
            VStack(spacing: 12) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.accent)
                
                Text("New Group")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .frame(width: 140, height: 120)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            )
        }
    }
}

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var groupName = ""
    @State private var selectedEmoji = "🏠"

    
    private let availableEmojis = [
        "🏠", "🏢", "🎓", "🍕", "☕️", "🛒", "🍔", "🏛️",
        "🚗", "✈️", "🚇", "🏃‍♂️", "💼", "🎭", "🎪", "🌮"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 24) {
                    Text("Create New Group")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
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
                                    let backgroundColor = isSelected ? Color.blue.opacity(0.2) : Color.background.opacity(0.8)
                                    let borderColor = isSelected ? Color.blue : Color.clear
                                    
                                    Text(emoji)
                                        .font(.title2)
                                        .frame(width: 44, height: 44)
                                        .background(backgroundColor)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(borderColor, lineWidth: 2)
                                        )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Form Section
                VStack(spacing: 20) {
                    // Group Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Group Name")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter group name", text: $groupName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.body)
                    }
                    
                    // Info about adding people
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Adding People")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("People can join this group using invite links after creation.")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: createGroup) {
                        let isDisabled = groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        let buttonOpacity = isDisabled ? 0.6 : 1.0
                        
                        HStack {
                            Text("Create Group")
                                .fontWeight(.semibold)
                            
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .opacity(buttonOpacity)
                    }
                    .disabled(groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(Color.background)
        }
    }
    
    private func createGroup() {
        let trimmedName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            // TODO: Save the group (name: trimmedName, emoji: selectedEmoji, people: [])
            print("Creating group: \(trimmedName) \(selectedEmoji)")
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            dismiss()
        }
    }
} 