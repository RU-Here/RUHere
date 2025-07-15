package com.example.testapp

data class Person(
    val id: String,
    val name: String,
    val areaCode: String
)

data class UserGroup(
    val id: String,
    val name: String,
    val people: List<Person>,
    val emoji: String
) 