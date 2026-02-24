const mongoose = require('mongoose');

const contactSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  name: { type: String, required: true },
  phone: { type: String, default: "N/A" },
  relation: { type: String },
  isEmergency: { type: Boolean, default: false },
  imageUrl: { type: String, default: null } // 🟢 CHANGED TO URL
}, { timestamps: true });

module.exports = mongoose.model('Contact', contactSchema);