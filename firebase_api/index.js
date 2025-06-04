const express = require('express')
const firebase = require('firebase/app')
require('firebase/firestore')
const app = express()
const port = 3000

app.use(express.urlencoded({extended: true}));

// Initialize Firebase
const firebaseConfig = {
  apiKey: "API_KEY",
  authDomain: "AUTH_DOMAIN",
  projectId: "PROJECT_ID",
  storageBucket: "STORAGE_BUCKET",
  messagingSenderId: "MESSAGING_SENDER_ID",
  appId: "APP_ID",
  measurementId: "MEASUREMENT_ID"
};

firebase.initializeApp(firebaseConfig)

app.listen(port, ()=> {
    console.log(`Server running on port ${port}`)
})