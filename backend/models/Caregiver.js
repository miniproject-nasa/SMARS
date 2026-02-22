const mongoose = require('mongoose');

const caregiverSchema = new mongoose.Schema(
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
    dateOfBirth: {
      type: String,
      required: true,
    },
    mobile: {
      type: String,
      required: true,
    },
    patientUsername: {
      type: String,
      required: true,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Caregiver', caregiverSchema);
