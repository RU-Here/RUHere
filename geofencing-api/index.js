require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path')
const app = express();
const geofenceRoutes = require('./routes/geofence');

const apiKeyMiddleware = (req, res, next) => {
  const apiKey = req.headers['x-api-key'] || req.headers['authorization'];
  
  if (!apiKey) {
    return res.status(401).json({ 
      error: 'API key required',
      message: 'Please provide an API key in the x-api-key header or Authorization header'
    });
  }
  
  const expectedApiKey = process.env.API_KEY_SECRET;
  
  if (apiKey !== expectedApiKey) {
    return res.status(403).json({ 
      error: 'Invalid API key',
      message: 'The provided API key is invalid'
    });
  }
  
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
