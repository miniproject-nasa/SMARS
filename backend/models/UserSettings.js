const mongoose = require("mongoose");

const userSettingsSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      unique: true,
    },
    dailyGameLimit: {
      type: Number,
      default: 1800000, // 30 minutes in milliseconds
    },
    enableNotifications: {
      type: Boolean,
      default: true,
    },
    difficultySetting: {
      type: String,
      enum: ["easy", "medium", "hard"],
      default: "medium",
    },
  },
  { timestamps: true },
);

module.exports = mongoose.model("UserSettings", userSettingsSchema);
