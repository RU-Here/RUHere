const express = require('express');
const router = express.Router();
const db = require('../firebase/admin');
const {FieldValue} = require('firebase-admin/firestore'); // FieldValue is not attached to admin, lives in /firestore
const rateLimit = require('express-rate-limit');


// Endpoint: Create group
router.post('/addGroup', async (req, res) => {
  const { name, emoji, admin } = req.body;

  try {
    const docRef = await db.collection('Groups').add({
      name: name,
      emoji: emoji,
      admin: admin
    });

    res.status(200).send({ 
      message: 'Group created.',
      groupId: docRef.id
    });
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

// Endpoint: User added to group
router.post('/addUsertoGroup', async (req, res) => {
  const { groupId, userId } = req.body;

  if (!groupId || !userId) {
    return res.status(400).send({ error: 'groupId and userId are both required' });
  }

  const groupRef = db.collection('Groups').doc(groupId);
  const userRef = db.collection('Users').doc(userId);

  try {
    await groupRef.update({
      people: FieldValue.arrayUnion(userRef)
    });
    
    res.status(200).send({message: `User ${userId} added to group ${groupId}`});
  } catch (error) {
    res.status(500).send({ error: error.message });
  }
});

// Endpoint: User created
router.post('/userSignedIn', async (req, res) => {
  const { userId, name, pfp } = req.body;

  try {
    // Grab user, if it exists, say so
    const user = await db.collection('Users').doc(userId).get();
    if (!!user) {
      // If not, create user
      await db.collection('Users').doc(userId).set({
        areaCode: null,
        name: name,
        pfp: pfp
      });
      res.status(200).send({ message: 'User created.'});
    } else {
      res.status(200).send({ message: 'User signed in.'});
    }

  } catch (error) {
    res.status(500).send({ error: error.message });
  }

});

// Endpoint: User deleted
router.post('/deleteUser', async (req, res) => {
  const { userId }= req.body;

  try {
    db.collection('Users').doc(userId).delete();

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

const joinWaitlistLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 5,              // Limit each IP to 5 requests per window
  message: { error: 'Too many requests, please try again later.' },
  standardHeaders: true, // Send standard rate limit headers
  legacyHeaders: false,  // Disable X-RateLimit-* headers (optional)
});

// Endpoint: Add email to waitlist
router.post('/joinWaitlist', joinWaitlistLimiter, async (req, res) => {
  const { email } = req.body;

  const isValidEmail = (email) => {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  };

  if (!email || !isValidEmail(email)) {
    return res.status(400).send({ error: 'Valid email is required' });
  }

  const normalizedEmail = email.toLowerCase().trim();

  try {
    const existingEmails = await db.collection('Waitlist')
      .where('email', '==', normalizedEmail)
      .get();

    if (!existingEmails.empty) {
      return res.status(409).send({ error: 'Email already registered' });
    }

    const docRef = await db.collection('Waitlist').add({
      email: normalizedEmail,
      timestamp: FieldValue.serverTimestamp(),
      createdAt: new Date().toISOString()
    });

    res.status(201).send({ 
      message: 'Successfully joined waitlist',
      id: docRef.id
    });
  } catch (error) {
    res.status(500).send({ error: error.message });
  }
});

// Endpoint: User enters a geofence
router.post('/enter', async (req, res) => {
  const { userId, areaCode } = req.body;

  try {
    await db.collection('Users').doc(userId).update({ // Update the user's location to this new one
      areaCode: areaCode
    });

    // If there are other users in the area, send notification to user of those people
    // Send notification to people already in the area of the new person

    // 1. Get all groups the userId is part of
    const groupsOfUser = await getAllGroupsByUser(userId, db);
    // 2. Get all friends in those groups
    const friends = data.people;
    // 3. Filter to get all friends where userId location == friend location
    // const usersToNotify = [];
    // friends.forEach(doc => {
    //   usersToNotify.push({userId: doc.id, ...doc.data()});
    // })
    const usersToNotify = groupsOfUser.flatMap(group =>
      group.people.filter(friend => friend.areaCode === areaCode)
    );
    // 4. Call function that send notification to each friend filtered
    for (const friend of usersToNotify) {
      console.log('Notify')
    }
    

    res.status(200).send({ message: 'Entered geofence logged.' });
  } catch (error) {
    res.status(500).send({ error: error.message });
  }
});

// Endpoint: User exits a geofence
router.post('/exit', async (req, res) => {
  const { userId } = req.body;

  try {
    const userRef = await db.collection('Users').doc(userId);
    await userRef.update({areacode: null});
    res.status(200).send({ message: 'Exit geofence logged.' });
  } catch (error) {
    res.status(500).send({ error: error.message });
  }
});

// Endpoint: Get all users
// router.get('/allUsers', async (req, res) => {
//   try {
//     const snapshot = await db.collection('Users').get();

//     const users = [];
//     snapshot.forEach(doc => {
//       users.push({userId: doc.id, ...doc.data()});
//     })
    
//     res.status(200).send(users);
//   } catch (error) {
//     res.status(500).send({error: error.message});
//   }
  
// });

// Endpoint: Get all groups by user
router.get('/allGroups/:userId', async (req, res) => {
  const userId = req.params.userId;

  try {
    const groupData = await getAllGroupsByUser(userId, db)
    console.log(groupData);
    console.log(groupData[0].people[0]);
    
    res.status(200).send(groupData)
  } catch (error) {
    res.status(500).send({ error: error.message });
  }
});

async function getAllGroupsByUser(userId, db) {
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
        return { id: personObject.id, ...personObject.data() }
      })
    );

    groupData.push({ id: doc.id, ...doc.data(), people: peopleData });
  }

  return groupData;
}

// Endpoint: Leave group
router.get('/leaveGroup/:userId/:groupId', async (req, res) => {
  const userId = req.params.userId;
  const groupId = req.params.groupId;

  try {
    const groupRef = await db.collection('Groups').doc(groupId);
    await groupRef.people.update()
  } catch (error) {
    res.status(500).send({ error: error.message });
  }
})

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

// Endpoint: Get group by ID
router.get('/group/:groupId', async (req, res) => {
  const groupId = req.params.groupId;

  try {
    const groupDoc = await db.collection('Groups').doc(groupId).get();
    
    if (!groupDoc.exists) {
      return res.status(404).send({ error: 'Group not found' });
    }

    const groupData = groupDoc.data();
    const personRefs = groupData.people || [];

    const peopleData = await Promise.all(
      personRefs.map(async (ref) => {
        const personObject = await ref.get();
        return { id: personObject.id, ...personObject.data() }
      })
    );
    
    const responseData = {
      id: groupDoc.id,
      ...groupData,
      people: peopleData
    };

    res.status(200).send(responseData);
  } catch (error) {
    res.status(500).send({ error: error.message });
  }
});




module.exports = router;
