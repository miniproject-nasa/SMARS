const mongoose = require('mongoose');

const sosSchema = new mongoose.Schema({
  patientId: String,
  timestamp: {
    type: Date,
    default: Date.now,
  },
  active: Boolean,
});

module.exports = mongoose.model('SOS', sosSchema);
