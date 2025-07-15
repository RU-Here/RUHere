package com.example.testapp

import android.app.Application
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material.icons.filled.People
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewmodel.compose.viewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GeofenceView() {
    val context = LocalContext.current
    val geofenceManager = viewModel<GeofenceManager>(
        factory = object : ViewModelProvider.Factory {
            override fun <T : ViewModel> create(modelClass: Class<T>): T {
                @Suppress("UNCHECKED_CAST")
                return GeofenceManager(context.applicationContext as Application) as T
            }
        }
    )
    
    var selectedGroup by remember { mutableStateOf<UserGroup?>(null) }
    
    // Observe permission state and trigger location services when available
    val hasLocationPermission by geofenceManager.hasLocationPermission.collectAsState()
    val currentLocation by geofenceManager.currentLocation.collectAsState()
    
    // Trigger location services when permissions are granted
    LaunchedEffect(Unit) {
        println("GeofenceView LaunchedEffect: Initial permission request")
        geofenceManager.requestLocationPermission()
    }
    
    // Monitor permission changes and refresh services when granted
    LaunchedEffect(hasLocationPermission) {
        println("GeofenceView LaunchedEffect: Permission state changed to $hasLocationPermission")
        if (hasLocationPermission) {
            geofenceManager.refreshLocationServices()
        }
    }
    
    // Force refresh when the view is created to ensure location services are running
    LaunchedEffect(geofenceManager) {
        println("GeofenceView LaunchedEffect: Force refreshing location services")
        geofenceManager.refreshLocationServices()
    }
    
    // Debug current location state
    LaunchedEffect(currentLocation) {
        if (currentLocation != null) {
            println("GeofenceView: Current location updated to ${currentLocation!!.latitude}, ${currentLocation!!.longitude}")
        } else {
            println("GeofenceView: Current location is null")
        }
    }
    
    // Sample groups data - in a real app this would come from a repository or API
    val groups = remember {
        listOf(
            UserGroup(
                id = "1", 
                name = "Abusement Park", 
                people = listOf(
                    Person(id = "1", name = "Dev", areaCode = "CASC"),
                    Person(id = "2", name = "Joshua", areaCode = "LSC"),
                    Person(id = "3", name = "Alan", areaCode = "BSC"),
                    Person(id = "4", name = "Sarah", areaCode = "CASC"),
                    Person(id = "5", name = "Mike", areaCode = "LSC"),
                    Person(id = "6", name = "Emma", areaCode = "BSC")
                ), 
                emoji = "🎢"
            ),
            UserGroup(
                id = "2", 
                name = "Band", 
                people = listOf(
                    Person(id = "7", name = "Ezra", areaCode = "CASC"),
                    Person(id = "8", name = "Alicia", areaCode = "CASC"),
                    Person(id = "9", name = "Hana", areaCode = "LSC")
                ), 
                emoji = "🎵"
            ),
            UserGroup(
                id = "3", 
                name = "RuHere Dev", 
                people = listOf(
                    Person(id = "10", name = "Jash", areaCode = "BSC"),
                    Person(id = "11", name = "Matt", areaCode = "CASC"),
                    Person(id = "12", name = "Adi", areaCode = "LSC")
                ), 
                emoji = "💻"
            )
        )
    }
    
    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(Color(0xFFF5F5F5))
    ) {
        // Top App Bar
        TopAppBar(
            title = {
                Text(
                    text = "RUHere",
                    style = MaterialTheme.typography.headlineMedium.copy(
                        fontWeight = FontWeight.Bold
                    )
                )
            },
            colors = TopAppBarDefaults.topAppBarColors(
                containerColor = MaterialTheme.colorScheme.primary,
                titleContentColor = MaterialTheme.colorScheme.onPrimary
            )
        )
        
        // Status Card
        GeofenceInfoCard(
            geofenceManager = geofenceManager,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
        )
        
        // Debug buttons
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Button(
                onClick = { geofenceManager.forceStartLocationUpdates() },
                modifier = Modifier.weight(1f).padding(end = 4.dp)
            ) {
                Text("Start Location")
            }
            
            Button(
                onClick = { geofenceManager.setMockLocation() },
                modifier = Modifier.weight(1f).padding(horizontal = 4.dp)
            ) {
                Text("Mock Location")
            }
            
            Button(
                onClick = { geofenceManager.loadGeofences() },
                modifier = Modifier.weight(1f).padding(start = 4.dp)
            ) {
                Text("Load Geofences")
            }
        }
        
        // Additional debug buttons
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp),
            horizontalArrangement = Arrangement.Center
        ) {
            Button(
                onClick = { geofenceManager.centerOnRutgers() },
                modifier = Modifier.padding(horizontal = 8.dp)
            ) {
                Text("Center on Rutgers")
            }
        }
        
        // Group Selection
        GroupSelectionRow(
            groups = groups,
            selectedGroup = selectedGroup,
            onGroupSelected = { selectedGroup = it },
            modifier = Modifier.padding(vertical = 8.dp)
        )
        
        // Map View
        Card(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp),
            shape = RoundedCornerShape(16.dp),
            elevation = CardDefaults.cardElevation(defaultElevation = 8.dp)
        ) {
            GeofenceMapView(
                geofenceManager = geofenceManager,
                selectedGroup = selectedGroup,
                modifier = Modifier.fillMaxSize()
            )
        }
    }
}

@Composable
fun GroupSelectionRow(
    groups: List<UserGroup>,
    selectedGroup: UserGroup?,
    onGroupSelected: (UserGroup?) -> Unit,
    modifier: Modifier = Modifier
) {
    Column(modifier = modifier) {
        Text(
            text = "Select a Group",
            style = MaterialTheme.typography.titleMedium,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
            color = MaterialTheme.colorScheme.onBackground
        )
        
        LazyRow(
            modifier = Modifier.fillMaxWidth(),
            contentPadding = PaddingValues(horizontal = 16.dp),
            horizontalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Add "Clear Selection" option
            item {
                GroupCard(
                    group = null,
                    isSelected = selectedGroup == null,
                    onClick = { onGroupSelected(null) }
                )
            }
            
            items(groups) { group ->
                GroupCard(
                    group = group,
                    isSelected = selectedGroup?.id == group.id,
                    onClick = { onGroupSelected(group) }
                )
            }
        }
    }
}

@Composable
fun GroupCard(
    group: UserGroup?,
    isSelected: Boolean,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val backgroundColor = if (isSelected) {
        MaterialTheme.colorScheme.primary
    } else {
        MaterialTheme.colorScheme.surface
    }
    
    val textColor = if (isSelected) {
        MaterialTheme.colorScheme.onPrimary
    } else {
        MaterialTheme.colorScheme.onSurface
    }
    
    Card(
        modifier = modifier
            .size(120.dp)
            .clickable { onClick() },
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = backgroundColor),
        elevation = CardDefaults.cardElevation(
            defaultElevation = if (isSelected) 8.dp else 4.dp
        )
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            if (group == null) {
                Icon(
                    imageVector = Icons.Default.LocationOn,
                    contentDescription = "All Locations",
                    tint = textColor,
                    modifier = Modifier.size(32.dp)
                )
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "All Locations",
                    style = MaterialTheme.typography.bodySmall,
                    color = textColor,
                    textAlign = TextAlign.Center,
                    fontSize = 12.sp
                )
            } else {
                Text(
                    text = group.emoji,
                    fontSize = 32.sp,
                    modifier = Modifier.height(40.dp)
                )
                
                Spacer(modifier = Modifier.height(4.dp))
                
                Text(
                    text = group.name,
                    style = MaterialTheme.typography.bodySmall,
                    color = textColor,
                    textAlign = TextAlign.Center,
                    fontSize = 12.sp,
                    fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                )
                
                Spacer(modifier = Modifier.height(2.dp))
                
                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        imageVector = Icons.Default.People,
                        contentDescription = "People count",
                        tint = textColor,
                        modifier = Modifier.size(12.dp)
                    )
                    Spacer(modifier = Modifier.width(2.dp))
                    Text(
                        text = "${group.people.size}",
                        style = MaterialTheme.typography.bodySmall,
                        color = textColor,
                        fontSize = 10.sp
                    )
                }
            }
        }
    }
}

@Composable
fun PersonDetailCard(
    people: List<Person>,
    areaName: String,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .padding(8.dp),
        elevation = CardDefaults.cardElevation(defaultElevation = 4.dp)
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = "People in $areaName",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            people.forEach { person ->
                Text(
                    text = "• ${person.name}",
                    style = MaterialTheme.typography.bodyMedium,
                    modifier = Modifier.padding(vertical = 2.dp)
                )
            }
        }
    }
}