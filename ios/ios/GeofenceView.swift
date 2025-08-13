import SwiftUI
import CoreLocation
import MapKit

struct GeofenceView: View {
    @StateObject private var geofenceManager = GeofenceManager()
    @EnvironmentObject var groupService: GroupService
    @EnvironmentObject var authService: AuthenticationService
    @State private var cameraPosition: MapCameraPosition = .automatic
    @State private var selectedRegion: CLCircularRegion?
    @State private var showingRegionDetail = false
    @State private var selectedGroup: UserGroup?
    @State private var showingCreateGroup = false
    @State private var showingManageGroup = false
    @State private var showingProfile = false
    @State private var hasPerformedInitialZoom = false
    
    // MARK: - Computed Properties
    
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
        PersonAnnotationCalculator.calculatePersonAnnotations(
            currentUserGeofence: geofenceManager.currentUserGeofence,
            selectedGroup: selectedGroup,
            groups: groupService.groups,
            monitoredRegions: geofenceManager.monitoredRegions
        )
    }
    
    // MARK: - View Body
    
    var body: some View {
        NavigationView {
            mainContentView
            .navigationTitle("RUHere")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(false)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingProfile = true
                    }) {
                        Image(systemName: "person.circle.fill")
                            .font(.title)
                            .foregroundColor(.accent)
                            .background(
                                Circle()
                                    .fill(.ultraThinMaterial)
                                    .frame(width: 36, height: 36)
                            )
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        if geofenceManager.isGhostModeEnabled {
                            geofenceManager.disableGhostMode()
                            // If not immediately in a geofence after re-enabling, keep the all-geofences view
                            if geofenceManager.currentUserGeofence == nil {
                                withAnimation(.easeInOut(duration: 1.0)) {
                                    cameraPosition = .region(
                                        MapUtilities.calculateAllGeofencesRegion(from: geofenceManager.monitoredRegions)
                                    )
                                }
                            }
                        } else {
                            geofenceManager.enableGhostMode()
                            withAnimation(.easeInOut(duration: 1.0)) {
                                cameraPosition = .region(
                                    MapUtilities.calculateAllGeofencesRegion(from: geofenceManager.monitoredRegions)
                                )
                            }
                        }
                    }) {
                        Text("👻")
                            .font(.title2)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(geofenceManager.isGhostModeEnabled ? Color.gray.opacity(0.2) : Color.accent.opacity(0.15))
                            )
                            .overlay(
                                Circle()
                                    .stroke(geofenceManager.isGhostModeEnabled ? Color.gray : Color.accent, lineWidth: 1)
                            )
                            .cornerRadius(18)
                            .accessibilityLabel(geofenceManager.isGhostModeEnabled ? "Disable Ghost Mode" : "Enable Ghost Mode")
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
            .task {
                if let userId = getUserId() {
                    await groupService.fetchGroups(for: userId)
                }
            }
            .refreshable {
                if let userId = getUserId() {
                    await groupService.fetchGroups(for: userId)
                }
            }
            .sheet(isPresented: $showingProfile) {
                ProfileView()
            }
        }
    }
    
    // MARK: - Private Views
    
    @ViewBuilder
    private var mainContentView: some View {
        ZStack {
            switch geofenceManager.authorizationStatus {
            case .notDetermined:
                LocationPermissionView(geofenceManager: geofenceManager)
            case .authorizedAlways:
                authorizedView
            default:
                LocationDeniedView()
            }
        }
        .ignoresSafeArea(.all, edges: .bottom)
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
                    groups: groupService.groups,
                    selectedGroup: $selectedGroup,
                    currentGeofence: geofenceManager.currentUserGeofence,
                    showingCreateGroup: $showingCreateGroup,
                    isLoading: groupService.isLoading,
                    errorMessage: groupService.errorMessage
                )
                .overlay(alignment: .topTrailing) {
                    if let selectedGroup, let currentUserId = authService.user?.uid ?? (authService.isGuestMode ? "guest_user" : nil), selectedGroup.admin == currentUserId {
                        Button {
                            showingManageGroup = true
                        } label: {
                            Label("Manage", systemImage: "gearshape.fill")
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                        }
                        .padding(.trailing, 28)
                        .padding(.top, 8)
                    }
                }
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
                
                MapCircle(center: annotation.coordinate, radius: annotation.radius)
                    .foregroundStyle(
                        isCurrentGeofence
                        ? AnyShapeStyle(LinearGradient(colors: [Color.accent.opacity(0.35), Color.accentLight.opacity(0.25)], startPoint: .top, endPoint: .bottom))
                        : AnyShapeStyle(LinearGradient(colors: [Color.gray.opacity(0.12), Color.gray.opacity(0.08)], startPoint: .top, endPoint: .bottom))
                    )
                    .stroke(
                        isCurrentGeofence
                        ? AnyShapeStyle(LinearGradient(colors: [Color.accent, Color.accentLight], startPoint: .leading, endPoint: .trailing))
                        : AnyShapeStyle(Color.gray),
                        lineWidth: isCurrentGeofence ? 3 : 1
                    )
                
                Annotation(annotation.identifier, coordinate: annotation.coordinate) {
                    GeofenceAnnotationView(
                        annotation: annotation, 
                        isCurrentGeofence: isCurrentGeofence
                    ) {
                        if let region = geofenceManager.monitoredRegions.first(where: { $0.identifier == annotation.identifier }) {
                            selectedRegion = region
                            showingRegionDetail = true
                        }
                    }
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
            setupInitialMapView()
        }
        .onChange(of: geofenceManager.monitoredRegions) { oldValue, newValue in
            handleRegionsChange()
        }
        .onChange(of: geofenceManager.currentUserGeofence) { oldValue, newValue in
            handleUserGeofenceChange()
        }
        .sheet(isPresented: $showingManageGroup) {
            if let g = selectedGroup {
                ManageGroupView(group: g)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupInitialMapView() {
        cameraPosition = .region(MapUtilities.calculateAllGeofencesRegion(from: geofenceManager.monitoredRegions))
        
        // Animate to current geofence after map is visible
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if !hasPerformedInitialZoom {
                animateToCurrentGeofenceIfNeeded()
                hasPerformedInitialZoom = true
            }
        }
    }
    
    private func handleRegionsChange() {
        if geofenceManager.isGhostModeEnabled { return }
        cameraPosition = .region(MapUtilities.calculateAllGeofencesRegion(from: geofenceManager.monitoredRegions))
        hasPerformedInitialZoom = false
        
        // Animate to current geofence after region update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if !hasPerformedInitialZoom {
                animateToCurrentGeofenceIfNeeded()
                hasPerformedInitialZoom = true
            }
        }
    }
    
    private func handleUserGeofenceChange() {
        if geofenceManager.isGhostModeEnabled { return }
        if geofenceManager.currentUserGeofence != nil {
            // User entered a geofence - animate to it
            animateToCurrentGeofenceIfNeeded()
        } else {
            // User left all geofences - zoom out to show all
            withAnimation(.easeInOut(duration: 1.0)) {
                cameraPosition = .region(MapUtilities.calculateAllGeofencesRegion(from: geofenceManager.monitoredRegions))
            }
        }
    }
    
    private func animateToCurrentGeofenceIfNeeded() {
        guard let currentGeofence = geofenceManager.currentUserGeofence,
              let currentRegion = geofenceManager.monitoredRegions.first(where: { $0.identifier == currentGeofence }) else {
            return
        }
        
        withAnimation(.easeInOut(duration: 1.5)) {
            cameraPosition = .region(MapUtilities.calculateRegionForGeofence(currentRegion))
        }
    }
    
    // MARK: - Helper Methods
    
    private func getUserId() -> String? {
        if let user = authService.user {
            return user.uid
        } else if authService.isGuestMode {
            // For guest mode, use a default guest ID or generate a unique one
            return "guest_user"
        }
        return nil
    }
}
    

// MARK: - Supporting Components

struct GeofenceAnnotationView: View {
    let annotation: GeofenceAnnotation
    let isCurrentGeofence: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                if isCurrentGeofence {
                    ZStack {
                        Circle()
                            .fill(AppGradients.primary)
                            .frame(width: 44, height: 44)
                            .shadow(color: Color.accent.opacity(0.5), radius: 10, x: 0, y: 6)
                        Image(systemName: "location.fill.viewfinder")
                            .foregroundColor(.white)
                            .font(.title3)
                    }
                } else {
                    ZStack {
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: 26, height: 26)
                            .shadow(color: .black.opacity(0.12), radius: 3, x: 0, y: 1)
                        Image(systemName: "location.circle")
                            .foregroundColor(.gray)
                            .font(.subheadline)
                    }
                }
                
                Text(annotation.identifier)
                    .font(isCurrentGeofence ? .caption : .caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(isCurrentGeofence ? .white : .white.opacity(0.9))
                    .padding(.horizontal, isCurrentGeofence ? 12 : 8)
                    .padding(.vertical, isCurrentGeofence ? 6 : 4)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                isCurrentGeofence
                                ? AnyShapeStyle(AppGradients.primary)
                                : AnyShapeStyle(Color.black.opacity(0.4))
                            )
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                    )
            }
        }
    }
}

struct LocationPermissionView: View {
    let geofenceManager: GeofenceManager
    
    var body: some View {
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
            
            Spacer()
        }
        .padding()
        .background(AppBackground())
    }
}

struct LocationDeniedView: View {
    var body: some View {
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
        .background(AppBackground())
    }
}

struct PersonAnnotationCalculator {
    static func calculatePersonAnnotations(
        currentUserGeofence: String?,
        selectedGroup: UserGroup?,
        groups: [UserGroup],
        monitoredRegions: [CLCircularRegion]
    ) -> [PersonAnnotation] {
        guard let currentUserGeofence = currentUserGeofence else {
            print("User is not currently in any geofence")
            return []
        }
        
        print("Monitored regions: \(monitoredRegions.map { $0.identifier })")
        print("Current user geofence: \(currentUserGeofence)")
        
        if let selectedGroup = selectedGroup {
            return calculateSelectedGroupAnnotations(
                selectedGroup: selectedGroup,
                currentUserGeofence: currentUserGeofence,
                monitoredRegions: monitoredRegions
            )
        } else {
            return calculateAllGroupsAnnotations(
                groups: groups,
                currentUserGeofence: currentUserGeofence,
                monitoredRegions: monitoredRegions
            )
        }
    }
    
    private static func calculateSelectedGroupAnnotations(
        selectedGroup: UserGroup,
        currentUserGeofence: String,
        monitoredRegions: [CLCircularRegion]
    ) -> [PersonAnnotation] {
        // Filter people to only those in the same geofence as the current user
        let peopleInCurrentGeofence = selectedGroup.people.filter { $0.areaCode == currentUserGeofence }
        
        // Create individual annotations for each person
        return peopleInCurrentGeofence.enumerated().compactMap { (index, person) -> PersonAnnotation? in
            if let region = monitoredRegions.first(where: { $0.identifier == currentUserGeofence }) {
                let scatteredCoordinate = MapUtilities.calculateScatteredPosition(
                    centerCoordinate: region.center,
                    radius: region.radius,
                    groupIndex: index,
                    totalGroups: peopleInCurrentGeofence.count
                )
                
                return PersonAnnotation(person: person, coordinate: scatteredCoordinate, allPeople: [person], group: nil)
            }
            return nil
        }
    }
    
    private static func calculateAllGroupsAnnotations(
        groups: [UserGroup],
        currentUserGeofence: String,
        monitoredRegions: [CLCircularRegion]
    ) -> [PersonAnnotation] {
        // Collect all people from all groups who are in the current geofence
        var allPeopleInGeofence: [Person] = []
        for group in groups {
            let peopleInGeofence = group.people.filter { $0.areaCode == currentUserGeofence }
            allPeopleInGeofence.append(contentsOf: peopleInGeofence)
        }
        
        // Remove duplicates based on person ID
        let uniquePeople = Array(Set(allPeopleInGeofence.map { $0.id }))
            .compactMap { personId in allPeopleInGeofence.first { $0.id == personId } }
        
        // Create individual annotations for each person
        return uniquePeople.enumerated().compactMap { (index, person) -> PersonAnnotation? in
            if let region = monitoredRegions.first(where: { $0.identifier == currentUserGeofence }) {
                let scatteredCoordinate = MapUtilities.calculateScatteredPosition(
                    centerCoordinate: region.center,
                    radius: region.radius,
                    groupIndex: index,
                    totalGroups: uniquePeople.count
                )
                
                return PersonAnnotation(person: person, coordinate: scatteredCoordinate, allPeople: [person], group: nil)
            }
            return nil
        }
    }
}



