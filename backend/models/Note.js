const mongoose = require('mongoose');

const noteSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  title: { type: String, required: true },
  content: { type: String, required: true },
  imageUrl: { type: String, default: null } // 🟢 NEW: PHOTO UPLOAD FOR NOTES
}, { timestamps: true });

module.exports = mongoose.model('Note', noteSchema);