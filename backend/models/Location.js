const mongoose = require('mongoose');

const locationSchema = new mongoose.Schema(
  {
    latitude: Number,
    longitude: Number,
  },
  {
    timestamps: true,
  }
);

module.exports = mongoose.model('Location', locationSchema);