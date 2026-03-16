const mongoose = require('mongoose');
const Note = require('../models/Note');
const Task = require('../models/Task');
const User = require('../models/User');
const { getEmbedding, generateAnswer } = require('../utils/huggingface');

const ObjectId = mongoose.Types.ObjectId;

function buildContextFromResults(noteResults, taskResults, userData = null) {
  const lines = [];

  // Include user profile info
  if (userData) {
    if (userData.fullName) lines.push(`Patient Name: ${userData.fullName}`);
    if (userData.dateOfBirth) lines.push(`Date of Birth: ${userData.dateOfBirth}`);
    if (userData.mobile) lines.push(`Mobile: ${userData.mobile}`);
    if (userData.address) lines.push(`Address: ${userData.address}`);
    if (userData.aadhar) lines.push(`Aadhar: ${userData.aadhar}`);
    if (userData.patientId) lines.push(`Patient ID: ${userData.patientId}`);
    if (lines.length > 0) lines.push('---');
  }

  for (const t of taskResults) {
    const status = t.done ? 'Completed' : 'Pending';
    const dateStr = t.date ? new Date(t.date).toDateString() : 'No date';
    lines.push(`Todo: ${t.title || '(No title)'} | Status: ${status} | Date: ${dateStr}`);
  }

  for (const n of noteResults) {
    const createdStr = n.createdAt ? new Date(n.createdAt).toDateString() : 'No date';
    const content = (n.content || '').substring(0, 100);
    lines.push(`Note: ${n.title || '(No title)'} | Date: ${createdStr} | Content: ${content}${content.length === 100 ? '...' : ''}`);
  }

  return lines.join('\n');
}

// 🟢 IMPROVED: Extract date from multiple formats and relative dates
function extractDateFromQuestion(question) {
  if (!question) return null;
  
  const q = question.toLowerCase();
  
  // 🟢 NEW: Handle relative date words
  const today = new Date();
  today.setHours(0, 0, 0, 0);
  
  // Today
  if (/\btoday\b|\btonight\b/.test(q)) {
    return new Date(today);
  }
  
  // Tomorrow
  if (/\btomorrow\b|\btommorow\b/.test(q)) {
    const tomorrow = new Date(today);
    tomorrow.setDate(tomorrow.getDate() + 1);
    return tomorrow;
  }
  
  // Yesterday
  if (/\byesterday\b/.test(q)) {
    const yesterday = new Date(today);
    yesterday.setDate(yesterday.getDate() - 1);
    return yesterday;
  }
  
  // Next week (interpret as 7 days from now)
  if (/\bnext\s+week\b/.test(q)) {
    const nextWeek = new Date(today);
    nextWeek.setDate(nextWeek.getDate() + 7);
    return nextWeek;
  }
  
  // Last week (interpret as 7 days ago)
  if (/\blast\s+week\b/.test(q)) {
    const lastWeek = new Date(today);
    lastWeek.setDate(lastWeek.getDate() - 7);
    return lastWeek;
  }
  
  // This week (interpret as today)
  if (/\bthis\s+week\b/.test(q)) {
    return new Date(today);
  }
  
  // Tomorrow's date variant
  if (/\bnext\s+day\b/.test(q)) {
    const nextDay = new Date(today);
    nextDay.setDate(nextDay.getDate() + 1);
    return nextDay;
  }
  
  // Explicit date format: dd-mm-yyyy, dd/mm/yyyy, dd.mm.yyyy, dd mm yyyy
  const dateRegex = /(\d{1,2})[\/\-\.\s](\d{1,2})[\/\-\.\s](\d{4})/;
  const match = question.match(dateRegex);
  if (match) {
    const day = parseInt(match[1], 10);
    const month = parseInt(match[2], 10) - 1;
    const year = parseInt(match[3], 10);

    // Validate the date
    const d = new Date(year, month, day, 0, 0, 0, 0);
    if (d.getFullYear() !== year || d.getMonth() !== month || d.getDate() !== day) {
      return null;
    }

    return d;
  }

  return null;
}

// 🟢 IMPROVED: Check for task-related keywords more intelligently
function hasTaskKeywords(question) {
  const q = question.toLowerCase();
  const taskKeywords = ['task', 'todo', 'to-do', 'assignment', 'work', 'schedule', 'upcoming', 'remind', 'deadline', 'done', 'completed', 'pending', 'active'];
  return taskKeywords.some(keyword => q.includes(keyword));
}

// 🟢 IMPROVED: Check for note-related keywords more intelligently
function hasNoteKeywords(question) {
  const q = question.toLowerCase();
  const noteKeywords = ['note', 'memo', 'information', 'record', 'written', 'saved', 'content', 'text'];
  return noteKeywords.some(keyword => q.includes(keyword));
}

// Try to extract a note title
function extractNoteTitle(question) {
  if (!question) return null;
  
  // Look for text inside quotes after "note"
  const quoted = question.match(/note[^"']*["']([^"']+)["']/i);
  if (quoted && quoted[1]) {
    return quoted[1].trim();
  }

  // Pattern: "note titled X"
  const titled = question.match(/note\s+(?:titled|called|named)\s+(.+?)(?:\s*[?!.]|$)/i);
  if (titled && titled[1]) {
    return titled[1].trim();
  }

  return null;
}

// Try to extract a subject or keyword after phrases like "notes about X", "notes on X", "find notes regarding X"
function extractNoteSubject(question) {
  if (!question) return null;
  const q = question.toLowerCase();

  // Patterns like: notes about X / find notes about X / notes on X / notes regarding X
  const aboutMatch = q.match(/notes?\s+(?:about|on|regarding|about the|about my)\s+(.+?)(?:\s*[?!.]|$)/i);
  if (aboutMatch && aboutMatch[1]) return aboutMatch[1].trim();

  // Patterns like: find notes with X / search notes for X / notes containing X
  const containMatch = q.match(/notes?\s+(?:containing|with|that contain|that have|containing the|containing my)\s+(.+?)(?:\s*[?!.]|$)/i);
  if (containMatch && containMatch[1]) return containMatch[1].trim();

  // If user asks: "show notes about \"X\"" or similar quoted subject
  const quoted = q.match(/notes?[^\"']*[\"']([^\"']+)[\"']/i);
  if (quoted && quoted[1]) return quoted[1].trim();

  return null;
}

// 🟢 COMPLETELY REWRITTEN: Flexible intent detection with natural language understanding
function detectIntent(question) {
  if (!question) return 'rag_generic';
  
  const q = question.toLowerCase();
  
  // Helper: Check if all keywords are present (in any order)
  const containsAllKeywords = (text, keywords) => {
    return keywords.every(kw => text.includes(kw));
  };
  
  // Helper: Check if any keyword is present
  const containsAnyKeyword = (text, keywords) => {
    return keywords.some(kw => text.includes(kw));
  };

  // 🎯 Priority 1: Check for ALL TASKS (various phrasings)
  const allTasksKeywords = [
    /all\s+(my\s+)?tasks?/i,
    /task.*list/i,
    /list\s+(my\s+)?tasks?/i,
    /show\s+(my\s+)?tasks?/i,
    /tell\s+.*all\s+(my\s+)?tasks?/i,
    /what\s+(are\s+)?(?:all\s+)?(?:my\s+)?tasks?/i,
    /my\s+(complete\s+)?task.*list/i,
    /get\s+all\s+(my\s+)?tasks?/i,
  ];
  if (allTasksKeywords.some(pattern => pattern.test(q))) {
    return 'all_tasks';
  }

  // 🎯 Priority 2: Check for PENDING TASKS (various phrasings)
  const pendingKeywords = ['pending', 'undone', 'incomplete', 'ongoing', 'active', 'not done'];
  const taskKeywords = ['task', 'todo', 'to-do', 'to do'];
  
  if (containsAnyKeyword(q, pendingKeywords)) {
    // If question mentions pending/undone, check if it's about tasks
    if (containsAnyKeyword(q, taskKeywords) || 
        containsAnyKeyword(q, ['all', 'my', 'tell', 'show', 'list', 'what', 'get'])) {
      return 'pending_tasks';
    }
  }

  // 🎯 Priority 3: Check for COMPLETED TASKS (various phrasings)
  const completedKeywords = ['completed', 'finished', 'done', 'completed tasks', 'finished tasks'];
  const completedPatterns = [
    /completed\s+(tasks?)?/i,
    /finished\s+(tasks?)?/i,
    /(all\s+)?done\s+(tasks?)?/i,
    /show.*(?:completed|finished|done)/i,
    /list.*(?:completed|finished|done)/i,
    /what.*(?:completed|finished|done)/i,
  ];
  if (completedPatterns.some(pattern => pattern.test(q))) {
    return 'completed_tasks';
  }

  // 🎯 Priority 4: Check for ALL NOTES (various phrasings)
  const allNotesKeywords = [
    /all\s+(my\s+)?notes?/i,
    /list\s+(all\s+)?(?:my\s+)?notes?/i,
    /show\s+(my\s+)?notes?/i,
    /tell\s+.*all\s+(my\s+)?notes?/i,
    /what\s+(?:are|is)\s+(?:all\s+)?(?:my\s+)?notes?/i,
    /my\s+notes?.*list/i,
    /get\s+all\s+(my\s+)?notes?/i,
  ];
  if (allNotesKeywords.some(pattern => pattern.test(q))) {
    return 'all_notes';
  }

  // 🎯 Priority 5: Check for NOTE BY TITLE
  if (extractNoteTitle(question)) {
    return 'note_by_title';
  }

  // 🎯 Priority 6: Check for NOTES BY SUBJECT/CONTENT (e.g., "notes about X", "notes containing X")
  if (extractNoteSubject(question)) {
    return 'notes_by_subject';
  }

  // 🎯 Priority 6: Check for DATE-BASED QUERIES
  const extractedDate = extractDateFromQuestion(question);
  if (extractedDate) {
    if (containsAnyKeyword(q, taskKeywords)) {
      return 'tasks_by_date';
    }
    return 'rag_with_date';
  }

  // 🎯 Default: Use semantic search (RAG) for all other questions
  return 'rag_generic';
}
const { answerQuestionForPatient } = require('../services/ragService');

// 🟢 NEW: Helper to apply fallback semantic search if specific queries return empty
async function performSemanticSearch(userId, question, limit = 10) {
  try {
    const questionEmbedding = await getEmbedding(question);

    const noteResults = await Note.aggregate([
      {
        $vectorSearch: {
          index: 'note_embedding_index',
          path: 'embedding',
          queryVector: questionEmbedding,
          numCandidates: 100,
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

    const taskResults = await Task.aggregate([
      {
        $vectorSearch: {
          index: 'task_embedding_index',
          path: 'embedding',
          queryVector: questionEmbedding,
          numCandidates: 100,
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

    return { notes: noteResults, tasks: taskResults };
  } catch (error) {
    console.error('Semantic search error:', error);
    return { notes: [], tasks: [] };
  }
}

exports.askRagQuestion = async (req, res) => {
  try {
    const { question, chatHistory } = req.body;
    if (!question || !question.trim()) {
      return res.status(400).json({ error: 'Question is required' });
    }

<<<<<<< HEAD
    const userId = new ObjectId(req.user.id);

    // Fetch user profile data
    const userData = await User.findById(userId).select('fullName dateOfBirth mobile address aadhar patientId').lean();

    const intent = detectIntent(question);
    let notes = [];
    let tasks = [];
    let combined = [];
    let usedFallback = false;

    console.log(`[RAG] Intent detected: ${intent} for question: "${question}"`);

    if (intent === 'all_tasks') {
      tasks = await Task.find({ userId }).sort({ date: 1 }).lean();
      
      // 🟢 IMPROVED: Fallback if no tasks found
      if (tasks.length === 0) {
        console.log(`[RAG] No tasks found, attempting semantic search`);
        const semanticResults = await performSemanticSearch(userId, question);
        notes = semanticResults.notes;
        tasks = semanticResults.tasks;
        usedFallback = true;
      }
    } else if (intent === 'pending_tasks') {
      tasks = await Task.find({ userId, done: false }).sort({ date: 1 }).lean();
      
      // 🟢 IMPROVED: Fallback if no pending tasks found
      if (tasks.length === 0) {
        console.log(`[RAG] No pending tasks found, attempting semantic search`);
        const semanticResults = await performSemanticSearch(userId, question);
        notes = semanticResults.notes;
        tasks = semanticResults.tasks;
        usedFallback = true;
      }
    } else if (intent === 'completed_tasks') {
      tasks = await Task.find({ userId, done: true }).sort({ date: 1 }).lean();
      
      // 🟢 IMPROVED: Fallback if no completed tasks found
      if (tasks.length === 0) {
        console.log(`[RAG] No completed tasks found, attempting semantic search`);
        const semanticResults = await performSemanticSearch(userId, question);
        notes = semanticResults.notes;
        tasks = semanticResults.tasks;
        usedFallback = true;
      }
    } else if (intent === 'all_notes') {
      notes = await Note.find({ userId }).sort({ createdAt: -1 }).lean();
      
      // 🟢 IMPROVED: Fallback if no notes found
      if (notes.length === 0) {
        console.log(`[RAG] No notes found, attempting semantic search`);
        const semanticResults = await performSemanticSearch(userId, question);
        notes = semanticResults.notes;
        tasks = semanticResults.tasks;
        usedFallback = true;
      }
    } else if (intent === 'note_by_title') {
      const title = extractNoteTitle(question);
      if (title) {
        const regex = new RegExp(title.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
        // First try title match
        notes = await Note.find({ userId, title: regex }).sort({ createdAt: -1 }).lean();
        // If none found, try content search (case-insensitive partial)
        if (notes.length === 0) {
          console.log(`[RAG] No title-match for "${title}", trying content search.`);
          notes = await Note.find({ userId, content: regex }).sort({ createdAt: -1 }).lean();
        }
        
        // Fallback to semantic search if no notes found by title
        if (notes.length === 0) {
          console.log(`[RAG] No notes found by title/content "${title}", falling back to semantic search`);
          const semanticResults = await performSemanticSearch(userId, question);
          notes = semanticResults.notes;
          tasks = semanticResults.tasks;
          usedFallback = true;
        }
      }
    } else if (intent === 'notes_by_subject') {
      const subject = extractNoteSubject(question);
      if (subject) {
        const regex = new RegExp(subject.replace(/[.*+?^${}()|[\]\\]/g, '\\$&'), 'i');
        // Search title and content
        notes = await Note.find({ userId, $or: [{ title: regex }, { content: regex }] }).sort({ createdAt: -1 }).lean();
        if (notes.length === 0) {
          console.log(`[RAG] No notes found for subject "${subject}", falling back to semantic search`);
          const semanticResults = await performSemanticSearch(userId, question);
          notes = semanticResults.notes;
          tasks = semanticResults.tasks;
          usedFallback = true;
        }
      }
    } else if (intent === 'tasks_by_date') {
      const extractedDate = extractDateFromQuestion(question);
      if (extractedDate) {
        console.log(`[RAG] tasks_by_date detected. date=${extractedDate.toISOString()}`);

        const day = extractedDate.getUTCDate();
        const month = extractedDate.getUTCMonth() + 1;
        const year = extractedDate.getUTCFullYear();

        // Match by year/month/day to avoid timezone mismatches
        tasks = await Task.find({
          userId,
          $expr: {
            $and: [
              { $eq: [{ $year: '$date' }, year] },
              { $eq: [{ $month: '$date' }, month] },
              { $eq: [{ $dayOfMonth: '$date' }, day] }
            ]
          }
        }).sort({ date: 1 }).lean();

        // Fallback to semantic search if no tasks found on that date
        if (tasks.length === 0) {
          console.log(`[RAG] No tasks found for date ${extractedDate.toDateString()}, falling back to semantic search`);
          const semanticResults = await performSemanticSearch(userId, question);
          notes = semanticResults.notes;
          tasks = semanticResults.tasks;
          usedFallback = true;
        }
      }
    } else if (intent === 'rag_with_date') {
      // Date mentioned but no specific keywords - use semantic search with date filter
      const extractedDate = extractDateFromQuestion(question);
      const semanticResults = await performSemanticSearch(userId, question);
      notes = semanticResults.notes;
      tasks = semanticResults.tasks;

      if (extractedDate) {
        const day = extractedDate.getUTCDate();
        const month = extractedDate.getUTCMonth() + 1;
        const year = extractedDate.getUTCFullYear();

        const dateFilteredTasks = await Task.find({
          userId,
          $expr: {
            $and: [
              { $eq: [{ $year: '$date' }, year] },
              { $eq: [{ $month: '$date' }, month] },
              { $eq: [{ $dayOfMonth: '$date' }, day] }
            ]
          }
        }).lean();

        tasks = [...tasks, ...dateFilteredTasks];
      }
    } else {
      // RAG generic flow: semantic search for any question
      const semanticResults = await performSemanticSearch(userId, question);
      notes = semanticResults.notes;
      tasks = semanticResults.tasks;

      // Also try to extract and add date-filtered tasks
      const extractedDate = extractDateFromQuestion(question);
      if (extractedDate) {
        const day = extractedDate.getUTCDate();
        const month = extractedDate.getUTCMonth() + 1;
        const year = extractedDate.getUTCFullYear();

        const dateFilteredTasks = await Task.find({
          userId,
          $expr: {
            $and: [
              { $eq: [{ $year: '$date' }, year] },
              { $eq: [{ $month: '$date' }, month] },
              { $eq: [{ $dayOfMonth: '$date' }, day] }
            ]
          }
        }).lean();

        tasks = [...tasks, ...dateFilteredTasks];
      }
    }

    // Build combined results for context
    if (combined.length === 0 && (notes.length > 0 || tasks.length > 0)) {
      combined = [
        ...notes.map(n => ({ type: 'note', ...n })),
        ...tasks.map(t => ({ type: 'task', ...t }))
      ];
    }

    const contextText = buildContextFromResults(notes, tasks, userData);

    const listPrompt = `
You are an assistant that answers questions based only on the provided context.

The context contains Todos and Notes for one user, along with their profile information.

INSTRUCTIONS:
- If the context contains any matching Todos or Notes, list them clearly, one per line.
- Each Todo must include: title, status (Pending or Completed), and date.
- Format each item clearly and concisely.
- If there are no matching items, reply: "You have no matching tasks or notes."
- Do NOT ask for more information.
- Do NOT provide generic advice.

Context:
${contextText || '(no relevant notes or todos found)'}

Question: ${question}

Answer based ONLY on the context provided.
`.trim();

    const ragPrompt = `
You are an assistant answering questions about a user's tasks and notes based solely on the provided context.

Context:
${contextText || '(no relevant notes or todos found)'}

Question: ${question}

Answer the question accurately using ONLY the information in the context. If the context doesn't contain relevant information, say so clearly.
`.trim();

    const promptToUse = (intent === 'rag_generic' || intent === 'rag_with_date') ? ragPrompt : listPrompt;

    const rawAnswer = await generateAnswer(promptToUse);

    res.json({
      answer: rawAnswer,
      context: contextText,
      sources: combined,
      intent: intent
=======
    const result = await answerQuestionForPatient({
      patientId: req.user.id,
      question: question.trim(),
      chatHistory: Array.isArray(chatHistory) ? chatHistory : []
    });

    res.json({
      answer: result.answer,
      standaloneQuestion: result.standaloneQuestion,
      context: result.context,
      sources: result.sources
>>>>>>> 6f051c541237d3b4bb466989951fc8de0262b09e
    });
  } catch (error) {
    console.error('RAG error:', error);
    res.status(500).json({ error: 'Failed to answer question', details: error.message });
  }
};
