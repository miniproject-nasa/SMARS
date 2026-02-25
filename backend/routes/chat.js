const express = require('express');
const router = express.Router();
const chatController = require('../controllers/chatController');
const User = require('../models/User');

const requireAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ message: 'No authorization token provided' });
    }
    const token = authHeader.split(' ')[1];
    const user = await User.findOne({ token: token });
    if (!user) {
      return res.status(401).json({ message: 'Invalid or expired token' });
    }
    req.user = { id: user._id };
    next();
  } catch (error) {
    res.status(500).json({ message: 'Authentication error', error: error.message });
  }
};

router.use(requireAuth);

router.post('/rag', chatController.askRagQuestion);

module.exports = router;

