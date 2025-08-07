const express = require('express');
const router = express.Router();
const { db } = require('../firebase/admin');
const rateLimit = require('express-rate-limit');

const getGroupPublicLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 20,             // Allow 20 requests per minute per IP
  message: { error: 'Too many requests, please try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
});

// Endpoint: Get public group info (for web deep links - no auth required)
router.post('/getGroup', getGroupPublicLimiter, async (req, res) => {
  const { groupId } = req.body;

  if (!groupId) {
    return res.status(400).send({ error: 'groupId is required' });
  }

  try {
    const groupDoc = await db.collection('Groups').doc(groupId).get();
    
    if (!groupDoc.exists) {
      return res.status(404).send({ error: 'Group not found' });
    }

    const groupData = groupDoc.data();
    
    const publicGroupInfo = {
      name: groupData.name,
      emoji: groupData.emoji,
      admin: groupData.admin
    };

    res.status(200).send({ group: publicGroupInfo });
  } catch (error) {
    res.status(500).send({ error: error.message });
  }
});

module.exports = router;
