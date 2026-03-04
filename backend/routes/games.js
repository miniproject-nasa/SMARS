const express = require("express");
const router = express.Router();
const gameController = require("../controllers/gameController");
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

// 🟢 START A NEW GAME SESSION
router.post("/start", gameController.startGameSession);

// 🟢 END GAME SESSION AND SAVE SCORE
router.post("/end", gameController.endGameSession);

// 🟢 GET DAILY GAME TIME REMAINING
router.get("/daily-time", gameController.getDailyGameTime);

// 🟢 GET GAME STATISTICS
router.get("/stats", gameController.getGameStats);

// 🟢 GET HIGH SCORES / LEADERBOARD
router.get("/high-scores", gameController.getHighScores);

module.exports = router;
