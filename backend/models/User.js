const mongoose = require("mongoose");

const userSchema = new mongoose.Schema(
  {
    username: {
      type: String,
      required: true,
      unique: true,
    },

    password: {
      type: String,
      required: true,
    },

    role: {
      type: String,
      enum: ["patient", "caregiver"],
      required: true,
    },

    // Only for caregivers
    patientUsername: {
      type: String,
      default: null,
    },

    // 🟢 CONSOLIDATED: All patient profile fields now in User (no separate Profile model)
    patientId: {
      type: String,
      unique: true,
      sparse: true,
      default: null,
    },

    // Signup fields
    fullName: { type: String, default: null },
    dateOfBirth: { type: String, default: null },
    mobile: { type: String, default: null },
    address: { type: String, default: null },

    // Extended profile fields (formerly in Profile model)
    aadhar: { type: String, default: "" },
    profilePicUrl: { type: String, default: "" },

    // Auth token
    token: { type: String, default: null, unique: true, sparse: true },
  },
  { timestamps: true },
);

module.exports = mongoose.model("User", userSchema);
