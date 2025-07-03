import SwiftUI
import CoreLocation
import MapKit

struct Person: Identifiable {
    let id: String
    let name: String
    let areaCode: String
}

struct Group: Identifiable {
    let id: String
    let name: String
    let people: [Person]
}

struct GeofenceAnnotation: Identifiable {
    let id = UUID()
    let coordinate: CLLocationCoordinate2D
    let radius: CLLocationDistance
    let identifier: String
}

struct PersonAnnotation: Identifiable {
    let id = UUID()
    let person: Person
    let coordinate: CLLocationCoordinate2D
    let allPeople: [Person]
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
    @State private var selectedGroup: Group?
    @State private var groups: [Group] = [
        Group(id: "1", name: "Abusement Park", people: [
            Person(id: "1", name: "Dev", areaCode: "CASC"),
            Person(id: "2", name: "Joshua", areaCode: "LSC"),
            Person(id: "3", name: "Alan", areaCode: "BSC"),
            Person(id: "4", name: "Dev", areaCode: "CASC"),
            Person(id: "5", name: "Joshua", areaCode: "LSC"),
            Person(id: "6", name: "Alan", areaCode: "BSC")
        ]),
        Group(id: "2", name: "Band", people: [
            Person(id: "4", name: "Ezra", areaCode: "CASC"),
            Person(id: "5", name: "Alicia", areaCode: "CASC"),
            Person(id: "6", name: "Hana", areaCode: "LSC")
        ]),
        Group(id: "3", name: "RuHere Dev", people: [
            Person(id: "7", name: "Jash", areaCode: "BSC"),
            Person(id: "8", name: "Matt", areaCode: "CASC"),
            Person(id: "9", name: "Adi", areaCode: "LSC")
        ])
    ]
    
    private var annotations: [GeofenceAnnotation] {
        geofenceManager.monitoredRegions.map { region in
            GeofenceAnnotation(
                coordinate: region.center,
                radius: region.radius,
                identifier: region.identifier
            )
        }
    }
    
    private var personAnnotations: [PersonAnnotation] {
        guard let selectedGroup = selectedGroup else { return [] }
        
        print("Selected group: \(selectedGroup.name)")
        print("Monitored regions: \(geofenceManager.monitoredRegions.map { $0.identifier })")
        print("Current user geofence: \(geofenceManager.currentUserGeofence ?? "none")")
        
        // Only show people in the same geofence as the current user
        guard let currentUserGeofence = geofenceManager.currentUserGeofence else {
            print("User is not currently in any geofence")
            return []
        }
        
        // Filter people to only those in the same geofence as the current user
        let peopleInCurrentGeofence = selectedGroup.people.filter { $0.areaCode == currentUserGeofence }
        
        print("People in current geofence (\(currentUserGeofence)): \(peopleInCurrentGeofence.map { $0.name })")
        
        // Group people by their area code (should all be the same now)
        let groupedPeople = Dictionary(grouping: peopleInCurrentGeofence) { $0.areaCode }
        
        // Create annotations for each group of people
        let annotations = groupedPeople.compactMap { (areaCode, people) -> PersonAnnotation? in
            print("Checking area: \(areaCode) with \(people.count) people")
            if let region = geofenceManager.monitoredRegions.first(where: { $0.identifier == areaCode }) {
                print("Found matching region for area: \(areaCode)")
                // Use the first person as the representative for the group
                return PersonAnnotation(person: people[0], coordinate: region.center, allPeople: people)
            }
            print("No matching region found for area: \(areaCode)")
            return nil
        }
        
        print("Generated \(annotations.count) person annotations")
        return annotations
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
                    // Status bar showing current user location
                    HStack {
                        Image(systemName: "location.fill")
                            .foregroundColor(.blue)
                        if let currentGeofence = geofenceManager.currentUserGeofence {
                            Text("You are in: \(currentGeofence)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        } else {
                            Text("You are not in any tracked location")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.gray.opacity(0.1))
                    
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
                        
                        // Show person annotations when a group is selected
                        ForEach(personAnnotations) { annotation in
                            Annotation(annotation.person.name, coordinate: annotation.coordinate) {
                                VStack(spacing: 4) {
                                    ZStack {
                                        Image(systemName: "person.circle.fill")
                                            .font(.title)
                                            .foregroundColor(.blue)
                                        
                                        if annotation.allPeople.count > 1 {
                                            Text("\(annotation.allPeople.count)")
                                                .font(.caption2)
                                                .foregroundColor(.white)
                                                .padding(4)
                                                .background(Circle().fill(Color.blue))
                                                .offset(x: 8, y: -8)
                                        }
                                    }
                                    
                                    VStack(spacing: 2) {
                                        ForEach(annotation.allPeople) { person in
                                            Text(person.name)
                                                .font(.caption)
                                                .padding(4)
                                                .background(Color.white.opacity(0.9))
                                                .cornerRadius(4)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll, showsTraffic: false))
                    .frame(maxHeight: .infinity)
                    .ignoresSafeArea(edges: .bottom)
                    .onAppear {
                        cameraPosition = .region(calculateMapRegion())
                    }
                    .onChange(of: geofenceManager.monitoredRegions) { oldValue, newValue in
                        cameraPosition = .region(calculateMapRegion())
                    }
                    .overlay(
                        VStack {
                            Spacer()
                            // Groups Section
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(groups) { group in
                                        Button(action: {
                                            selectedGroup = selectedGroup?.id == group.id ? nil : group
                                        }) {
                                            VStack {
                                                Text(group.name)
                                                    .font(.headline)
                                                // Show count of people in current geofence instead of total
                                                if let currentGeofence = geofenceManager.currentUserGeofence {
                                                    let peopleInCurrentGeofence = group.people.filter { $0.areaCode == currentGeofence }.count
                                                    Text("\(peopleInCurrentGeofence) here")
                                                        .font(.caption)
                                                        .foregroundColor(.gray)
                                                } else {
                                                    Text("Enter a location")
                                                        .font(.caption)
                                                        .foregroundColor(.gray)
                                                }
                                            }
                                            .padding()
                                            .background(selectedGroup?.id == group.id ? Color.blue.opacity(0.9) : Color.white.opacity(0.9))
                                            .foregroundColor(selectedGroup?.id == group.id ? .white : .primary)
                                            .cornerRadius(12)
                                            .shadow(radius: 2)
                                        }
                                    }
                                    
                                    // Add New Group Button
                                    Button(action: {
                                        // TODO: Implement add new group functionality
                                    }) {
                                        VStack {
                                            Image(systemName: "plus.circle.fill")
                                                .font(.title)
                                            Text("New Group")
                                                .font(.caption)
                                        }
                                        .padding()
                                        .background(Color.white.opacity(0.9))
                                        .cornerRadius(12)
                                        .shadow(radius: 2)
                                    }
                                }
                                .padding(.horizontal)
                            }
                            .frame(height: 100)
                            .padding(.bottom, 16)
                        }
                    )
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

