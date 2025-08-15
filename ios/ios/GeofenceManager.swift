import CoreLocation
import UserNotifications

class GeofenceManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var monitoredRegions: [CLCircularRegion] = []
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentUserGeofence: String? = nil // Track which geofence the user is currently in
    @Published var isGhostModeEnabled: Bool = false
    
    override init() {
        super.init()
        setupLocationManager()
        setupNotifications()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
        locationManager.showsBackgroundLocationIndicator = true
        locationManager.startUpdatingLocation() // Start location updates
    }
    
    private func setupNotifications() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
        
        // Configure notification categories
        let enterCategory = UNNotificationCategory(
            identifier: "GEOFENCE_ENTER",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        let exitCategory = UNNotificationCategory(
            identifier: "GEOFENCE_EXIT",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        
        center.setNotificationCategories([enterCategory, exitCategory])
    }
    
    func requestLocationPermission() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func loadGeofences() {
        guard !isGhostModeEnabled else {
            print("Ghost Mode is enabled — skipping geofence load")
            return
        }
        guard let url = Bundle.main.url(forResource: "Locations", withExtension: "json") else {
            print("Could not find Locations.json in app bundle")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let locationData = try JSONDecoder().decode(LocationData.self, from: data)
            
            // Remove existing geofences
            for region in monitoredRegions {
                locationManager.stopMonitoring(for: region)
            }
            monitoredRegions.removeAll()
            
            // Add new geofences
            for location in locationData.locations {
                addGeofence(latitude: location.latitude,
                           longitude: location.longitude,
                           radius: location.radius,
                           identifier: location.areaCode)
            }
            
            // Check current location to determine which geofence we're in
            checkCurrentLocation()
        } catch {
            print("Error loading geofences: \(error.localizedDescription)")
        }
    }
    
    private func checkCurrentLocation() {
        guard let currentLocation = locationManager.location else {
            print("Current location not available")
            return
        }
        
        // Check which geofence contains the current location
        for region in monitoredRegions {
            let distance = currentLocation.distance(from: CLLocation(latitude: region.center.latitude, longitude: region.center.longitude))
            if distance <= region.radius {
                print("User is currently in geofence: \(region.identifier)")
                currentUserGeofence = region.identifier
                break
            }
        }
    }
    
    func addGeofence(latitude: Double, longitude: Double, radius: Double, identifier: String) {
        let region = CLCircularRegion(center: CLLocationCoordinate2D(latitude: latitude, longitude: longitude),
                                    radius: radius,
                                    identifier: identifier)
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        // Check if we can monitor this region
        if CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) {
            locationManager.startMonitoring(for: region)
            monitoredRegions.append(region)
            print("Started monitoring region: \(identifier)")
        } else {
            print("Region monitoring is not available")
        }
    }
    
    func removeGeofence(identifier: String) {
        if let region = monitoredRegions.first(where: { $0.identifier == identifier }) {
            locationManager.stopMonitoring(for: region)
            monitoredRegions.removeAll { $0.identifier == identifier }
            print("Stopped monitoring region: \(identifier)")
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        print("Location authorization status changed to: \(manager.authorizationStatus.rawValue)")
        
        if manager.authorizationStatus == .authorizedAlways {
            loadGeofences()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        print("Started monitoring region: \(region.identifier)")
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("Monitoring failed for region: \(region?.identifier ?? "unknown")")
        print("Error: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        guard !isGhostModeEnabled else { return }
        print("Entered region: \(region.identifier)")
        currentUserGeofence = region.identifier
        sendNotification(title: "Entered Region", body: "You have entered \(region.identifier)", category: "GEOFENCE_ENTER")
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        guard !isGhostModeEnabled else { return }
        print("Exited region: \(region.identifier)")
        // Only clear current geofence if we're exiting the one we're currently in
        if currentUserGeofence == region.identifier {
            currentUserGeofence = nil
        }
        sendNotification(title: "Exited Region", body: "You have exited \(region.identifier)", category: "GEOFENCE_EXIT")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard !isGhostModeEnabled else { return }
        guard let currentLocation = locations.last else { return }
        
        // Check which geofence contains the current location
        var foundGeofence: String? = nil
        for region in monitoredRegions {
            let distance = currentLocation.distance(from: CLLocation(latitude: region.center.latitude, longitude: region.center.longitude))
            if distance <= region.radius {
                foundGeofence = region.identifier
                break
            }
        }
        
        // Update current geofence if it changed
        if currentUserGeofence != foundGeofence {
            currentUserGeofence = foundGeofence
        }
    }
    
    private func sendNotification(title: String, body: String, category: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.categoryIdentifier = category
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error sending notification: \(error.localizedDescription)")
            } else {
                print("Notification sent successfully")
            }
        }
    }
} 

// MARK: - Ghost Mode Controls
extension GeofenceManager {
    func enableGhostMode() {
        guard !isGhostModeEnabled else { return }
        isGhostModeEnabled = true
        print("👻 Enabling Ghost Mode: stopping monitoring and clearing state")
        
        // Stop monitoring all regions
        for region in monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        
        // Clear current geofence and stop location updates
        currentUserGeofence = nil
        locationManager.stopUpdatingLocation()
    }
    
    func disableGhostMode() {
        guard isGhostModeEnabled else { return }
        isGhostModeEnabled = false
        print("🛰️ Disabling Ghost Mode: resuming monitoring and location updates")
        
        // Resume location updates and reload geofences if authorized
        locationManager.startUpdatingLocation()
        if authorizationStatus == .authorizedAlways {
            loadGeofences()
        }
    }
}