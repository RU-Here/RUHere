const admin = require('firebase-admin');
const dotenv = require('dotenv');
dotenv.config();

const serviceAccount = JSON.parse(process.env.FIREBASE_CONFIG); 

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://whereru-43fec.firebaseio.com"
});

const db = admin.firestore();

module.exports = {
  admin,
  db
};