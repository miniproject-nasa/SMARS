const { RecursiveCharacterTextSplitter } = require("@langchain/textsplitters");
const { SupabaseVectorStore } = require("@langchain/community/vectorstores/supabase");
const { Embeddings } = require("@langchain/core/embeddings");
const { ChatGoogle } = require("@langchain/google");
const { createClient } = require("@supabase/supabase-js");

const { getEmbedding } = require("../utils/huggingface");

const DOC_TABLE = process.env.SUPABASE_VECTOR_TABLE || "documents";
const DOC_QUERY_NAME = process.env.SUPABASE_VECTOR_QUERY_NAME || "match_documents";

class BgeSmallEmbeddings extends Embeddings {
  async embedDocuments(texts) {
    const vectors = [];
    for (const text of texts) {
      vectors.push(await getEmbedding(text));
    }
    return vectors;
  }

  async embedQuery(text) {
    return getEmbedding(text);
  }
}

const splitter = new RecursiveCharacterTextSplitter({
  chunkSize: 512,
  chunkOverlap: 60,
});

const embeddings = new BgeSmallEmbeddings();

const llm = new ChatGoogle({
  apiKey: process.env.GOOGLE_API_KEY,
  model: "gemini-2.5-flash",
});

function getSupabaseClient() {
  const url = process.env.SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;

  if (!url || !key) {
    throw new Error("SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required");
  }

  return createClient(url, key, {
    auth: { persistSession: false },
  });
}

function parseModelText(output) {
  if (!output) return "";
  if (typeof output.content === "string") return output.content;
  if (Array.isArray(output.content)) {
    return output.content
      .map((chunk) => (typeof chunk === "string" ? chunk : chunk.text || ""))
      .join(" ")
      .trim();
  }
  return "";
}

function toIso(value) {
  if (!value) return null;
  const d = new Date(value);
  if (isNaN(d.getTime())) return null;
  return d.toISOString();
}

function buildTaskStructuredDocument(task, patientId) {
  const status = task.done ? "completed" : "pending";
  const dueDate = toIso(task.date);

  return [
    "DOC_TYPE: task",
    `PATIENT_ID: ${patientId}`,
    `SOURCE_ID: ${task._id}`,
    `TITLE: ${task.title || ""}`,
    `STATUS: ${status}`,
    `DUE_DATE: ${dueDate || ""}`,
    `CATEGORY: ${task.category || "General"}`,
    `RECURRENCE: ${task.recurrence || "None"}`,
    `CREATED_AT: ${toIso(task.createdAt) || ""}`,
    `UPDATED_AT: ${toIso(task.updatedAt) || ""}`,
    `NATURAL_SUMMARY: Task ${task.title || ""} is currently ${status}.${dueDate ? ` Due on ${dueDate}.` : ""}`,
  ].join("\n");
}

function buildNoteStructuredDocument(note, patientId) {
  return [
    "DOC_TYPE: note",
    `PATIENT_ID: ${patientId}`,
    `SOURCE_ID: ${note._id}`,
    `TITLE: ${note.title || ""}`,
    `CONTENT: ${note.content || ""}`,
    `CREATED_AT: ${toIso(note.createdAt) || ""}`,
    `UPDATED_AT: ${toIso(note.updatedAt) || ""}`,
    `NATURAL_SUMMARY: Note titled ${note.title || "untitled"}. ${note.content || ""}`,
  ].join("\n");
}

async function createStandaloneQuestion(question, chatHistory = []) {
  const historyText = Array.isArray(chatHistory)
    ? chatHistory
        .slice(-10)
        .map((m) => `${m.role || "user"}: ${m.content || ""}`)
        .join("\n")
    : "";
const now = new Date();
const todayIso = now.toISOString().slice(0, 10); // YYYY-MM-DD
const tz = Intl.DateTimeFormat().resolvedOptions().timeZone || "UTC";

const prompt = `
You rewrite follow-up user questions as a standalone question for retrieval.
Do not answer the question. Return only one standalone question.
Preserve intent, dates,medications, tasks, and personal references.

Temporal normalization rules:
- Current date: ${todayIso}
- Timezone: ${tz}
- Convert relative dates to absolute dates:
  - today -> ${todayIso}
  - tomorrow -> today + 1 day
  - yesterday -> today - 1 day
  -do similarly for all other relative dates too
- Use YYYY-MM-DD format in the rewritten question.
- If no date is mentioned, keep the question unchanged except for making it standalone.

Chat history:
${historyText || "(none)"}

User question:
${question}
`.trim();


  const rewritten = await llm.invoke(prompt);
  const standalone = parseModelText(rewritten);

  return standalone || question;
}

async function deleteSourceChunks(patientId, sourceType, sourceId) {
  const supabase = getSupabaseClient();

  const { error } = await supabase
    .from(DOC_TABLE)
    .delete()
    .filter("metadata->>patient_id", "eq", String(patientId))
    .filter("metadata->>type", "eq", sourceType)
    .filter("metadata->>source_id", "eq", String(sourceId));

  if (error) {
    throw new Error(`Failed to delete old chunks: ${error.message}`);
  }
}

async function upsertStructuredDocument(content, metadata) {
  const supabase = getSupabaseClient();

  const output = await splitter.createDocuments([content]);
  const prepared = output.map((doc, idx) => {
    doc.metadata = {
      ...metadata,
      chunk_index: idx,
    };
    return doc;
  });

  await SupabaseVectorStore.fromDocuments(prepared, embeddings, {
    client: supabase,
    tableName: DOC_TABLE,
    queryName: DOC_QUERY_NAME,
  });
}

async function syncTaskEmbedding(task, patientId) {
  await deleteSourceChunks(patientId, "task", task._id);

  const content = buildTaskStructuredDocument(task, patientId);
  await upsertStructuredDocument(content, {
    patient_id: String(patientId),
    type: "task",
    source_id: String(task._id),
    created_at: toIso(task.createdAt),
    task_status: task.done ? "completed" : "pending",
  });
}

async function syncNoteEmbedding(note, patientId) {
  await deleteSourceChunks(patientId, "note", note._id);

  const content = buildNoteStructuredDocument(note, patientId);
  await upsertStructuredDocument(content, {
    patient_id: String(patientId),
    type: "note",
    source_id: String(note._id),
    created_at: toIso(note.createdAt),
  });
}

async function deleteSourceEmbedding(patientId, sourceType, sourceId) {
  await deleteSourceChunks(patientId, sourceType, sourceId);
}

function buildContextFromDocs(docs) {
  return docs
    .map((doc, idx) => {
      const md = doc.metadata || {};
      return [
        `[Chunk ${idx + 1}]`,
        `type=${md.type || "unknown"}`,
        `source_id=${md.source_id || ""}`,
        `created_at=${md.created_at || ""}`,
        doc.pageContent || "",
      ].join("\n");
    })
    .join("\n\n");
}

async function answerQuestionForPatient({ patientId, question, chatHistory = [] }) {
  const standaloneQuestion = await createStandaloneQuestion(question, chatHistory);

  const supabase = getSupabaseClient();
  const vectorStore = new SupabaseVectorStore(embeddings, {
    client: supabase,
    tableName: DOC_TABLE,
    queryName: DOC_QUERY_NAME,
  });

  const docs = await vectorStore.similaritySearch(standaloneQuestion, 8, {
    patient_id: String(patientId),
  });

  const context = buildContextFromDocs(docs);

  const prompt = `
You are a memory assistant for an Alzheimer's support application.
Answer using ONLY the retrieved context.
If context is missing details, say that clearly and do not invent facts.
Use simple, supportive language.

Retrieved context:
${context || "(no context found)"}

Original question:
${question}

Standalone retrieval question:
${standaloneQuestion}

Answer:
`.trim();

  const response = await llm.invoke(prompt);
  const answer = parseModelText(response) || "I could not find relevant information in your notes or tasks.";

  return {
    answer,
    standaloneQuestion,
    context,
    sources: docs.map((doc) => ({
      metadata: doc.metadata,
      content: doc.pageContent,
    })),
  };
}

module.exports = {
  answerQuestionForPatient,
  syncTaskEmbedding,
  syncNoteEmbedding,
  deleteSourceEmbedding,
  createStandaloneQuestion,
};
