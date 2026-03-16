-- Enable pgvector in Supabase SQL editor before running this script.
create extension if not exists vector;

create table if not exists public.documents (
  id bigserial primary key,
  content text not null,
  metadata jsonb not null,
  embedding vector(384) not null
);

create index if not exists documents_embedding_idx
on public.documents
using hnsw (embedding vector_cosine_ops);

create index if not exists documents_metadata_patient_id_idx
on public.documents ((metadata->>'patient_id'));

create or replace function public.match_documents (
  query_embedding vector(384),
  match_count int default 8,
  filter jsonb default '{}'
)
returns table (
  id bigint,
  content text,
  metadata jsonb,
  similarity float
)
language sql
stable
as $$
  select
    documents.id,
    documents.content,
    documents.metadata,
    1 - (documents.embedding <=> query_embedding) as similarity
  from public.documents
  where documents.metadata @> filter
  order by documents.embedding <=> query_embedding
  limit match_count;
$$;
