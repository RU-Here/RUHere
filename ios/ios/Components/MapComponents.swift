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
                
                if let group = annotation.group {
                    Text(group.emoji)
                        .font(.title2)
                } else {
                    Image(systemName: "person.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                
                if annotation.allPeople.count > 1 {
                    Text("\(annotation.allPeople.count)")
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(6)
                        .background(
                            Circle()
                                .fill(.red)
                                .shadow(color: .red.opacity(0.3), radius: 4, x: 0, y: 2)
                        )
                        .offset(x: 18, y: -18)
                }
            }
            
            VStack(spacing: 4) {
                // Show group name if we have group information
                if let group = annotation.group {
                    Text(group.name)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.accent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.accent.opacity(0.1))
                        )
                }
                
                ForEach(annotation.allPeople) { person in
                    Text(person.name)
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                }
            }
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            )
        }
    }
} 