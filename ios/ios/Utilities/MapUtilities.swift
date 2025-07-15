import Foundation
import CoreLocation
import MapKit

struct MapUtilities {
    
    static func calculateAllGeofencesRegion(from regions: [CLCircularRegion]) -> MKCoordinateRegion {
        guard !regions.isEmpty else {
            return MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
                span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
            )
        }
        
        var minLat = Double.infinity
        var maxLat = -Double.infinity
        var minLon = Double.infinity
        var maxLon = -Double.infinity
        
        for region in regions {
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
    
    static func calculateRegionForGeofence(_ geofence: CLCircularRegion) -> MKCoordinateRegion {
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
    
    static func calculateScatteredPosition(
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
} 