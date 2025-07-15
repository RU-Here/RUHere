package com.example.testapp

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.google.android.gms.maps.CameraUpdateFactory
import com.google.android.gms.maps.model.*
import com.google.maps.android.compose.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GeofenceMapView(
    geofenceManager: GeofenceManager,
    selectedGroup: UserGroup?,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    val monitoredRegions by geofenceManager.monitoredRegions.collectAsState()
    val currentUserGeofence by geofenceManager.currentUserGeofence.collectAsState()
    val currentLocation by geofenceManager.currentLocation.collectAsState()
    val hasLocationPermission by geofenceManager.hasLocationPermission.collectAsState()
    
    // Calculate camera position based on monitored regions
    val cameraPositionState = rememberCameraPositionState {
        position = if (monitoredRegions.isNotEmpty()) {
            val center = calculateCenterPoint(monitoredRegions.map { it.center })
            println("GeofenceMapView: Setting camera to center of ${monitoredRegions.size} regions: ${center.latitude}, ${center.longitude}")
            CameraPosition.fromLatLngZoom(center, 12f)
        } else {
            // Default to Rutgers University area
            println("GeofenceMapView: No monitored regions, using default Rutgers location: 40.5017, -74.4474")
            CameraPosition.fromLatLngZoom(LatLng(40.5017, -74.4474), 12f)
        }
    }
    
    // Update camera when current location changes
    LaunchedEffect(currentLocation) {
        currentLocation?.let { location ->
            cameraPositionState.animate(
                CameraUpdateFactory.newLatLngZoom(location, 15f),
                1000
            )
        }
    }
    
    GoogleMap(
        modifier = modifier.fillMaxSize(),
        cameraPositionState = cameraPositionState,
        uiSettings = MapUiSettings(
            zoomControlsEnabled = true,
            mapToolbarEnabled = false,
            myLocationButtonEnabled = hasLocationPermission,
            compassEnabled = true
        ),
        properties = MapProperties(
            isMyLocationEnabled = hasLocationPermission,
            mapType = MapType.NORMAL
        )
    ) {
        // Draw geofence circles
        monitoredRegions.forEach { region ->
            Circle(
                center = region.center,
                radius = region.radius,
                fillColor = Color(0x330000FF), // Semi-transparent blue
                strokeColor = Color(0xFF0000FF), // Blue border
                strokeWidth = 3.toFloat()
            )
            
            // Add markers for geofence centers
            Marker(
                state = MarkerState(position = region.center),
                title = region.name,
                snippet = "Area Code: ${region.id}"
            )
        }
        
        // Draw person annotations for selected group
        selectedGroup?.let { group ->
            currentUserGeofence?.let { userGeofence ->
                val peopleInCurrentGeofence = group.people.filter { it.areaCode == userGeofence }
                val groupedPeople = peopleInCurrentGeofence.groupBy { it.areaCode }
                
                groupedPeople.forEach { (areaCode, people) ->
                    val region = monitoredRegions.find { it.id == areaCode }
                    region?.let {
                        val personCount = people.size
                        val names = people.joinToString(", ") { it.name }
                        
                        Marker(
                            state = MarkerState(position = region.center),
                            title = "${group.emoji} ${group.name}",
                            snippet = "$personCount people: $names",
                            icon = BitmapDescriptorFactory.defaultMarker(BitmapDescriptorFactory.HUE_RED)
                        )
                    }
                }
            }
        }
        
        // Add marker for current location if available
        currentLocation?.let { location ->
            Marker(
                state = MarkerState(position = location),
                title = "Your Location",
                snippet = currentUserGeofence?.let { "In: $it" } ?: "Not in any geofence",
                icon = BitmapDescriptorFactory.defaultMarker(BitmapDescriptorFactory.HUE_GREEN)
            )
        }
    }
}

private fun calculateCenterPoint(points: List<LatLng>): LatLng {
    if (points.isEmpty()) {
        println("calculateCenterPoint: No points provided, returning default location")
        return LatLng(40.5017, -74.4474)
    }
    
    println("calculateCenterPoint: Processing ${points.size} points:")
    points.forEach { point ->
        println("  Point: ${point.latitude}, ${point.longitude}")
    }
    
    var totalLat = 0.0
    var totalLng = 0.0
    
    points.forEach { point ->
        totalLat += point.latitude
        totalLng += point.longitude
    }
    
    val result = LatLng(
        totalLat / points.size,
        totalLng / points.size
    )
    
    println("calculateCenterPoint: Center calculated as: ${result.latitude}, ${result.longitude}")
    return result
}

@Composable
fun GeofenceInfoCard(
    geofenceManager: GeofenceManager,
    modifier: Modifier = Modifier
) {
    val currentUserGeofence by geofenceManager.currentUserGeofence.collectAsState()
    val monitoredRegions by geofenceManager.monitoredRegions.collectAsState()
    val hasLocationPermission by geofenceManager.hasLocationPermission.collectAsState()
    val currentLocation by geofenceManager.currentLocation.collectAsState()
    val isLocationEnabled by geofenceManager.isLocationEnabled.collectAsState()
    
    Card(
        modifier = modifier
            .fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = "Current Status",
                style = MaterialTheme.typography.headlineSmall
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            // Permission Status
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                val permissionColor = if (hasLocationPermission) Color(0xFF4CAF50) else Color(0xFFF44336)
                Box(
                    modifier = Modifier
                        .size(12.dp)
                        .background(permissionColor, CircleShape)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "Permission: ${if (hasLocationPermission) "Granted" else "Not Granted"}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = permissionColor
                )
            }
            
            Spacer(modifier = Modifier.height(4.dp))
            
            // Location Services Status
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                val servicesColor = if (isLocationEnabled) Color(0xFF4CAF50) else Color(0xFFF44336)
                Box(
                    modifier = Modifier
                        .size(12.dp)
                        .background(servicesColor, CircleShape)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "Location Services: ${if (isLocationEnabled) "Enabled" else "Disabled"}",
                    style = MaterialTheme.typography.bodyMedium,
                    color = servicesColor
                )
            }
            
            Spacer(modifier = Modifier.height(4.dp))
            
            // Current Location Status
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                val locationColor = if (currentLocation != null) Color(0xFF4CAF50) else Color(0xFFFF9800)
                Box(
                    modifier = Modifier
                        .size(12.dp)
                        .background(locationColor, CircleShape)
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = if (currentLocation != null) {
                        "Location: ${String.format("%.4f", currentLocation!!.latitude)}, ${String.format("%.4f", currentLocation!!.longitude)}"
                    } else {
                        if (hasLocationPermission && isLocationEnabled) "Location: Searching..." else "Location: Not available"
                    },
                    style = MaterialTheme.typography.bodyMedium,
                    color = locationColor
                )
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            if (currentUserGeofence != null) {
                val region = monitoredRegions.find { it.id == currentUserGeofence }
                Text(
                    text = "You are in: ${region?.name ?: currentUserGeofence}",
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.primary
                )
            } else {
                Text(
                    text = if (currentLocation != null) "You are not in any monitored area" else "Waiting for location...",
                    style = MaterialTheme.typography.bodyLarge,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = "Monitoring ${monitoredRegions.size} regions",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            
            // Troubleshooting and action buttons
            if (!hasLocationPermission || !isLocationEnabled || currentLocation == null) {
                Spacer(modifier = Modifier.height(8.dp))
                
                if (!hasLocationPermission) {
                    Text(
                        text = "⚠️ Grant location permission in app settings",
                        style = MaterialTheme.typography.bodySmall,
                        color = Color(0xFFF44336)
                    )
                } else if (!isLocationEnabled) {
                    Text(
                        text = "⚠️ Enable location services in device settings",
                        style = MaterialTheme.typography.bodySmall,
                        color = Color(0xFFF44336)
                    )
                } else if (currentLocation == null) {
                    Button(
                        onClick = { geofenceManager.refreshLocationServices() },
                        modifier = Modifier.fillMaxWidth(),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = Color(0xFFFF9800)
                        )
                    ) {
                        Text("Refresh Location Services")
                    }
                }
            }
        }
    }
} 