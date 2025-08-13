const express = require('express');
const router = express.Router();
const { db } = require('../firebase/admin');
const {FieldValue} = require('firebase-admin/firestore'); // FieldValue is not attached to admin, lives in /firestore


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

// Endpoint: Remove user from group (admin only)
router.post('/removeUserFromGroup', async (req, res) => {
  const { groupId, userId, requesterId } = req.body;

  if (!groupId || !userId || !requesterId) {
    return res.status(400).send({ error: 'groupId, userId, and requesterId are required' });
  }

  try {
    const groupRef = db.collection('Groups').doc(groupId);
    const groupDoc = await groupRef.get();
    if (!groupDoc.exists) {
      return res.status(404).send({ error: 'Group not found' });
    }

    const groupData = groupDoc.data();
    if (!groupData || groupData.admin !== requesterId) {
      return res.status(403).send({ error: 'Only the group admin can remove members' });
    }

    const userRef = db.collection('Users').doc(userId);
    await groupRef.update({
      people: FieldValue.arrayRemove(userRef)
    });

    return res.status(200).send({ message: `User ${userId} removed from group ${groupId}` });
  } catch (error) {
    return res.status(500).send({ error: error.message });
  }
});

// Endpoint: Update group info (admin only)
router.post('/updateGroupInfo', async (req, res) => {
  const { groupId, name, emoji, requesterId } = req.body;

  if (!groupId || !requesterId) {
    return res.status(400).send({ error: 'groupId and requesterId are required' });
  }

  try {
    const groupRef = db.collection('Groups').doc(groupId);
    const groupDoc = await groupRef.get();
    if (!groupDoc.exists) {
      return res.status(404).send({ error: 'Group not found' });
    }

    const groupData = groupDoc.data();
    if (!groupData || groupData.admin !== requesterId) {
      return res.status(403).send({ error: 'Only the group admin can update group info' });
    }

    const update = {};
    if (typeof name === 'string') update.name = name;
    if (typeof emoji === 'string') update.emoji = emoji;

    if (Object.keys(update).length === 0) {
      return res.status(400).send({ error: 'No valid fields to update' });
    }

    await groupRef.update(update);
    return res.status(200).send({ message: 'Group updated.' });
  } catch (error) {
    return res.status(500).send({ error: error.message });
  }
});

// Endpoint: Transfer admin (admin only)
router.post('/transferAdmin', async (req, res) => {
  const { groupId, newAdminId, requesterId } = req.body;

  if (!groupId || !newAdminId || !requesterId) {
    return res.status(400).send({ error: 'groupId, newAdminId, and requesterId are required' });
  }

  try {
    const groupRef = db.collection('Groups').doc(groupId);
    const groupDoc = await groupRef.get();
    if (!groupDoc.exists) {
      return res.status(404).send({ error: 'Group not found' });
    }

    const groupData = groupDoc.data();
    if (!groupData || groupData.admin !== requesterId) {
      return res.status(403).send({ error: 'Only the current admin can transfer admin role' });
    }

    await groupRef.update({ admin: newAdminId });
    return res.status(200).send({ message: 'Admin transferred.' });
  } catch (error) {
    return res.status(500).send({ error: error.message });
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

    for (const doc in groupsOfUser) {
      const peopleData = await getAllPeopleinGroup(doc, db);

    }

    // 3. Filter to get all friends where userId location == friend location
    const allFriends = groupsOfUser.flatMap(group =>
      group.people.filter(friend => friend.areaCode === areaCode && friend.id != userId)
    );
    // Exclude counting duplicates of friends that are in multiple groups
    const uniqueFriends = Array.from(
      new Map(allFriends.map(friend => [friend.id, friend])).values()
    );
    // 5. Call function that send notification to each friend filtered
    for (const friend of uniqueFriends) {
      console.log(`Notify ${friend.name}`);
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
    
    res.status(200).send(groupData)
  } catch (error) {
    res.status(500).send({ error: error.message });
  }
});

async function getAllGroupsByUser(userId, db) {
  const userRef = db.collection('Users').doc(userId);

  const groups = await db.collection('Groups')
    .where('people', 'array-contains', userRef)
    .select("name", "emoji", "admin")
    .get();
  
  const groupData = [];

  groups.forEach(doc => {
    groupData.push({ id: doc.id, ...doc.data() });
  });

  // for (const doc of groups.docs) {
  //   const groupObjects = doc.data();
  //   const personRefs = groupObjects.people || [];

  //   const peopleData = await Promise.all(
  //     personRefs.map(async (ref) => {
  //       const personObject = await ref.get();
  //       return { id: personObject.id, ...personObject.data() }
  //     })
  //   );

  //   groupData.push({ id: doc.id, ...doc.data(), people: peopleData });
  // }

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

// Get all people by a group
router.get('/getPeople/:groupId', async (req, res) => {
  const groupId = req.params.groupId
  
  try {
    const peopleData = await getAllPeopleinGroup(groupId, db)
    res.status(200).send(peopleData)
  } catch (error) {
    res.status(500).send({error: error.message});
  }
});

async function getAllPeopleinGroup(groupId, db) {
  const groupRef = await db.collection('Groups').doc(groupId).get();

  if (!groupRef.exists) {
      return res.status(404).send({ error: 'Group not found' });
  }

  const personRefs = groupRef.data().people || [];
  
  const peopleData = await Promise.all(
      personRefs.map(async (ref) => {
        const personObject = await ref.get();
        return { id: personObject.id, ...personObject.data() }
      })
    );
  
  return peopleData;
}




module.exports = router;
