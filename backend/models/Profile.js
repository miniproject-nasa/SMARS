const mongoose = require('mongoose');

const profileSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true, unique: true },
  mobile: { type: String, default: "" },
  dob: { type: String, default: "" },
  aadhar: { type: String, default: "" },
  address: { type: String, default: "" }
}, { timestamps: true });

module.exports = mongoose.model('Profile', profileSchema);