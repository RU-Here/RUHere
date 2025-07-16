package com.example.testapp

import android.content.ContentValues.TAG
import android.util.Log
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
                    Log.d(TAG, "${document.id} => ${document.data}")
                }
            }
    }

    fun addUser(userName: String, userArea: String){
        val userInfo = hashMapOf(
            "name" to userName,
            "areacode" to userArea
        )

        users.add(userInfo)
            .addOnSuccessListener { documentRef ->
                Log.d(TAG, "DocumentSnapshot added with ID: ${documentRef.id}")
            }
            .addOnFailureListener { e ->
                Log.w(TAG, "Error adding document", e)
            }
    }
}