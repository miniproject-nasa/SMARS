const { answerQuestionForPatient } = require('../services/ragService');

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

