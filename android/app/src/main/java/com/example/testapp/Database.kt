package com.example.testapp

import com.google.firebase.Firebase
import com.google.firebase.firestore.firestore

class Database {
    private val db = Firebase.firestore
    private val groups = db.collection("Groups")
    private val users = db.collection("Users")

    fun getUser(userName: String){
        val allUsers = users.get()
        var user = null
        allUsers.addOnSuccessListener { result ->
            for (document in result) {
                println(document)
            }
        }
    }

    fun printAllUsers(){
        println("all users")
        users.get()
            .addOnSuccessListener { result ->
                for (document in result) {
                    println(document.id)
                }
            }
    }
}