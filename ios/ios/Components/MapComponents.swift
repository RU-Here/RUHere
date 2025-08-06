import SwiftUI
import CoreLocation

struct ModernPersonAnnotation: View {
    let annotation: PersonAnnotation
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.accent, Color.accentLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(color: Color.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                
                // Display person's photo or fallback to person icon
                if !annotation.person.photoURL.isEmpty {
                    AsyncImage(url: URL(string: annotation.person.photoURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 46, height: 46)
                            .clipShape(Circle())
                    } placeholder: {
                        Image(systemName: "person.fill")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                } else {
                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
            }
            
            // Show person's name
            Text(annotation.person.name)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.primary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                )
        }
    }
} 