require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path')
const app = express();
const geofenceRoutes = require('./routes/geofence');
const admin = require('firebase-admin')

const apiKeyMiddleware = (req, res, next) => {
  const idToken = req.headers.authorization;
  if (!idToken) {
    return res.status(401).send('Unauthorized: Missing token');
  }

  admin.auth()
  .verifyIdToken(idToken)
  .then((decodedToken) => {
    const uid = decodedToken.uid;
    next();
  })
  .catch((error) => {
    // Handle error
    res.status(401).send('Unauthorized')
  });
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
