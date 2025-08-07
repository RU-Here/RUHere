require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path')
const app = express();
const geofenceRoutes = require('./routes/geofence');
const { admin } = require('./firebase/admin')

const apiKeyMiddleware = (req, res, next) => {
  const idToken = req.headers.authorization;
  
  if (!idToken) {
    return res.status(401).json({ error: 'No authorization token provided' });
  }
  
  admin.auth()
  .verifyIdToken(idToken)
  .then((decodedToken) => {
    const uid = decodedToken.uid;
    console.log('Token verified for user:', uid);
    req.user = decodedToken; 
    next(); 
  })
  .catch((error) => {
    console.error('Token verification failed:', error.message);
    res.status(401).json({ error: 'Invalid or expired token' });
  });
};

app.use(express.urlencoded({ extended: true })); 
app.use(cors());
app.use(express.json());

// Public routes (no authentication required)
const publicRoutes = require('./routes/public');
app.use('/api/public', publicRoutes);

// Apply API key middleware to all routes except public ones
app.use(apiKeyMiddleware);

app.use('/api/geofence', geofenceRoutes);

app.get('/api/geofence/nearby', (req, res) => {
    res.sendFile(path.join(__dirname, './pages/post.html'))
})

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
