const admin = require('firebase-admin');
const serviceAccount = require('./privateServiceAccountKey.json'); 

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://whereru-43fec.firebaseio.com"
});

const db = admin.firestore();
module.exports = db;
