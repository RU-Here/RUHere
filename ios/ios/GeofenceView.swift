import SwiftUI
import CoreLocation
import MapKit

struct Person: Identifiable {
    let id: String
    let name: String
    let areaCode: String
}

struct UserGroup: Identifiable {
    let id: String
    let name: String
    let people: [Person]
    let emoji: String // use image later
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

extension Color {
    static let accent = Color(red: 1.0, green: 0.25, blue: 0.25) // #FF4040
    static let accentLight = Color(red: 1.0, green: 0.4, blue: 0.4)
    static let background = Color(red: 0.98, green: 0.98, blue: 1.0)
    static let cardBackground = Color.white
}

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

struct GeofenceView: View {
    @StateObject private var geofenceManager = GeofenceManager()
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedRegion: CLCircularRegion?
    @State private var showingRegionDetail = false
    @State private var selectedGroup: UserGroup?
    @State private var groups: [UserGroup] = [
        UserGroup(id: "1", name: "Abusement Park", people: [
            Person(id: "1", name: "Dev", areaCode: "CASC"),
            Person(id: "2", name: "Joshua", areaCode: "LSC"),
            Person(id: "3", name: "Alan", areaCode: "BSC"),
            Person(id: "4", name: "Dev", areaCode: "CASC"),
            Person(id: "5", name: "Joshua", areaCode: "LSC"),
            Person(id: "6", name: "Alan", areaCode: "BSC")
        ], emoji: "🎢"),
        UserGroup(id: "2", name: "Band", people: [
            Person(id: "4", name: "Ezra", areaCode: "CASC"),
            Person(id: "5", name: "Alicia", areaCode: "CASC"),
            Person(id: "6", name: "Hana", areaCode: "LSC")
        ], emoji: "🎵"),
        UserGroup(id: "3", name: "RuHere Dev", people: [
            Person(id: "7", name: "Jash", areaCode: "BSC"),
            Person(id: "8", name: "Matt", areaCode: "CASC"),
            Person(id: "9", name: "Adi", areaCode: "LSC")
        ], emoji: "💻")
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
            ZStack {
                Color.background.ignoresSafeArea()
                mainContentView
            }
            .navigationTitle("RuHere")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingRegionDetail) {
                if let region = selectedRegion {
                    RegionDetailView(region: region)
                }
            }
        }
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        VStack(spacing: 0) {
            switch geofenceManager.authorizationStatus {
            case .notDetermined:
                locationPermissionView
            case .authorizedAlways:
                authorizedView
            default:
                locationDeniedView
            }
        }
    }
    
    @ViewBuilder
    private var locationPermissionView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "location.circle")
                .font(.system(size: 80))
                .foregroundColor(.accent)
            
            VStack(spacing: 12) {
                Text("Location Permission")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("We need your location to show you friends nearby")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            locationPermissionButton
            
            Spacer()
        }
        .padding()
    }
    
    @ViewBuilder
    private var locationPermissionButton: some View {
        Button(action: {
            geofenceManager.requestLocationPermission()
        }) {
            HStack {
                Image(systemName: "location.fill")
                Text("Enable Location")
            }
            .font(.headline)
            .foregroundColor(.white)
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [.accent, .accentLight],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(25)
            .shadow(color: .accent.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }
    
    @ViewBuilder
    private var authorizedView: some View {
        ModernStatusBar(currentGeofence: geofenceManager.currentUserGeofence)
        
        mapView
        
        ModernGroupsSection(
            groups: groups,
            selectedGroup: $selectedGroup,
            currentGeofence: geofenceManager.currentUserGeofence
        )
    }
    
    @ViewBuilder
    private var mapView: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
            
            ForEach(annotations) { annotation in
                MapCircle(center: annotation.coordinate, radius: annotation.radius)
                    .foregroundStyle(Color.accent.opacity(0.2))
                    .stroke(Color.accent, lineWidth: 2)
                
                Annotation(annotation.identifier, coordinate: annotation.coordinate) {
                    geofenceAnnotationView(for: annotation)
                }
            }
            
            ForEach(personAnnotations) { annotation in
                Annotation(annotation.person.name, coordinate: annotation.coordinate) {
                    ModernPersonAnnotation(annotation: annotation)
                }
            }
        }
        .mapStyle(.standard(elevation: .realistic, pointsOfInterest: .excludingAll, showsTraffic: false))
        .clipShape(RoundedRectangle(cornerRadius: 0))
        .onAppear {
            cameraPosition = .region(calculateMapRegion())
        }
        .onChange(of: geofenceManager.monitoredRegions) { oldValue, newValue in
            cameraPosition = .region(calculateMapRegion())
        }
    }
    
    @ViewBuilder
    private func geofenceAnnotationView(for annotation: GeofenceAnnotation) -> some View {
        Button(action: {
            if let region = geofenceManager.monitoredRegions.first(where: { $0.identifier == annotation.identifier }) {
                selectedRegion = region
                showingRegionDetail = true
            }
        }) {
            VStack(spacing: 4) {
                Image(systemName: "location.circle.fill")
                    .font(.title2)
                    .foregroundColor(.accent)
                    .background(
                        Circle()
                            .fill(.white)
                            .frame(width: 32, height: 32)
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    )
                
                Text(annotation.identifier)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.white)
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    )
            }
        }
    }
    
    @ViewBuilder
    private var locationDeniedView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "location.slash")
                .font(.system(size: 80))
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                Text("Location Access Denied")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Please enable location access in Settings to use this app")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct ModernStatusBar: View {
    let currentGeofence: String?
    
    var body: some View {
        ModernCardView {
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .font(.title3)
                    .foregroundColor(.accent)
                    .frame(width: 24, height: 24)
                
                VStack(alignment: .leading, spacing: 2) {
                    if let currentGeofence = currentGeofence {
                        HStack {
                            Text("You're at")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(currentGeofence)
                                .font(.headline)
                                .fontWeight(.semibold)
                                .foregroundColor(.accent)
                        }
                        
                    } else {
                        Text("Not in any tracked location")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Text("Move to a public location to find friends 👯")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if currentGeofence != nil {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}

struct ModernPersonAnnotation: View {
    let annotation: PersonAnnotation
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.accent, .accentLight],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                    .shadow(color: .accent.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: "person.fill")
                    .font(.title2)
                    .foregroundColor(.white)
                
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
            
            ModernCardView {
                VStack(spacing: 4) {
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
            }
        }
    }
}

struct ModernGroupsSection: View {
    let groups: [UserGroup]
    @Binding var selectedGroup: UserGroup?
    let currentGeofence: String?
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Your Groups")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
            }
            .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(groups) { group in
                        ModernGroupCard(
                            group: group,
                            isSelected: selectedGroup?.id == group.id,
                            currentGeofence: currentGeofence
                        ) {
                            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                selectedGroup = selectedGroup?.id == group.id ? nil : group
                            }
                        }
                    }
                    
                    // Add New Group Button
                    ModernAddGroupCard()
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 20)
        .background(Color.background)
    }
}

struct ModernGroupCard: View {
    let group: UserGroup
    let isSelected: Bool
    let currentGeofence: String?
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            action()
        }) {
            ModernCardView {
                VStack(spacing: 12) {
                    Text(group.emoji)
                        .font(.system(size: 32))
                    
                    VStack(spacing: 4) {
                        Text(group.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(isSelected ? .white : .primary)
                            .multilineTextAlignment(.center)
                        
                        if let currentGeofence = currentGeofence {
                            let peopleInCurrentGeofence = group.people.filter { $0.areaCode == currentGeofence }.count
                            Text("\(peopleInCurrentGeofence) here")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(isSelected ? .white.opacity(0.8) : .accent)
                        } else {
                            Text("Enter a location")
                                .font(.caption)
                                .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .frame(width: 140, height: 120)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            isSelected 
                            ? LinearGradient(
                                colors: [.accent, .accentLight],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                            : LinearGradient(
                                colors: [.cardBackground, .cardBackground],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(
                            color: isSelected ? .accent.opacity(0.3) : .black.opacity(0.1),
                            radius: isSelected ? 12 : 8,
                            x: 0,
                            y: isSelected ? 6 : 4
                        )
                )
            }
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
    }
}

struct ModernAddGroupCard: View {
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // TODO: Implement add new group functionality
        }) {
            ModernCardView {
                VStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.accent)
                    
                    Text("New Group")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 20)
                .frame(width: 140, height: 120)
            }
        }
    }
}

