const mongoose = require("mongoose");

const profileSchema = new mongoose.Schema(
  {
    userId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
      unique: true,
    },
    patientId: { type: String, default: "" }, // 🟢 ADDED: Store patient ID for reference
    name: { type: String, default: "Patient Name" },
    mobile: { type: String, default: "" },
    dob: { type: String, default: "" },
    aadhar: { type: String, default: "" },
    address: { type: String, default: "" },
    profilePicUrl: { type: String, default: "" }, // 🟢 ADDED: Profile picture URL from Cloudinary
  },
  { timestamps: true },
);

module.exports = mongoose.model("Profile", profileSchema);
