import SwiftUI
import CoreLocation
import MapKit

struct GeofenceAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let radius: CLLocationDistance
    let identifier: String
}

struct RegionDetailView: View {
    let region: CLCircularRegion
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Region Details")) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Identifier")
                            .font(.headline)
                        Text(region.identifier)
                            .font(.subheadline)
                        
                        Text("Center")
                            .font(.headline)
                            .padding(.top, 4)
                        Text("Latitude: \(region.center.latitude)")
                            .font(.subheadline)
                        Text("Longitude: \(region.center.longitude)")
                            .font(.subheadline)
                        
                        Text("Radius")
                            .font(.headline)
                            .padding(.top, 4)
                        Text("\(Int(region.radius)) meters")
                            .font(.subheadline)
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Region Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct GeofenceView: View {
    @StateObject private var geofenceManager = GeofenceManager()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedRegion: CLCircularRegion?
    @State private var showingRegionDetail = false
    
    private var annotations: [GeofenceAnnotation] {
        geofenceManager.monitoredRegions.map { region in
            GeofenceAnnotation(
                coordinate: region.center,
                radius: region.radius,
                identifier: region.identifier
            )
        }
    }
    
    private func calculateMapRegion() -> MKCoordinateRegion {
        guard !geofenceManager.monitoredRegions.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }
        
        var minLat = Double.infinity
        var maxLat = -Double.infinity
        var minLon = Double.infinity
        var maxLon = -Double.infinity
        
        for region in geofenceManager.monitoredRegions {
            minLat = min(minLat, region.center.latitude)
            maxLat = max(maxLat, region.center.latitude)
            minLon = min(minLon, region.center.longitude)
            maxLon = max(maxLon, region.center.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.5,
            longitudeDelta: (maxLon - minLon) * 1.5
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if geofenceManager.authorizationStatus == .notDetermined {
                    Button("Request Location Permission") {
                        geofenceManager.requestLocationPermission()
                    }
                    .padding()
                } else if geofenceManager.authorizationStatus == .authorizedAlways {
                    Map(position: $cameraPosition) {
                        UserAnnotation()
                        ForEach(annotations) { annotation in
                            Annotation(annotation.identifier, coordinate: annotation.coordinate) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.2))
                                        .frame(width: CGFloat(annotation.radius * 2), height: CGFloat(annotation.radius * 2))
                                    Circle()
                                        .stroke(Color.blue, lineWidth: 2)
                                        .frame(width: CGFloat(annotation.radius * 2), height: CGFloat(annotation.radius * 2))
                                }
                                .contentShape(Circle())
                                .onTapGesture {
                                    if let region = geofenceManager.monitoredRegions.first(where: { $0.identifier == annotation.identifier }) {
                                        selectedRegion = region
                                        showingRegionDetail = true
                                    }
                                }
                            }
                        }
                    }
                    .frame(maxHeight: .infinity)
                    .ignoresSafeArea(edges: .bottom)
                    .onAppear {
                        cameraPosition = .region(calculateMapRegion())
                    }
                    .onChange(of: geofenceManager.monitoredRegions) { oldValue, newValue in
                        cameraPosition = .region(calculateMapRegion())
                    }
                } else {
                    Text("Location permission denied. Please enable it in Settings.")
                        .padding()
                }
            }
            .navigationTitle("ru-here")
            .sheet(isPresented: $showingRegionDetail) {
                if let region = selectedRegion {
                    RegionDetailView(region: region)
                }
            }
        }
    }
} 
