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
    });
  } catch (error) {
    console.error('RAG error:', error);
    res.status(500).json({ error: 'Failed to answer question', details: error.message });
  }
};
