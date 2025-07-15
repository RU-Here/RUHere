package com.example.testapp

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import com.google.android.gms.location.Geofence
import com.google.android.gms.location.GeofenceStatusCodes
import com.google.android.gms.location.GeofencingEvent

class GeofenceBroadcastReceiver : BroadcastReceiver() {
    
    override fun onReceive(context: Context, intent: Intent) {
        val geofencingEvent = GeofencingEvent.fromIntent(intent)
        
        if (geofencingEvent == null || geofencingEvent.hasError()) {
            val errorMessage = GeofenceStatusCodes.getStatusCodeString(geofencingEvent?.errorCode ?: 0)
            println("Geofence error: $errorMessage")
            return
        }
        
        val geofenceTransition = geofencingEvent.geofenceTransition
        
        if (geofenceTransition == Geofence.GEOFENCE_TRANSITION_ENTER ||
            geofenceTransition == Geofence.GEOFENCE_TRANSITION_EXIT) {
            
            val triggeringGeofences = geofencingEvent.triggeringGeofences
            
            triggeringGeofences?.forEach { geofence ->
                println("Geofence transition: ${geofence.requestId}, type: $geofenceTransition")
                
                // Here you would typically notify your GeofenceManager
                // For now, we'll handle this via the static callback or shared preferences
                // In a real app, you might use a service or broadcast to the main app
                
                // Store the transition in shared preferences or send a local broadcast
                val sharedPref = context.getSharedPreferences("geofence_prefs", Context.MODE_PRIVATE)
                with(sharedPref.edit()) {
                    putString("last_geofence_id", geofence.requestId)
                    putInt("last_transition_type", geofenceTransition)
                    putLong("last_transition_time", System.currentTimeMillis())
                    apply()
                }
                
                // Send a local broadcast that the app can listen to
                val localBroadcast = Intent("GEOFENCE_TRANSITION")
                localBroadcast.putExtra("geofence_id", geofence.requestId)
                localBroadcast.putExtra("transition_type", geofenceTransition)
                context.sendBroadcast(localBroadcast)
            }
        } else {
            println("Invalid geofence transition type: $geofenceTransition")
        }
    }
} 