import Foundation
import CoreLocation

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