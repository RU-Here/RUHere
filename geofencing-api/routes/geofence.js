const express = require('express');
const router = express.Router();
const db = require('../firebase/admin');

// Endpoint: User enters a geofence
router.post('/enter', async (req, res) => {
  const { userId, locationId, coordinates } = req.body;

  try {
    await db.collection('user_locations').doc(userId).set({
      locationId,
      coordinates,
      timestamp: Date.now()
    });

    res.status(200).send({ message: 'Entered geofence logged.' });
  } catch (error) {
    res.status(500).send({ error: error.message });
  }
});

// Endpoint: User exits a geofence
router.post('/exit', async (req, res) => {
  const { userId } = req.body;

  try {
    await db.collection('user_locations').doc(userId).delete();
    res.status(200).send({ message: 'Exit geofence logged.' });
  } catch (error) {
    res.status(500).send({ error: error.message });
  }
});

// Endpoint: Get users in a location
router.get('/nearby/:locationId', async (req, res) => {
  const locationId = req.params.locationId;

  try {
    const snapshot = await db.collection('user_locations')
      .where('locationId', '==', locationId)
      .get();

    const users = [];
    snapshot.forEach(doc => {
      users.push({ userId: doc.id, ...doc.data() });
    });

    res.status(200).send(users);
  } catch (error) {
    res.status(500).send({ error: error.message });
  }
});

module.exports = router;
