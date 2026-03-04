const mongoose = require("mongoose");

const userAchievementSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    currentStreak: {
      type: Number,
      default: 0, // consecutive days played
    },
    longestStreak: {
      type: Number,
      default: 0,
    },
    totalGamesPlayed: {
      type: Number,
      default: 0,
    },
    totalGamesCompleted: {
      type: Number,
      default: 0,
    },
    achievements: [
      {
        id: String, // e.g., "first_game", "7_day_streak", "100_score"
        name: String, // e.g., "First Steps"
        description: String,
        icon: String,
        unlockedAt: Date,
      },
    ],
    milestones: {
      gamesPlayed_10: { type: Boolean, default: false },
      gamesPlayed_50: { type: Boolean, default: false },
      gamesPlayed_100: { type: Boolean, default: false },
      streak_7days: { type: Boolean, default: false },
      streak_30days: { type: Boolean, default: false },
      highScore_1000: { type: Boolean, default: false },
      perfectGame: { type: Boolean, default: false }, // No mistakes
    },
    lastPlayedDate: Date,
  },
  { timestamps: true },
);

module.exports = mongoose.model("UserAchievement", userAchievementSchema);
