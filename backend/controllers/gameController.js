const GameSession = require("../models/GameSession");
const UserSettings = require("../models/UserSettings");
const UserAchievement = require("../models/UserAchievement");

// 🟢 GET DAILY GAME LIMIT FROM SETTINGS
const getDailyLimit = async (userId) => {
  let settings = await UserSettings.findOne({ userId });
  if (!settings) {
    settings = new UserSettings({ userId });
    await settings.save();
  }
  return settings.dailyGameLimit; // Already in milliseconds
};

// 🟢 START GAME SESSION
exports.startGameSession = async (req, res) => {
  try {
    const { gameType, difficulty } = req.body;

    if (!gameType) {
      return res.status(400).json({ error: "gameType is required" });
    }

    const gameSession = new GameSession({
      userId: req.user.id,
      gameType,
      difficulty: difficulty || "easy",
    });

    await gameSession.save();

    res.status(201).json({
      sessionId: gameSession._id,
      message: "Game session started",
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// 🟢 END GAME SESSION (SAVE SCORE & UPDATE ACHIEVEMENTS)
exports.endGameSession = async (req, res) => {
  try {
    const { sessionId, score, level, completed, mistakes, duration } = req.body;

    if (!sessionId) {
      return res.status(400).json({ error: "sessionId is required" });
    }

    const gameSession = await GameSession.findByIdAndUpdate(
      sessionId,
      {
        score: score || 0,
        level: level || 1,
        completed: completed || false,
        mistakes: mistakes || 0,
        duration: duration || 0,
      },
      { new: true },
    );

    if (!gameSession) {
      return res.status(404).json({ error: "Game session not found" });
    }

    // 🟢 UPDATE ACHIEVEMENTS & STREAKS
    let achievements = await UserAchievement.findOne({ userId: req.user.id });
    if (!achievements) {
      achievements = new UserAchievement({ userId: req.user.id });
    }

    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);

    // Check if user played yesterday for streak calculation
    const playedToday =
      achievements.lastPlayedDate?.toDateString() === today.toDateString();
    const playedYesterday =
      achievements.lastPlayedDate?.toDateString() === yesterday.toDateString();

    // Update streak
    if (!playedToday) {
      if (playedYesterday) {
        achievements.currentStreak = (achievements.currentStreak || 0) + 1;
      } else {
        achievements.currentStreak = 1;
      }
      achievements.longestStreak = Math.max(
        achievements.longestStreak || 0,
        achievements.currentStreak,
      );
      achievements.lastPlayedDate = new Date();
    }

    // Update counters
    if (!playedToday) {
      achievements.totalGamesPlayed = (achievements.totalGamesPlayed || 0) + 1;
    }
    if (completed) {
      achievements.totalGamesComplayed =
        (achievements.totalGamesCompleted || 0) + 1;
    }

    // 🟢 UNLOCK ACHIEVEMENTS
    const newAchievements = [];

    // First game achievement
    if (
      (achievements.totalGamesPlayed || 0) === 1 &&
      !achievements.achievements.find((a) => a.id === "first_game")
    ) {
      newAchievements.push({
        id: "first_game",
        name: "First Steps",
        description: "Play your first game",
        icon: "🎮",
        unlockedAt: new Date(),
      });
    }

    // Streak achievements
    if (
      achievements.currentStreak === 7 &&
      !achievements.milestones.streak_7days
    ) {
      achievements.milestones.streak_7days = true;
      newAchievements.push({
        id: "streak_7days",
        name: "Week Warrior",
        description: "7 day playing streak",
        icon: "🔥",
        unlockedAt: new Date(),
      });
    }

    if (
      achievements.currentStreak === 30 &&
      !achievements.milestones.streak_30days
    ) {
      achievements.milestones.streak_30days = true;
      newAchievements.push({
        id: "streak_30days",
        name: "Monthly Master",
        description: "30 day playing streak",
        icon: "👑",
        unlockedAt: new Date(),
      });
    }

    // Games played milestones
    if (
      achievements.totalGamesPlayed === 10 &&
      !achievements.milestones.gamesPlayed_10
    ) {
      achievements.milestones.gamesPlayed_10 = true;
      newAchievements.push({
        id: "games_10",
        name: "Getting Started",
        description: "Play 10 games",
        icon: "🚀",
        unlockedAt: new Date(),
      });
    }

    if (
      achievements.totalGamesPlayed === 50 &&
      !achievements.milestones.gamesPlayed_50
    ) {
      achievements.milestones.gamesPlayed_50 = true;
      newAchievements.push({
        id: "games_50",
        name: "Game Fanatic",
        description: "Play 50 games",
        icon: "⭐",
        unlockedAt: new Date(),
      });
    }

    if (
      achievements.totalGamesPlayed === 100 &&
      !achievements.milestones.gamesPlayed_100
    ) {
      achievements.milestones.gamesPlayed_100 = true;
      newAchievements.push({
        id: "games_100",
        name: "Legendary Player",
        description: "Play 100 games",
        icon: "💎",
        unlockedAt: new Date(),
      });
    }

    // Perfect game (no mistakes)
    if (mistakes === 0 && completed && !achievements.milestones.perfectGame) {
      achievements.milestones.perfectGame = true;
      newAchievements.push({
        id: "perfect_game",
        name: "Flawless Victory",
        description: "Complete a game with no mistakes",
        icon: "✨",
        unlockedAt: new Date(),
      });
    }

    // Score milestone
    if (score >= 1000 && !achievements.milestones.highScore_1000) {
      achievements.milestones.highScore_1000 = true;
      newAchievements.push({
        id: "score_1000",
        name: "Score Master",
        description: "Reach 1000 score",
        icon: "🏆",
        unlockedAt: new Date(),
      });
    }

    // Add new achievements
    if (newAchievements.length > 0) {
      achievements.achievements = [
        ...(achievements.achievements || []),
        ...newAchievements,
      ];
    }

    await achievements.save();

    res.json({
      message: "Game session saved",
      session: gameSession,
      achievements: newAchievements,
      streak: achievements.currentStreak,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// 🟢 GET DAILY GAME TIME REMAINING (WITH STREAK & ACHIEVEMENTS)
exports.getDailyGameTime = async (req, res) => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);

    // Get dynamic daily limit
    const dailyLimit = await getDailyLimit(req.user.id);

    // Get all game sessions for today
    const sessions = await GameSession.find({
      userId: req.user.id,
      playedAt: { $gte: today, $lt: tomorrow },
    });

    // Calculate total time spent
    const totalTimeSpent = sessions.reduce(
      (sum, session) => sum + session.duration,
      0,
    );
    const timeRemaining = Math.max(0, dailyLimit - totalTimeSpent);

    // Get user achievements for streak
    let achievements = await UserAchievement.findOne({ userId: req.user.id });
    if (!achievements) {
      achievements = new UserAchievement({ userId: req.user.id });
      await achievements.save();
    }

    res.json({
      dailyLimit,
      totalTimeSpent,
      timeRemaining,
      sessionsCount: sessions.length,
      canPlay: timeRemaining > 0,
      streak: achievements.currentStreak || 0,
      longestStreak: achievements.longestStreak || 0,
      totalGamesPlayed: achievements.totalGamesPlayed || 0,
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// 🟢 GET GAME STATISTICS
exports.getGameStats = async (req, res) => {
  try {
    const { gameType } = req.query;

    let filter = { userId: req.user.id };
    if (gameType) filter.gameType = gameType;

    const stats = await GameSession.find(filter)
      .sort({ createdAt: -1 })
      .limit(100);

    const totalSessions = stats.length;
    const completedSessions = stats.filter((s) => s.completed).length;
    const avgScore =
      stats.length > 0
        ? Math.round(stats.reduce((sum, s) => sum + s.score, 0) / stats.length)
        : 0;
    const avgLevel =
      stats.length > 0
        ? Math.round(stats.reduce((sum, s) => sum + s.level, 0) / stats.length)
        : 0;
    const totalTimeSpent = stats.reduce((sum, s) => sum + s.duration, 0);

    // Group by game type
    const byGameType = {};
    stats.forEach((session) => {
      if (!byGameType[session.gameType]) {
        byGameType[session.gameType] = {
          count: 0,
          avgScore: 0,
          highScore: 0,
          totalTime: 0,
        };
      }
      byGameType[session.gameType].count++;
      byGameType[session.gameType].avgScore += session.score;
      byGameType[session.gameType].highScore = Math.max(
        byGameType[session.gameType].highScore,
        session.score,
      );
      byGameType[session.gameType].totalTime += session.duration;
    });

    // Calculate averages
    Object.keys(byGameType).forEach((gameType) => {
      byGameType[gameType].avgScore = Math.round(
        byGameType[gameType].avgScore / byGameType[gameType].count,
      );
    });

    res.json({
      totalSessions,
      completedSessions,
      completionRate:
        totalSessions > 0
          ? Math.round((completedSessions / totalSessions) * 100)
          : 0,
      avgScore,
      avgLevel,
      totalTimeSpent,
      byGameType,
      recentSessions: stats.slice(0, 10),
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// 🟢 GET HIGH SCORES (LEADERBOARD)
exports.getHighScores = async (req, res) => {
  try {
    const { gameType, limit = 10 } = req.query;

    let matchStage = {};
    if (gameType) matchStage.gameType = gameType;

    const highScores = await GameSession.aggregate([
      { $match: matchStage },
      {
        $group: {
          _id: "$userId",
          highScore: { $max: "$score" },
          avgScore: { $avg: "$score" },
          gamesPlayed: { $sum: 1 },
          lastPlayedAt: { $max: "$playedAt" },
        },
      },
      { $sort: { highScore: -1 } },
      { $limit: parseInt(limit) },
      {
        $lookup: {
          from: "users",
          localField: "_id",
          foreignField: "_id",
          as: "userInfo",
        },
      },
    ]);

    res.json(highScores);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};
