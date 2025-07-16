import SwiftUI

struct ModernCardView<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.cardBackground)
                    .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
            )
    }
}

struct FloatingStatusCard: View {
    let currentGeofence: String?
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(currentGeofence != nil ? Color.accent : .gray)
                    .frame(width: 12, height: 12)
                
                if currentGeofence != nil {
                    Circle()
                        .fill(Color.accent)
                        .frame(width: 8, height: 8)
                        .scaleEffect(1.0)
                        .animation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true), value: currentGeofence != nil)
                }
            }
            
            VStack(alignment: .leading, spacing: 2) {
                if let currentGeofence = currentGeofence {
                    HStack(spacing: 4) {
                        Text("📍 You're at")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(currentGeofence)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                } else {
                    Text("Not in any tracked location")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 2)
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

#Preview("FloatingStatusCard - With Location") {
    FloatingStatusCard(currentGeofence: "CASC")
        .background(Color.gray.opacity(0.1))
}

#Preview("FloatingStatusCard - No Location") {
    FloatingStatusCard(currentGeofence: nil)
        .background(Color.gray.opacity(0.1))
}

#Preview("DetailRow") {
    VStack(spacing: 12) {
        DetailRow(title: "Latitude", value: "40.501400")
        DetailRow(title: "Longitude", value: "-74.447400")
        DetailRow(title: "Radius", value: "150 meters")
        DetailRow(title: "Status", value: "Active")
    }
    .padding()
    .background(
        RoundedRectangle(cornerRadius: 12)
            .fill(Color(.systemBackground))
            .shadow(radius: 2)
    )
    .padding()
    .background(Color.gray.opacity(0.1))
} 
