require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path')
const app = express();
const geofenceRoutes = require('./routes/geofence');
const getAuth = require('firebase-admin/auth')

const apiKeyMiddleware = (req, res, next) => {
  const idToken = req.headers.authorization;
  getAuth()
  .verifyIdToken(idToken)
  .then((decodedToken) => {
    const uid = decodedToken.uid;
    // ...
  })
  .catch((error) => {
    // Handle error
    res.status(401).send('Unauthorized')
  });
  
  next();
};

app.use(express.urlencoded({ extended: true })); 
app.use(cors());
app.use(express.json());

// Apply API key middleware to all routes
app.use(apiKeyMiddleware);

app.use('/api/geofence', geofenceRoutes);

app.get('/api/geofence/nearby', (req, res) => {
    res.sendFile(path.join(__dirname, './pages/post.html'))
})

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
