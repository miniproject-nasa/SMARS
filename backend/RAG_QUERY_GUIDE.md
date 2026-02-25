# RAG Bot Query Guide - Flexible Natural Language Support

## 🎯 Intent Detection System

The RAG bot now understands natural language variations of queries. Below are all the query types that are now supported:

---

## 📋 ALL TASKS QUERIES

Any of these queries will return ALL tasks:

```
✅ "all tasks"
✅ "show my tasks"
✅ "list my tasks"
✅ "what are my tasks"
✅ "tell me all tasks"
✅ "get all my tasks"
✅ "my task list"
✅ "tasks"
✅ "all my tasks"
```

---

## ⏳ PENDING TASKS QUERIES  

Any of these queries will return PENDING (undone) tasks:

```
✅ "pending tasks"
✅ "tell my all pending task"
✅ "show me pending tasks"
✅ "what are my pending tasks"
✅ "undone tasks"
✅ "incomplete tasks"
✅ "active tasks"
✅ "ongoing tasks"
✅ "my pending work"
✅ "tasks not done"
```

---

## ✅ COMPLETED TASKS QUERIES

Any of these queries will return COMPLETED tasks:

```
✅ "completed tasks"
✅ "finished tasks"
✅ "done tasks"
✅ "all done tasks"
✅ "show me completed tasks"
✅ "what tasks are completed"
✅ "show finished tasks"
✅ "tasks i finished"
```

---

## 📝 ALL NOTES QUERIES

Any of these queries will return ALL notes:

```
✅ "all notes"
✅ "show my notes"
✅ "list all notes"
✅ "my notes"
✅ "what notes do i have"
✅ "get all my notes"
✅ "tell me all notes"
```

---

## 📍 NOTES BY TITLE

Any of these patterns will find a specific note:

```
✅ "note titled Shopping"
✅ "note called Meeting Notes"
✅ "note named Doctor Appointment"
✅ "show note "Meeting""
✅ "get note "Reminders""
```

---

## 📅 DATE-BASED TASKS

Query tasks for a specific date:

### Explicit Dates:
```
✅ "task in 24-2-2026"
✅ "task on 24/02/2026"
✅ "tasks for 24.02.2026"
✅ "tasks on 24 02 2026"
✅ "what tasks on 24-2-2026"
✅ "show me tasks for 24-2-2026"
✅ "pending tasks on 24-2-2026"
```

### Relative Dates (NEW 🎉):
```
✅ "tasks today"
✅ "tasks tomorrow"
✅ "tasks yesterday"
✅ "pending tasks today"
✅ "tasks for today"
✅ "what do i have today"
✅ "show me tasks tonight"
✅ "tasks next week"
✅ "tasks last week"
✅ "tasks this week"
✅ "tasks next day"
✅ "pending tasks tomorrow"
✅ "completed tasks today"
```

**Date Formats Supported:**
- Explicit: `dd-mm-yyyy`, `dd/mm/yyyy`, `dd.mm.yyyy`, `dd mm yyyy`
- Relative: `today`, `tomorrow`, `yesterday`, `next week`, `last week`, `this week`, `tonight`

---

## 🔍 SEMANTIC SEARCH (ANY OTHER QUESTION)

For questions that don't match the above patterns, the bot performs semantic search:

```
✅ "what should i do today"
✅ "remind me about my appointments"
✅ "how much work do i have"
✅ "what's the summary of my tasks"
✅ "find notes about health"
✅ "search for doctor notes"
✅ "am i busy this week"
✅ "what am i working on"
```

---

## 🔄 FALLBACK MECHANISM

If a specific query returns no results, the bot automatically falls back to semantic search:

- Query "pending tasks" → Returns 0 results → Falls back to semantic search
- Query "note titled Shopping" → Exact match not found → Falls back to semantic search
- Query "tasks on 25-2-2026" → No tasks on that date → Falls back to semantic search

---

## 📊 How Intent Detection Works

1. **Keyword Matching**: Looks for specific keywords like "pending", "completed", "all", etc.
2. **Context Awareness**: Checks if the question is about tasks, notes, or dates
3. **Pattern Recognition**: Handles variations in word order (e.g., "tell me all pending tasks" vs "pending tasks tell me")
4. **Semantic Understanding**: Falls back to embeddings-based search for complex questions
5. **Multi-strategy**: Combines multiple approaches for best results

---

## 📝 Response Format

Every RAG query response includes:

```json
{
  "answer": "The bot's response based on context",
  "context": "Formatted context that was used to generate the answer",
  "sources": "Original documents used as sources",
  "intent": "The detected intent (e.g., pending_tasks, rag_generic, etc.)"
}
```

---

## ⚙️ Technical Details

- **Intent Detection**: Flexible keyword-based + pattern matching
- **Date Parsing**: Supports multiple formats with validation
- **Fallback Strategy**: 5-tier fallback system 
- **Semantic Search**: Powered by BAAI/bge-small-en-v1.5 embeddings
- **Database Indexes**: Vector search on embedding indexes
- **User Context**: Includes patient profile info in answers
- **Logging**: Detailed console logs for debugging

---

## 🚀 Testing

All these query types have been tested to work with the flexible intent detection system.

For the best results:
- Use natural language as you normally would
- The bot will understand various phrasings of the same intent
- If specific queries find nothing, semantic search kicks in automatically
- Always provide context (dates, titles, etc.) when available
