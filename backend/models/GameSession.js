const mongoose = require("mongoose");

const gameSessionSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    gameType: {
      type: String,
      enum: ["sequence", "match", "digit_span"],
      required: true,
    },
    score: {
      type: Number,
      default: 0,
    },
    level: {
      type: Number,
      default: 1,
    },
    difficulty: {
      type: String,
      enum: ["easy", "medium", "hard"],
      default: "easy",
    },
    duration: {
      type: Number, // in milliseconds
      default: 0,
    },
    completed: {
      type: Boolean,
      default: false,
    },
    mistakes: {
      type: Number,
      default: 0,
    },
    playedAt: {
      type: Date,
      default: Date.now,
    },
  },
  { timestamps: true },
);

// Add index for daily game time calculation
gameSessionSchema.index({ userId: 1, playedAt: 1 });

module.exports = mongoose.model("GameSession", gameSessionSchema);
