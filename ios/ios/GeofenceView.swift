import SwiftUI
import CoreLocation

struct GeofenceView: View {
    @StateObject private var geofenceManager = GeofenceManager()
    
    var body: some View {
        NavigationView {
            VStack {
                if geofenceManager.authorizationStatus == .notDetermined {
                    Button("Request Location Permission") {
                        geofenceManager.requestLocationPermission()
                    }
                    .padding()
                } else if geofenceManager.authorizationStatus == .authorizedAlways {
                    List {
                        Section(header: Text("Monitored Regions")) {
                            ForEach(geofenceManager.monitoredRegions, id: \.identifier) { region in
                                VStack(alignment: .leading) {
                                    Text(region.identifier)
                                        .font(.headline)
                                    Text("Center: \(region.center.latitude), \(region.center.longitude)")
                                        .font(.subheadline)
                                    Text("Radius: \(Int(region.radius))m")
                                        .font(.subheadline)
                                }
                            }
                        }
                    }
                } else {
                    Text("Location permission denied. Please enable it in Settings.")
                        .padding()
                }
            }
            .navigationTitle("Geofences")
        }
    }
} 