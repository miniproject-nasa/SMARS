const UserSettings = require("../models/UserSettings");
const UserAchievement = require("../models/UserAchievement");

// 🟢 GET USER SETTINGS
exports.getUserSettings = async (req, res) => {
  try {
    let settings = await UserSettings.findOne({ userId: req.user.id });
    if (!settings) {
      settings = new UserSettings({ userId: req.user.id });
      await settings.save();
    }
    res.json(settings);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// 🟢 UPDATE USER SETTINGS
exports.updateUserSettings = async (req, res) => {
  try {
    const { dailyGameLimit, enableNotifications, difficultySetting } = req.body;

    let settings = await UserSettings.findOne({ userId: req.user.id });
    if (!settings) {
      settings = new UserSettings({ userId: req.user.id });
    }

    if (dailyGameLimit) {
      // Validate: between 5 and 480 minutes in milliseconds
      // 5 min = 300000ms, 480 min = 28800000ms
      const minMs = 5 * 60 * 1000; // 5 minutes
      const maxMs = 480 * 60 * 1000; // 480 minutes (8 hours)

      if (dailyGameLimit < minMs || dailyGameLimit > maxMs) {
        return res.status(400).json({
          error: "Daily limit must be between 5 and 480 minutes",
        });
      }
      settings.dailyGameLimit = dailyGameLimit;
    }

    if (enableNotifications !== undefined) {
      settings.enableNotifications = enableNotifications;
    }

    if (difficultySetting) {
      settings.difficultySetting = difficultySetting;
    }

    await settings.save();
    res.json({ message: "Settings updated", settings });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// 🟢 GET USER ACHIEVEMENTS
exports.getUserAchievements = async (req, res) => {
  try {
    let achievements = await UserAchievement.findOne({ userId: req.user.id });
    if (!achievements) {
      achievements = new UserAchievement({ userId: req.user.id });
      await achievements.save();
    }

    res.json({
      currentStreak: achievements.currentStreak || 0,
      longestStreak: achievements.longestStreak || 0,
      totalGamesPlayed: achievements.totalGamesPlayed || 0,
      totalGamesCompleted: achievements.totalGamesCompleted || 0,
      achievements: achievements.achievements || [],
      milestones: achievements.milestones || {},
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
