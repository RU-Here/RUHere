import Foundation

struct Location: Codable {
    let name: String
    let latitude: Double
    let longitude: Double
    let radius: Double
    let areaCode: String
}

struct LocationData: Codable {
    let locations: [Location]
} 
