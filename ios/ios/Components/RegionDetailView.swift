import SwiftUI
import CoreLocation

struct RegionDetailView: View {
    let region: CLCircularRegion
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header with gradient
                VStack(spacing: 16) {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.accent)
                    
                    Text(region.identifier)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
                .padding(.top, 20)
                
                ModernCardView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Image(systemName: "mappin.circle.fill")
                                .foregroundColor(.accent)
                            Text("Location Details")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        
                        VStack(alignment: .leading, spacing: 12) {
                            DetailRow(title: "Latitude", value: String(format: "%.6f", region.center.latitude))
                            DetailRow(title: "Longitude", value: String(format: "%.6f", region.center.longitude))
                            DetailRow(title: "Radius", value: "\(Int(region.radius)) meters")
                        }
                    }
                    .padding(20)
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .background(Color.background.ignoresSafeArea())
            .navigationTitle("Region Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
} 