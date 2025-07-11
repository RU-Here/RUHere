const express = require('express');
const router = express.Router();
const db = require('../firebase/admin');

// Endpoint: Create group
router.post('/addGroup', async (req, res) => {
  const { groupId, name, people } = req.body;

  try {
    await db.collection('Groups').doc(groupId).set({
      name,
      people
    });

    res.status(200).send({ message: 'Group created.'});
  } catch (error) {
    res.status(500).send({ error: error.message });
  }

});

// Endpoint: Group deleted
router.post('/deleteGroup', async (req, res) => {
  const { groupId } = req.body;

  try {
    await db.collection('Groups').doc(groupId).delete();
    res.status(200).send({ message: 'Group deleted.' });
  } catch (error) {
    res.status(500).send({ error: error.message });
  }
});

// Endpoint: User created
router.post('/addUser', async (req, res) => {
  const { areacode, name } = req.body;

  try {
    await db.collection('Users').add({
      areacode: areacode,
      name: name
    });

    res.status(200).send({ message: 'User created.'});
  } catch (error) {
    res.status(500).send({ error: error.message });
  }

});

// Endpoint: User deleted
router.post('/deleteUser/:name', async (req, res) => {
  const name = req.params.name;

  try {
    const snapshot = await db.collection('Users')
      .where('name', '==', name)
      .get();

    const users = [];
    snapshot.forEach(doc => {
      users.push({ userId: doc.id, ...doc.data() });
      db.collection('Users').doc(doc.id).delete();
    });


    res.status(200).send({message: 'User deleted'});
  } catch (error) {
    res.status(500).send({ error: error.message });
  }

});

// Endpoint: Updating a User's name field
router.post('/changeName', async (req, res) => {
  const { userId, newName } = req.body;
  try {
    const update = await db.collection('Users').doc(userId).update({name: newName});

    res.status(200).send({ message: 'Name changed.' });
  } catch (error) {
    res.status(500).send({ error: error.message });
  }
});

// Endpoint: User enters a geofence
router.post('/enter', async (req, res) => {
  const { userId, locationId, coordinates } = req.body;

  try {
    await db.collection('user_locations').doc(userId).set({
      locationId,
      coordinates,
      timestamp: Date.now()
    });

    // If there are other users in the area, send notification to user of those people
    // Send notification to people already in the area of the new person

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
    const snapshot = await db.collection('Users')
      .where('areacode', '==', locationId)
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

// Endpoint: Get all users
router.get('/allUsers', async (req, res) => {
  try {
    const snapshot = await db.collection('Users').get();

    const users = [];
    snapshot.forEach(doc => {
      users.push({userId: doc.id, ...doc.data()});
    })
    
    res.status(200).send(users);
  } catch (error) {
    res.status(500).send({error: error.message});
  }
  
});

// Endpoint: Get all groups by user
router.get('/allGroups/:userId', async (req, res) => {
  const userId = req.params.userId;

  try {
    const userRef = db.collection('Users').doc(userId);

    const groups = await db.collection('Groups')
      .where('people', 'array-contains', userRef)
      .get();
    
    const groupData = [];
    for (const doc of groups.docs) {
      const groupObjects = doc.data();
      const personRefs = groupObjects.people || [];

      const peopleData = await Promise.all(
        personRefs.map(async (ref) => {
          const personObject = await ref.get();
            return { personId: personObject.id, ...personObject.data() }
        })
      )
      
      groupData.push({ groupId: doc.id, ...doc.data(), people: peopleData });

    }
    console.log(groupData);
    console.log(groupData[0].people[0]);
    
    res.status(200).send(groupData)
  } catch (error) {
    res.status(500).send({ error: error.message });
  }
});

// Endpoint: Get all groups
// router.get('/allGroups', async (req, res) => {
//   const groups = await db.collection('Groups').get();

//   try {
//     const groupData = [];
//     for (const doc of groups.docs) {
//       const groupObjects = doc.data();
//       const personRefs = groupObjects.people || [];

//       const peopleData = await Promise.all(
//         personRefs.map(async (ref) => {
//           const personObject = await ref.get();
//             return { personId: personObject.id, ...personObject.data() }
//         })
//       )
//       groupData.push({ groupId: doc.id, ...doc.data(), people: peopleData });

//     }
//     console.log(groupData);
//     console.log(groupData[0].people[0]);
    
//     res.status(200).send(groupData)
//   } catch (error) {
//     res.status(500).send({ error: error.message });
//   }
// });


module.exports = router;
