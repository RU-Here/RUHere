package com.example.testapp

import com.google.gson.annotations.SerializedName

data class Location(
    val name: String,
    val latitude: Double,
    val longitude: Double,
    val radius: Double,
    @SerializedName("areaCode") val areaCode: String
)

data class LocationData(
    val locations: List<Location>
) 