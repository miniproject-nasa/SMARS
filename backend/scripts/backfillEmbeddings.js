require('dotenv').config();
const mongoose = require('mongoose');
const connectDB = require('../config/db');
const Note = require('../models/Note');
const Task = require('../models/Task');
const { getEmbedding } = require('../utils/huggingface');

(async () => {
  try {
    await connectDB();

    const notes = await Note.find({});
    console.log(`Recomputing embeddings for ${notes.length} notes`);
    for (const note of notes) {
      const text = `${note.title || ''}\n${note.content || ''}`;
      if (!text.trim()) continue;
      const embedding = await getEmbedding(text);
      note.embedding = embedding;
      await note.save();
      console.log(`Updated Note ${note._id}`);
    }

    const tasks = await Task.find({});
    console.log(`Recomputing embeddings for ${tasks.length} tasks`);
    for (const task of tasks) {
      const dateValue = task.date ? new Date(task.date) : null;
      const dateStr = dateValue && !isNaN(dateValue.getTime())
        ? dateValue.toDateString()
        : '';

      const parts = [
        task.title ? `Task title: ${task.title}` : '',
        dateStr ? `Date: ${dateStr}` : '',
        task.category ? `Category: ${task.category}` : '',
        task.recurrence ? `Recurrence: ${task.recurrence}` : ''
      ].filter(Boolean);

      const text = parts.join('. ');
      if (!text.trim()) continue;

      const embedding = await getEmbedding(text);
      task.embedding = embedding;
      await task.save();
      console.log(`Updated Task ${task._id}`);
    }

    console.log('Backfill complete');
    process.exit(0);
  } catch (err) {
    console.error('Backfill error:', err);
    process.exit(1);
  }
})();

