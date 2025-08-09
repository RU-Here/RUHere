import SwiftUI

struct ModernCardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .glassCard()
    }
}

struct FloatingStatusCard: View {
    let currentGeofence: String?
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.clear)
                    .frame(width: 14, height: 14)
                    .overlay(
                        Circle().stroke(Color.accent, lineWidth: 2)
                    )
                Circle()
                    .fill(Color.accent)
                    .frame(width: 6, height: 6)
                    .opacity(currentGeofence != nil ? 1 : 0.4)
                    .scaleEffect(currentGeofence != nil ? 1.0 : 0.9)
                    .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: currentGeofence != nil)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                if let currentGeofence = currentGeofence {
                    HStack(spacing: 6) {
                        Image(systemName: "scope")
                            .foregroundColor(.accent)
                        Text("At")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(currentGeofence)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "location.slash")
                            .foregroundColor(.secondary)
                        Text("Not in any tracked location")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            LinearGradient(colors: [Color.cardBackground.opacity(0.9), Color.cardBackground.opacity(0.6)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .shadow(color: Color.accent.opacity(0.35), radius: 16, x: 0, y: 8)
        )
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

struct DetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primary)
        }
    }
} 