const admin = require('firebase-admin');
const dotenv = require('dotenv');
dotenv.config();
const serviceKey = process.env.SERVICE_ACCOUNT;

const serviceAccount = require(`./${serviceKey}.json`); 

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://whereru-43fec.firebaseio.com"
});

const db = admin.firestore();
module.exports = db;
