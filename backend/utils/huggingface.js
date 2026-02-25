const fetch = require('node-fetch');

const HF_API_KEY = process.env.HF_API_KEY;
const EMBEDDING_MODEL = 'BAAI/bge-small-en-v1.5';
const LLM_MODEL = 'mistralai/Mistral-7B-Instruct-v0.2';

if (!HF_API_KEY) {
  console.warn('HF_API_KEY is not set – HuggingFace calls will fail.');
}

async function getEmbedding(text) {
  const response = await fetch(
    `https://router.huggingface.co/hf-inference/models/${EMBEDDING_MODEL}/pipeline/feature-extraction`,
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${HF_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        inputs: text
      })
    }
  );

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`HF embedding error: ${response.status} - ${errText}`);
  }

  const data = await response.json();
  const vector = Array.isArray(data[0]) ? data[0] : data;
  return vector;
}

async function generateAnswer(prompt) {
  const response = await fetch(
    'https://router.huggingface.co/v1/responses',
    {
      method: 'POST',
      headers: {
        Authorization: `Bearer ${HF_API_KEY}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: LLM_MODEL,
        input: prompt,
        max_output_tokens: 256,
        temperature: 0.2,
        top_p: 0.9
      })
    }
  );

  if (!response.ok) {
    const errText = await response.text();
    throw new Error(`HF LLM error: ${response.status} - ${errText}`);
  }

  const data = await response.json();

  // Responses API: text is typically at output[0].content[0].text
  let text = '';
  try {
    if (Array.isArray(data.output) && data.output.length > 0) {
      const first = data.output[0];
      if (Array.isArray(first.content) && first.content.length > 0) {
        const contentItem = first.content[0];
        if (contentItem.text && typeof contentItem.text === 'string') {
          text = contentItem.text;
        }
      }
    }
  } catch (_) {
    // Fallback to raw JSON if structure changes
  }

  if (!text) {
    text = JSON.stringify(data);
  }

  return text;
}

module.exports = {
  getEmbedding,
  generateAnswer
};

