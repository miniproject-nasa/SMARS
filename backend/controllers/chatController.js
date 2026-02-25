const mongoose = require('mongoose');
const Note = require('../models/Note');
const Task = require('../models/Task');
const { getEmbedding, generateAnswer } = require('../utils/huggingface');

const ObjectId = mongoose.Types.ObjectId;

function buildContextFromResults(noteResults, taskResults) {
  const lines = [];

  for (const t of taskResults) {
    const status = t.done ? 'Completed' : 'Pending';
    const dateStr = t.date ? new Date(t.date).toDateString() : '';
    lines.push(`Todo: ${t.title || ''} | Status: ${status} | Date: ${dateStr}`);
  }

  for (const n of noteResults) {
    const createdStr = n.createdAt ? new Date(n.createdAt).toDateString() : '';
    lines.push(`Note: ${n.title || ''} | Date: ${createdStr} | Text: ${n.content || ''}`);
  }

  return lines.join('\n');
}

// Try to extract a specific calendar date from the user's question (e.g. "25-2-2026", "25/02/2026").
function extractDateFromQuestion(question) {
  // Matches dd[-/. ]mm[-/. ]yyyy with 1-2 digit day/month.
  const dateRegex = /(\d{1,2})[\/\-. ](\d{1,2})[\/\-. ](\d{4})/;
  const match = question.match(dateRegex);
  if (!match) return null;

  const day = parseInt(match[1], 10);
  const month = parseInt(match[2], 10) - 1; // JS months are 0-based
  const year = parseInt(match[3], 10);

  const d = new Date(year, month, day);
  if (isNaN(d.getTime())) return null;
  return d;
}

// Try to extract a note title from patterns like:
// - note titled "Shopping"
// - show note "Shopping"
// - content of note "Shopping"
// Falls back to null if no clear title phrase is found.
function extractNoteTitle(question) {
  // First, look for text inside quotes after the word "note"
  const quoted = question.match(/note[^"'"]*["“](.+?)["”]/i);
  if (quoted && quoted[1]) {
    return quoted[1].trim();
  }

  // Next, simple pattern: "note titled X"
  const titled = question.match(/note titled\s+(.+)/i);
  if (titled && titled[1]) {
    return titled[1].trim();
  }

  return null;
}

// Basic intent detection for common structured queries
function detectIntent(question) {
  const q = question.toLowerCase();

  if (/all (my )?tasks|task list|list my tasks/.test(q)) return 'all_tasks';
  if (/pending tasks?|undone|not done/.test(q)) return 'pending_tasks';
  if (/(completed|finished|done) tasks?/.test(q)) return 'completed_tasks';
  if (/all (my )?notes|list notes/.test(q)) return 'all_notes';
  if (extractNoteTitle(question)) return 'note_by_title';

  // If a date is present and the user mentions tasks/todos, treat as date-specific tasks
  if (extractDateFromQuestion(q) && /(task|todo)/.test(q)) return 'tasks_by_date';

  return 'rag_generic';
}

exports.askRagQuestion = async (req, res) => {
  try {
    const { question } = req.body;
    if (!question || !question.trim()) {
      return res.status(400).json({ error: 'Question is required' });
    }

    const userId = new ObjectId(req.user.id);

    const intent = detectIntent(question);
    let notes = [];
    let tasks = [];
    let combined = [];

    if (intent === 'all_tasks') {
      tasks = await Task.find({ userId }).sort({ date: 1 }).lean();
    } else if (intent === 'pending_tasks') {
      tasks = await Task.find({ userId, done: false }).sort({ date: 1 }).lean();
    } else if (intent === 'completed_tasks') {
      tasks = await Task.find({ userId, done: true }).sort({ date: 1 }).lean();
    } else if (intent === 'all_notes') {
      notes = await Note.find({ userId }).sort({ createdAt: -1 }).lean();
    } else if (intent === 'note_by_title') {
      const title = extractNoteTitle(question);
      if (title) {
        // Case-insensitive partial match on title
        const regex = new RegExp(title.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
        notes = await Note.find({ userId, title: regex }).sort({ createdAt: -1 }).lean();
      }
    } else if (intent === 'tasks_by_date') {
      const extractedDate = extractDateFromQuestion(question);
      if (extractedDate) {
        const startOfDay = new Date(extractedDate);
        startOfDay.setHours(0, 0, 0, 0);
        const endOfDay = new Date(extractedDate);
        endOfDay.setHours(23, 59, 59, 999);

        tasks = await Task.find({
          userId,
          date: { $gte: startOfDay, $lte: endOfDay }
        }).sort({ date: 1 }).lean();
      }
    } else {
      // RAG generic flow: semantic search (notes + tasks) + optional date filter
      const questionEmbedding = await getEmbedding(question);

      const noteResults = await Note.aggregate([
        {
          $vectorSearch: {
            index: 'note_embedding_index',
            path: 'embedding',
            queryVector: questionEmbedding,
            numCandidates: 50,
            limit: 5,
            filter: { userId }
          }
        },
        {
          $project: {
            title: 1,
            content: 1,
            createdAt: 1,
            score: { $meta: 'vectorSearchScore' }
          }
        }
      ]);

      const taskResultsFromVector = await Task.aggregate([
        {
          $vectorSearch: {
            index: 'task_embedding_index',
            path: 'embedding',
            queryVector: questionEmbedding,
            numCandidates: 50,
            limit: 5,
            filter: { userId }
          }
        },
        {
          $project: {
            title: 1,
            done: 1,
            date: 1,
            score: { $meta: 'vectorSearchScore' }
          }
        }
      ]);

      let dateFilteredTasks = [];
      const extractedDate = extractDateFromQuestion(question);
      if (extractedDate) {
        const startOfDay = new Date(extractedDate);
        startOfDay.setHours(0, 0, 0, 0);
        const endOfDay = new Date(extractedDate);
        endOfDay.setHours(23, 59, 59, 999);

        dateFilteredTasks = await Task.find({
          userId,
          date: { $gte: startOfDay, $lte: endOfDay }
        }).lean();
      }

      combined = [
        ...noteResults.map(r => ({ type: 'note', ...r })),
        ...taskResultsFromVector.map(r => ({ type: 'task', ...r })),
        ...dateFilteredTasks.map(t => ({ type: 'task', ...t, score: 1.0 }))
      ];

      combined.sort((a, b) => (b.score || 0) - (a.score || 0));

      const topCombined = combined.slice(0, 10);
      notes = topCombined.filter(x => x.type === 'note');
      tasks = topCombined.filter(x => x.type === 'task');
    }

    // When we used direct Mongo queries (non-generic intents), combined is just for debugging.
    if (combined.length === 0 && (notes.length > 0 || tasks.length > 0)) {
      combined = [
        ...notes.map(n => ({ type: 'note', ...n })),
        ...tasks.map(t => ({ type: 'task', ...t }))
      ];
    }

    const contextText = buildContextFromResults(notes, tasks);

    const listPrompt = `
You are an assistant that answers questions based only on the provided context.

The context is a list of Todos and Notes for one user.

- If the context contains any matching Todos or Notes, list them clearly, one per line.
- Each Todo line must include: title, date, and whether it is Pending or Completed.
- If there are no matching items, reply exactly: "You have no matching tasks or notes."
- Do NOT ask the user for more information.
- Do NOT give generic productivity advice.

Context:
${contextText || '(no relevant notes or todos found)'}

Question: ${question}

Now answer based only on the context.
`.trim();

    const ragPrompt = `
You are an assistant that answers questions based only on the provided context.

Context:
${contextText || '(no relevant notes or todos found)'}

Question: ${question}

Answer clearly and accurately based only on the context.
`.trim();

    const promptToUse =
      intent === 'rag_generic' ? ragPrompt : listPrompt;

    const rawAnswer = await generateAnswer(promptToUse);

    res.json({
      answer: rawAnswer,
      context: contextText,
      sources: combined
    });
  } catch (error) {
    console.error('RAG error:', error);
    res.status(500).json({ error: 'Failed to answer question', details: error.message });
  }
};

