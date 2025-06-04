import SwiftUI
import CoreLocation

struct GeofenceView: View {
    @StateObject private var geofenceManager = GeofenceManager()
    @State private var latitude: String = ""
    @State private var longitude: String = ""
    @State private var radius: String = "100"
    @State private var identifier: String = ""
    
    var body: some View {
        NavigationView {
            VStack {
                if geofenceManager.authorizationStatus == .notDetermined {
                    Button("Request Location Permission") {
                        geofenceManager.requestLocationPermission()
                    }
                    .padding()
                } else if geofenceManager.authorizationStatus == .authorizedAlways {
                    Form {
                        Section(header: Text("Add New Geofence")) {
                            TextField("Latitude", text: $latitude)
                                .keyboardType(.decimalPad)
                            TextField("Longitude", text: $longitude)
                                .keyboardType(.decimalPad)
                            TextField("Radius (meters)", text: $radius)
                                .keyboardType(.decimalPad)
                            TextField("Identifier", text: $identifier)
                            
                            Button("Add Geofence") {
                                if let lat = Double(latitude),
                                   let lon = Double(longitude),
                                   let rad = Double(radius) {
                                    geofenceManager.addGeofence(
                                        latitude: lat,
                                        longitude: lon,
                                        radius: rad,
                                        identifier: identifier
                                    )
                                    // Clear fields
                                    latitude = ""
                                    longitude = ""
                                    radius = "100"
                                    identifier = ""
                                }
                            }
                            .disabled(latitude.isEmpty || longitude.isEmpty || radius.isEmpty || identifier.isEmpty)
                        }
                        
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
                                .swipeActions {
                                    Button(role: .destructive) {
                                        geofenceManager.removeGeofence(identifier: region.identifier)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
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