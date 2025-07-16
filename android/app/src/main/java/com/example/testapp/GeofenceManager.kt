package com.example.testapp

import android.Manifest
import android.app.Application
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationManager
import android.os.Build
import androidx.core.app.ActivityCompat
import androidx.core.app.NotificationCompat
import androidx.core.content.ContextCompat
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.google.android.gms.location.*
import com.google.android.gms.maps.model.LatLng
import com.google.gson.Gson
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.io.IOException
import kotlin.math.*

class GeofenceManager(application: Application) : AndroidViewModel(application) {
    
    private val context: Context = application.applicationContext
    private val geofencingClient: GeofencingClient = LocationServices.getGeofencingClient(context)
    private val fusedLocationClient: FusedLocationProviderClient = LocationServices.getFusedLocationProviderClient(context)
    private val notificationManager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
    
    private val _monitoredRegions = MutableStateFlow<List<GeofenceRegion>>(emptyList())
    val monitoredRegions: StateFlow<List<GeofenceRegion>> = _monitoredRegions.asStateFlow()
    
    private val _currentUserGeofence = MutableStateFlow<String?>(null)
    val currentUserGeofence: StateFlow<String?> = _currentUserGeofence.asStateFlow()
    
    private val _hasLocationPermission = MutableStateFlow(false)
    val hasLocationPermission: StateFlow<Boolean> = _hasLocationPermission.asStateFlow()
    
    private val _currentLocation = MutableStateFlow<LatLng?>(null)
    val currentLocation: StateFlow<LatLng?> = _currentLocation.asStateFlow()
    
    private val _isLocationEnabled = MutableStateFlow(false)
    val isLocationEnabled: StateFlow<Boolean> = _isLocationEnabled.asStateFlow()
    
    private var locationCallback: LocationCallback? = null
    
    init {
        println("GeofenceManager initialized")
        createNotificationChannel()
        checkLocationPermission()
        checkLocationEnabled()
        
        // If we already have permissions, start location services immediately
        if (_hasLocationPermission.value && _isLocationEnabled.value) {
            println("GeofenceManager init: Starting location services immediately")
            loadGeofences()
            startLocationUpdates()
        }
    }
    
    data class GeofenceRegion(
        val id: String,
        val center: LatLng,
        val radius: Double,
        val name: String
    )
    
    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                NOTIFICATION_CHANNEL_ID,
                "Geofence Notifications",
                NotificationManager.IMPORTANCE_DEFAULT
            ).apply {
                description = "Notifications for geofence entry and exit events"
                enableVibration(true)
                setShowBadge(true)
            }
            notificationManager.createNotificationChannel(channel)
        }
    }
    
    private fun checkLocationPermission() {
        val hasPermission = ContextCompat.checkSelfPermission(
            context,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED
        
        println("Checking location permission: $hasPermission")
        _hasLocationPermission.value = hasPermission
    }
    
    private fun checkLocationEnabled() {
        val locationManager = context.getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val isGpsEnabled = locationManager.isProviderEnabled(LocationManager.GPS_PROVIDER)
        val isNetworkEnabled = locationManager.isProviderEnabled(LocationManager.NETWORK_PROVIDER)
        val isEnabled = isGpsEnabled || isNetworkEnabled
        
        println("Checking location services: GPS=$isGpsEnabled, Network=$isNetworkEnabled, Overall=$isEnabled")
        _isLocationEnabled.value = isEnabled
    }
    
    fun loadGeofences() {
        println("Loading geofences...")
        viewModelScope.launch {
            try {
                val json = context.assets.open("RUHereLocations/Locations.json").bufferedReader().use { it.readText() }
                val locationData = Gson().fromJson(json, LocationData::class.java)
                
                // Remove existing geofences
                removeAllGeofences()
                
                // Create new geofence regions
                val regions = locationData.locations.map { location ->
                    println("Loading geofence: ${location.name} at ${location.latitude}, ${location.longitude}")
                    GeofenceRegion(
                        id = location.areaCode,
                        center = LatLng(location.latitude, location.longitude),
                        radius = location.radius,
                        name = location.name
                    )
                }
                
                _monitoredRegions.value = regions
                println("Loaded ${regions.size} geofence regions")
                
                // Log the loaded regions
                regions.forEach { region ->
                    println("Region: ${region.name} (${region.id}) at ${region.center.latitude}, ${region.center.longitude}")
                }
                
                // Start monitoring geofences
                addGeofences(regions)
                
                // Check current location
                checkCurrentLocation()
                
            } catch (e: IOException) {
                e.printStackTrace()
                println("Failed to load geofences from assets: ${e.message}")
            } catch (e: Exception) {
                e.printStackTrace()
                println("Unexpected error loading geofences: ${e.message}")
            }
        }
    }
    
    private fun addGeofences(regions: List<GeofenceRegion>) {
        if (!_hasLocationPermission.value) {
            println("Cannot add geofences: no location permission")
            return
        }
        
        val geofenceList = regions.map { region ->
            Geofence.Builder()
                .setRequestId(region.id)
                .setCircularRegion(
                    region.center.latitude,
                    region.center.longitude,
                    region.radius.toFloat()
                )
                .setExpirationDuration(Geofence.NEVER_EXPIRE)
                .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_ENTER or Geofence.GEOFENCE_TRANSITION_EXIT)
                .build()
        }
        
        val geofencingRequest = GeofencingRequest.Builder()
            .setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER)
            .addGeofences(geofenceList)
            .build()
        
        val geofencePendingIntent: PendingIntent by lazy {
            val intent = Intent(context, GeofenceBroadcastReceiver::class.java)
            PendingIntent.getBroadcast(
                context, 
                0, 
                intent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_MUTABLE
            )
        }
        
        if (ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            geofencingClient.addGeofences(geofencingRequest, geofencePendingIntent)
                .addOnSuccessListener {
                    println("Geofences added successfully")
                }
                .addOnFailureListener { e ->
                    e.printStackTrace()
                    println("Failed to add geofences: ${e.message}")
                }
        }
    }
    
    private fun removeAllGeofences() {
        val regionIds = _monitoredRegions.value.map { it.id }
        if (regionIds.isNotEmpty()) {
            geofencingClient.removeGeofences(regionIds)
            println("Removed ${regionIds.size} existing geofences")
        }
    }
    
    private fun startLocationUpdates() {
        if (!_hasLocationPermission.value) {
            println("Cannot start location updates: no permission")
            return
        }
        
        println("Starting location updates...")
        
        // Remove existing callback first
        locationCallback?.let { callback ->
            fusedLocationClient.removeLocationUpdates(callback)
        }
        
        val locationRequest = LocationRequest.Builder(Priority.PRIORITY_HIGH_ACCURACY, 10000)
            .setWaitForAccurateLocation(false)
            .setMinUpdateIntervalMillis(5000)
            .setMaxUpdateDelayMillis(15000)
            .build()
        
        locationCallback = object : LocationCallback() {
            override fun onLocationResult(locationResult: LocationResult) {
                locationResult.lastLocation?.let { location ->
                    val latLng = LatLng(location.latitude, location.longitude)
                    println("Location update received: ${location.latitude}, ${location.longitude}")
                    _currentLocation.value = latLng
                    checkCurrentGeofence(location)
                }
            }
        }
        
        if (ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            locationCallback?.let { callback ->
                fusedLocationClient.requestLocationUpdates(
                    locationRequest,
                    callback,
                    null
                ).addOnSuccessListener {
                    println("Location updates started successfully")
                }.addOnFailureListener { e ->
                    println("Failed to start location updates: ${e.message}")
                    e.printStackTrace()
                }
            }
        }
    }
    
    private fun checkCurrentLocation() {
        if (!_hasLocationPermission.value) {
            println("Cannot check current location: no permission")
            return
        }
        
        println("Checking current location...")
        
        if (ActivityCompat.checkSelfPermission(
                context,
                Manifest.permission.ACCESS_FINE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
        ) {
            fusedLocationClient.lastLocation
                .addOnSuccessListener { location ->
                    if (location != null) {
                        val latLng = LatLng(location.latitude, location.longitude)
                        println("Got last known location: ${location.latitude}, ${location.longitude}")
                        _currentLocation.value = latLng
                        checkCurrentGeofence(location)
                    } else {
                        println("No last known location available")
                    }
                }
                .addOnFailureListener { e ->
                    println("Failed to get last location: ${e.message}")
                    e.printStackTrace()
                }
        }
    }
    
    private fun checkCurrentGeofence(location: Location) {
        val currentLatLng = LatLng(location.latitude, location.longitude)
        
        var foundGeofence: String? = null
        for (region in _monitoredRegions.value) {
            val distance = calculateDistance(currentLatLng, region.center)
            if (distance <= region.radius) {
                foundGeofence = region.id
                break
            }
        }
        
        if (_currentUserGeofence.value != foundGeofence) {
            _currentUserGeofence.value = foundGeofence
            println("User is now in geofence: ${foundGeofence ?: "none"}")
        }
    }
    
    private fun calculateDistance(point1: LatLng, point2: LatLng): Double {
        val earthRadius = 6371000.0 // Earth's radius in meters
        
        val lat1Rad = Math.toRadians(point1.latitude)
        val lat2Rad = Math.toRadians(point2.latitude)
        val deltaLatRad = Math.toRadians(point2.latitude - point1.latitude)
        val deltaLngRad = Math.toRadians(point2.longitude - point1.longitude)
        
        val a = sin(deltaLatRad / 2).pow(2) +
                cos(lat1Rad) * cos(lat2Rad) *
                sin(deltaLngRad / 2).pow(2)
        val c = 2 * atan2(sqrt(a), sqrt(1 - a))
        
        return earthRadius * c
    }
    
    fun handleGeofenceTransition(geofenceId: String, transitionType: Int) {
        val region = _monitoredRegions.value.find { it.id == geofenceId }
        
        when (transitionType) {
            Geofence.GEOFENCE_TRANSITION_ENTER -> {
                _currentUserGeofence.value = geofenceId
                sendNotification(
                    "Entered Region",
                    "You have entered ${region?.name ?: geofenceId}",
                    "GEOFENCE_ENTER"
                )
                println("Entered geofence: $geofenceId")
            }
            Geofence.GEOFENCE_TRANSITION_EXIT -> {
                if (_currentUserGeofence.value == geofenceId) {
                    _currentUserGeofence.value = null
                }
                sendNotification(
                    "Exited Region",
                    "You have exited ${region?.name ?: geofenceId}",
                    "GEOFENCE_EXIT"
                )
                println("Exited geofence: $geofenceId")
            }
        }
    }
    
    private fun sendNotification(title: String, body: String, category: String) {
        val notification = NotificationCompat.Builder(context, NOTIFICATION_CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(body)
            .setSmallIcon(R.drawable.ic_launcher_foreground)
            .setAutoCancel(true)
            .setPriority(NotificationCompat.PRIORITY_DEFAULT)
            .setCategory(category)
            .build()
        
        notificationManager.notify(
            System.currentTimeMillis().toInt(),
            notification
        )
    }
    
    fun requestLocationPermission() {
        println("requestLocationPermission() called")
        checkLocationPermission()
        checkLocationEnabled()
        
        println("requestLocationPermission: hasPermission=${_hasLocationPermission.value}, isEnabled=${_isLocationEnabled.value}")
        
        if (_hasLocationPermission.value) {
            if (_isLocationEnabled.value) {
                println("Permission granted and location services enabled, loading geofences and starting location updates")
                loadGeofences()
                startLocationUpdates()
            } else {
                println("Permission granted but location services are disabled")
            }
        } else {
            println("Location permission not granted")
        }
    }
    
    // Add method to force refresh location services
    fun refreshLocationServices() {
        println("Refreshing location services...")
        checkLocationPermission()
        checkLocationEnabled()
        if (_hasLocationPermission.value) {
            if (_isLocationEnabled.value) {
                // Stop existing updates
                locationCallback?.let { callback ->
                    fusedLocationClient.removeLocationUpdates(callback)
                }
                // Restart everything
                loadGeofences()
                startLocationUpdates()
            } else {
                println("Cannot refresh: location services are disabled on device")
            }
        }
    }
    
    // Add a public method to manually start location updates for testing
    fun forceStartLocationUpdates() {
        println("Force starting location updates...")
        checkLocationPermission()
        checkLocationEnabled()
        if (_hasLocationPermission.value && _isLocationEnabled.value) {
            startLocationUpdates()
        } else {
            println("Cannot force start: permission=${_hasLocationPermission.value}, enabled=${_isLocationEnabled.value}")
        }
    }
    
    // Add method to test with mock location data
    fun setMockLocation() {
        println("Setting mock location to College Avenue Student Center")
        val mockLocation = LatLng(40.5014, -74.4474) // College Avenue Student Center
        _currentLocation.value = mockLocation
        println("Mock location set to: ${mockLocation.latitude}, ${mockLocation.longitude}")
    }
    
    // Add method to force center on Rutgers University
    fun centerOnRutgers() {
        println("Centering map on Rutgers University")
        val rutgersCenter = LatLng(40.5017, -74.4474) // Rutgers University center
        _currentLocation.value = rutgersCenter
        println("Map centered on Rutgers: ${rutgersCenter.latitude}, ${rutgersCenter.longitude}")
    }
    
    override fun onCleared() {
        super.onCleared()
        locationCallback?.let { callback ->
            fusedLocationClient.removeLocationUpdates(callback)
        }
        println("GeofenceManager cleared")
    }
    
    companion object {
        private const val NOTIFICATION_CHANNEL_ID = "geofence_notifications"
    }
} 