const mongoose = require('mongoose');

const taskSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  title: { type: String, required: true },
  done: { type: Boolean, default: false },
  priority: { type: String, enum: ['Low', 'Normal', 'High'], default: 'Normal' },
  date: { type: Date, required: true }
}, { timestamps: true });

module.exports = mongoose.model('Task', taskSchema);