const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
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
    enum: ['patient', 'caregiver'],
    required: true,
  },

  // Only for caregivers
  patientUsername: {
    type: String,
    default: null,
  },

  // Patient signup fields (from Sign Up page)
  fullName: { type: String, default: null },
  dateOfBirth: { type: String, default: null },
  mobile: { type: String, default: null },
  otp: { type: String, default: null },
});

module.exports = mongoose.model('User', userSchema);
