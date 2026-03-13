require('dotenv').config();
const connectDB = require('../config/db');
const Note = require('../models/Note');
const Task = require('../models/Task');
const { syncNoteEmbedding, syncTaskEmbedding } = require('../services/ragService');

(async () => {
  try {
    await connectDB();

    const notes = await Note.find({});
    console.log(`Rebuilding Supabase vectors for ${notes.length} notes`);
    for (const note of notes) {
      await syncNoteEmbedding(note, note.userId);
      console.log(`Synced note ${note._id}`);
    }

    const tasks = await Task.find({});
    console.log(`Rebuilding Supabase vectors for ${tasks.length} tasks`);
    for (const task of tasks) {
      await syncTaskEmbedding(task, task.userId);
      console.log(`Synced task ${task._id}`);
    }

    console.log('Backfill complete');
    process.exit(0);
  } catch (err) {
    console.error('Backfill error:', err);
    process.exit(1);
  }
})();

