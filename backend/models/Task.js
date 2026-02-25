const mongoose = require('mongoose');

const taskSchema = new mongoose.Schema({
  userId: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  title: { type: String, required: true },
  done: { type: Boolean, default: false },
  priority: { type: String, enum: ['Low', 'Normal', 'High'], default: 'Normal' },
  date: { type: Date, required: true },
  // 🟢 NEW: ADVANCED TASK FIELDS
  recurrence: { type: String, enum: ['None', 'Daily', 'Weekly', 'Monthly'], default: 'None' },
  category: { type: String, enum: ['General', 'Medication', 'Appointment', 'Exercise'], default: 'General' },
  // Vector embedding for RAG (BAAI/bge-small-en-v1.5)
  embedding: {
    type: [Number],
    default: null
  }
}, { timestamps: true });

module.exports = mongoose.model('Task', taskSchema);