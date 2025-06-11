require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path')
const app = express();
const geofenceRoutes = require('./routes/geofence');

app.use(express.urlencoded({ extended: true })); 

app.use(cors());
app.use(express.json());

app.use('/api/geofence', geofenceRoutes);

app.get('/api/geofence/nearby', (req, res) => {
    res.sendFile(path.join(__dirname, './pages/post.html'))
})



const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
