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
    let group: UserGroup? // Added to track which group these people belong to
}

extension Color {
    static let accent = Color(red: 1.0, green: 0.25, blue: 0.25) // #FF4040
    static let accentLight = Color(red: 1.0, green: 0.4, blue: 0.4)
    static let background = Color(red: 0.98, green: 0.98, blue: 1.0)
    static let cardBackground = Color.white
    
    // Highlighted geofence colors
    static let highlightedGeofence = Color(red: 0.0, green: 0.8, blue: 1.0) // Bright cyan
    static let highlightedGeofenceLight = Color(red: 0.3, green: 0.9, blue: 1.0)
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
    @State private var showingCreateGroup = false
    @State private var showingProfile = false
    @State private var hasPerformedInitialZoom = false
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
        guard let currentUserGeofence = geofenceManager.currentUserGeofence else {
            print("User is not currently in any geofence")
            return []
        }
        
        print("Monitored regions: \(geofenceManager.monitoredRegions.map { $0.identifier })")
        print("Current user geofence: \(currentUserGeofence)")
        
        if let selectedGroup = selectedGroup {
            // If a group is selected, only show people from that group
            print("Selected group: \(selectedGroup.name)")
            
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
                    return PersonAnnotation(person: people[0], coordinate: region.center, allPeople: people, group: selectedGroup)
                }
                print("No matching region found for area: \(areaCode)")
                return nil
            }
            
            print("Generated \(annotations.count) person annotations")
            return annotations
        } else {
            // If no group is selected, show all people from all groups in the current geofence
            print("No group selected, showing all people in current geofence")
            
            // Collect all people from all groups who are in the current geofence
            var allPeopleInGeofence: [(Person, UserGroup)] = []
            for group in groups {
                let peopleInGeofence = group.people.filter { $0.areaCode == currentUserGeofence }
                for person in peopleInGeofence {
                    allPeopleInGeofence.append((person, group))
                }
            }
            
            print("All people in current geofence: \(allPeopleInGeofence.map { "\($0.0.name) (\($0.1.name))" })")
            
            // Group people by their group
            let peopleByGroup = Dictionary(grouping: allPeopleInGeofence) { $0.1.id }
            
            // Create annotations for each group that has people in the current geofence
            let sortedGroupIds = Array(peopleByGroup.keys).sorted() // Ensure consistent ordering
            let annotations = sortedGroupIds.enumerated().compactMap { (index, groupId) -> PersonAnnotation? in
                guard let peopleWithGroups = peopleByGroup[groupId] else { return nil }
                
                let people = peopleWithGroups.map { $0.0 }
                let group = peopleWithGroups.first?.1
                
                print("Creating annotation for group: \(group?.name ?? "Unknown") with \(people.count) people")
                
                if let region = geofenceManager.monitoredRegions.first(where: { $0.identifier == currentUserGeofence }) {
                    // Calculate offset position to scatter groups
                    let scatteredCoordinate = calculateScatteredPosition(
                        centerCoordinate: region.center,
                        radius: region.radius,
                        groupIndex: index,
                        totalGroups: sortedGroupIds.count
                    )
                    
                    return PersonAnnotation(person: people[0], coordinate: scatteredCoordinate, allPeople: people, group: group)
                }
                return nil
            }
            
            print("Generated \(annotations.count) group annotations")
            return annotations
        }
    }
    
    private func calculateMapRegion() -> MKCoordinateRegion {
        return calculateAllGeofencesRegion()
    }
    
    private func calculateAllGeofencesRegion() -> MKCoordinateRegion {
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
    
    private func animateToCurrentGeofenceIfNeeded() {
        guard let currentGeofence = geofenceManager.currentUserGeofence,
              let currentRegion = geofenceManager.monitoredRegions.first(where: { $0.identifier == currentGeofence }) else {
            return
        }
        
        withAnimation(.easeInOut(duration: 1.5)) {
            cameraPosition = .region(calculateRegionForGeofence(currentRegion))
        }
    }
    
    private func calculateRegionForGeofence(_ geofence: CLCircularRegion) -> MKCoordinateRegion {
        // Calculate span based on geofence radius
        // Convert radius from meters to approximate degrees
        let metersPerDegreeLatitude = 111000.0
        let metersPerDegreeLongitude = 111000.0 * cos(geofence.center.latitude * .pi / 180.0)
        
        // Use smaller multiplier to zoom in more (geofence covers more of screen)
        let latitudeDelta = (geofence.radius * 1.2) / metersPerDegreeLatitude
        let longitudeDelta = (geofence.radius * 1.2) / metersPerDegreeLongitude
        
        return MKCoordinateRegion(
            center: geofence.center,
            span: MKCoordinateSpan(
                latitudeDelta: max(latitudeDelta, 0.005), // Reduced minimum zoom for tighter zoom
                longitudeDelta: max(longitudeDelta, 0.005)
            )
        )
    }
    
    private func calculateScatteredPosition(
        centerCoordinate: CLLocationCoordinate2D,
        radius: CLLocationDistance,
        groupIndex: Int,
        totalGroups: Int
    ) -> CLLocationCoordinate2D {
        // If only one group, keep it at center
        guard totalGroups > 1 else {
            return centerCoordinate
        }
        
        // Use 40% of the radius to keep groups well within the geofence
        let offsetDistance = radius * 0.4
        
        // Calculate angle for this group (evenly distributed around circle)
        let angleStep = (2.0 * Double.pi) / Double(totalGroups)
        let angle = Double(groupIndex) * angleStep
        
        // Convert offset from meters to coordinate degrees
        let metersPerDegreeLatitude = 111000.0
        let metersPerDegreeLongitude = 111000.0 * cos(centerCoordinate.latitude * .pi / 180.0)
        
        // Calculate offset in latitude and longitude
        let latitudeOffset = (offsetDistance * cos(angle)) / metersPerDegreeLatitude
        let longitudeOffset = (offsetDistance * sin(angle)) / metersPerDegreeLongitude
        
        return CLLocationCoordinate2D(
            latitude: centerCoordinate.latitude + latitudeOffset,
            longitude: centerCoordinate.longitude + longitudeOffset
        )
    }
    
    var body: some View {
        NavigationView {
            mainContentView
            .navigationTitle("RuHere")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingProfile = true
                    }) {
                        Image(systemName: "person.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 36, height: 36)
                            )
                    }
                }
            }
            .sheet(isPresented: $showingRegionDetail) {
                if let region = selectedRegion {
                    RegionDetailView(region: region)
                }
            }
            .sheet(isPresented: $showingCreateGroup) {
                CreateGroupView()
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
        }
    }
    
    @ViewBuilder
    private var mainContentView: some View {
        ZStack {
            switch geofenceManager.authorizationStatus {
            case .notDetermined:
                locationPermissionView
            case .authorizedAlways:
                authorizedView
            default:
                locationDeniedView
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
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
        .background(Color.background.ignoresSafeArea())
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
                    colors: [Color.accent, Color.accentLight],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(25)
                                .shadow(color: Color.accent.opacity(0.3), radius: 10, x: 0, y: 5)
        }
    }
    
    @ViewBuilder
    private var authorizedView: some View {
        ZStack {
            // Map as background - fills entire screen
            mapView
                .ignoresSafeArea(.all)
            
            // Floating components overlay
            VStack(spacing: 0) {
                FloatingStatusCard(currentGeofence: geofenceManager.currentUserGeofence)
                
                Spacer(minLength: 0)
                
                ModernGroupsSection(
                    groups: groups,
                    selectedGroup: $selectedGroup,
                    currentGeofence: geofenceManager.currentUserGeofence,
                    showingCreateGroup: $showingCreateGroup
                )
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)
        }
    }
    
    @ViewBuilder
    private var mapView: some View {
        Map(position: $cameraPosition) {
            UserAnnotation()
            
            ForEach(annotations) { annotation in
                let isCurrentGeofence = annotation.identifier == geofenceManager.currentUserGeofence
                
                if isCurrentGeofence {
                    MapCircle(center: annotation.coordinate, radius: annotation.radius)
                        .foregroundStyle(Color.accent.opacity(0.4))
                        .stroke(Color.accent, lineWidth: 3)
                } else {
                    MapCircle(center: annotation.coordinate, radius: annotation.radius)
                        .foregroundStyle(Color.gray.opacity(0.15))
                        .stroke(Color.gray, lineWidth: 1)
                }
                
                Annotation(annotation.identifier, coordinate: annotation.coordinate) {
                    geofenceAnnotationView(for: annotation, isCurrentGeofence: isCurrentGeofence)
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
            
            // Animate to current geofence after map is visible
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if !hasPerformedInitialZoom {
                    animateToCurrentGeofenceIfNeeded()
                    hasPerformedInitialZoom = true
                }
            }
        }
        .onChange(of: geofenceManager.monitoredRegions) { oldValue, newValue in
            cameraPosition = .region(calculateMapRegion())
            hasPerformedInitialZoom = false
            
            // Animate to current geofence after region update
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if !hasPerformedInitialZoom {
                    animateToCurrentGeofenceIfNeeded()
                    hasPerformedInitialZoom = true
                }
            }
        }
        .onChange(of: geofenceManager.currentUserGeofence) { oldValue, newValue in
            if newValue != nil {
                // User entered a geofence - animate to it
                animateToCurrentGeofenceIfNeeded()
            } else {
                // User left all geofences - zoom out to show all
                withAnimation(.easeInOut(duration: 1.0)) {
                    cameraPosition = .region(calculateAllGeofencesRegion())
                }
            }
        }
    }
    
    @ViewBuilder
    private func geofenceAnnotationView(for annotation: GeofenceAnnotation, isCurrentGeofence: Bool) -> some View {
        Button(action: {
            if let region = geofenceManager.monitoredRegions.first(where: { $0.identifier == annotation.identifier }) {
                selectedRegion = region
                showingRegionDetail = true
            }
        }) {
            VStack(spacing: 4) {
                if isCurrentGeofence {
                    Image(systemName: "location.fill.viewfinder")
                        .font(.title)
                        .foregroundColor(.accent)
                        .background(
                            Circle()
                                .fill(.white)
                                .frame(width: 40, height: 40)
                                .shadow(color: Color.accent.opacity(0.4), radius: 8, x: 0, y: 4)
                        )
                } else {
                    Image(systemName: "location.circle")
                        .font(.callout)
                        .foregroundColor(.gray)
                        .background(
                            Circle()
                                .fill(.white)
                                .frame(width: 24, height: 24)
                                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
                        )
                }
                
                Text(annotation.identifier)
                    .font(isCurrentGeofence ? .caption : .caption2)
                    .fontWeight(isCurrentGeofence ? .bold : .medium)
                    .foregroundColor(isCurrentGeofence ? .accent : .gray)
                    .padding(.horizontal, isCurrentGeofence ? 12 : 6)
                    .padding(.vertical, isCurrentGeofence ? 6 : 3)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.ultraThinMaterial)
                            .shadow(
                                color: isCurrentGeofence ? Color.accent.opacity(0.3) : .black.opacity(0.1), 
                                radius: isCurrentGeofence ? 6 : 2, 
                                x: 0, 
                                y: isCurrentGeofence ? 3 : 1
                            )
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
        .background(Color.background.ignoresSafeArea())
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

struct ModernGroupsSection: View {
    let groups: [UserGroup]
    @Binding var selectedGroup: UserGroup?
    let currentGeofence: String?
    @Binding var showingCreateGroup: Bool
    
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
                        .padding(.vertical, 10) // Extra space for scaling and shadow
                    }
                    
                    // Add New Group Button
                    ModernAddGroupCard {
                        showingCreateGroup = true
                    }
                    .padding(.vertical, 10) // Consistent spacing
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 5) // Additional space for shadows
            }
        }
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 4)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 34) // Safe area bottom padding
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
                    .fill(isSelected ? .thinMaterial : .ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: isSelected 
                                    ? [Color.accent.opacity(0.8), Color.accentLight.opacity(0.6)]
                                    : [Color.clear, Color.clear],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(isSelected ? Color.accent : Color.clear, lineWidth: isSelected ? 2 : 0)
                    )
                    .shadow(color: isSelected ? Color.accent.opacity(0.4) : .black.opacity(0.08), radius: isSelected ? 15 : 8, x: 0, y: isSelected ? 8 : 4)
            )
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isSelected)
        .allowsHitTesting(true)
    }
}

struct ModernAddGroupCard: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            action()
        }) {
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
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            )
        }
    }
}

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var groupName = ""
    @State private var selectedEmoji = "🏠"

    
    private let availableEmojis = [
        "🏠", "🏢", "🎓", "🍕", "☕️", "🛒", "🍔", "🏛️",
        "🚗", "✈️", "🚇", "🏃‍♂️", "💼", "🎭", "🎪", "🌮"
    ]
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 24) {
                    Text("Create New Group")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    // Emoji Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Choose an Icon")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 8), spacing: 12) {
                            ForEach(availableEmojis, id: \.self) { emoji in
                                Button(action: {
                                    selectedEmoji = emoji
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                }) {
                                    let isSelected = selectedEmoji == emoji
                                    let backgroundColor = isSelected ? Color.blue.opacity(0.2) : Color.background.opacity(0.8)
                                    let borderColor = isSelected ? Color.blue : Color.clear
                                    
                                    Text(emoji)
                                        .font(.title2)
                                        .frame(width: 44, height: 44)
                                        .background(backgroundColor)
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(borderColor, lineWidth: 2)
                                        )
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                // Form Section
                VStack(spacing: 20) {
                    // Group Name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Group Name")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        TextField("Enter group name", text: $groupName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.body)
                    }
                    
                    // Info about adding people
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Adding People")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("People can join this group using invite links after creation.")
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.leading)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                
                Spacer()
                
                // Action Buttons
                VStack(spacing: 12) {
                    Button(action: createGroup) {
                        let isDisabled = groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        let buttonOpacity = isDisabled ? 0.6 : 1.0
                        
                        HStack {
                            Text("Create Group")
                                .fontWeight(.semibold)
                            
                            Image(systemName: "arrow.right")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            LinearGradient(
                                colors: [Color.blue, Color.purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(12)
                        .opacity(buttonOpacity)
                    }
                    .disabled(groupName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Cancel")
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .background(Color.background)
        }
    }
    

    
    private func createGroup() {
        let trimmedName = groupName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmedName.isEmpty {
            // TODO: Save the group (name: trimmedName, emoji: selectedEmoji, people: [])
            print("Creating group: \(trimmedName) \(selectedEmoji)")
            
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            dismiss()
        }
    }
}

