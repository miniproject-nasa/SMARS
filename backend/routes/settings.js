const express = require("express");
const router = express.Router();
const settingsController = require("../controllers/settingsController");
const User = require("../models/User");

// 🟢 AUTH MIDDLEWARE
const requireAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith("Bearer ")) {
      return res
        .status(401)
        .json({ message: "No authorization token provided" });
    }
    const token = authHeader.split(" ")[1];
    const user = await User.findOne({ token: token });
    if (!user) {
      return res.status(401).json({ message: "Invalid or expired token" });
    }
    req.user = { id: user._id };
    next();
  } catch (error) {
    res
      .status(500)
      .json({ message: "Authentication error", error: error.message });
  }
};

// All routes require authentication
router.use(requireAuth);

// 🟢 GET USER SETTINGS
router.get("/", settingsController.getUserSettings);

// 🟢 UPDATE USER SETTINGS
router.put("/", settingsController.updateUserSettings);

// 🟢 GET USER ACHIEVEMENTS
router.get("/achievements", settingsController.getUserAchievements);

module.exports = router;
