import CoreLocation
import UserNotifications

class GeofenceManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    @Published var monitoredRegions: [CLCircularRegion] = []
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    
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
                           identifier: location.name)
            }
        } catch {
            print("Error loading geofences: \(error.localizedDescription)")
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
        print("Entered region: \(region.identifier)")
        sendNotification(title: "Entered Region", body: "You have entered \(region.identifier)", category: "GEOFENCE_ENTER")
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        print("Exited region: \(region.identifier)")
        sendNotification(title: "Exited Region", body: "You have exited \(region.identifier)", category: "GEOFENCE_EXIT")
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