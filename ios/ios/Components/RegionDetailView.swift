import SwiftUI
import CoreLocation

struct RegionDetailView: View {
    let region: CLCircularRegion
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                // Header section
                VStack(spacing: 20) {
                    Image(systemName: "location.fill.viewfinder")
                        .font(.system(size: 70))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.accent, Color.accentLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color.accent.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Text(region.identifier)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 32)
                
                // Location details card
                ModernCardView {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack(spacing: 8) {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.accent)
                                .font(.title2)
                            Text("Location Details")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        
                        VStack(spacing: 16) {
                            DetailRow(title: "Latitude", value: String(format: "%.6f", region.center.latitude))
                            
                            Divider()
                                .background(.quaternary)
                            
                            DetailRow(title: "Longitude", value: String(format: "%.6f", region.center.longitude))
                            
                            Divider()
                                .background(.quaternary)
                            
                            DetailRow(title: "Radius", value: "\(Int(region.radius)) meters")
                        }
                    }
                    .padding(24)
                }
                .padding(.horizontal, 20)
                
                // Additional info card
                ModernCardView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.accent)
                                .font(.title2)
                            Text("About This Area")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primary)
                        }
                        
                        Text("This is a tracked location where you can see friends when they're nearby. The circle on the map shows the detection area.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .lineLimit(nil)
                    }
                    .padding(24)
                }
                .padding(.horizontal, 20)
                
                Spacer()
            }
            .background(Color.background.ignoresSafeArea())
            .navigationTitle("Area Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
} 