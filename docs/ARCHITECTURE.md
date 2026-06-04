# KnowledgeOS AI Architecture & Design

## 1. System Architecture

KnowledgeOS AI uses a modern, scalable, serverless-first architecture optimized for performance, AI operations, and multi-tenancy.

- **Frontend Client:** Next.js 15 (App Router) with React 19, Tailwind, and shadcn/ui. Handles UI, local state, and interactions.
- **Backend / API Layer:** Next.js Server Actions and API Routes provide a secure interface to the database and external services.
- **Database Layer:** Supabase (PostgreSQL) handles all relational data, user profiles, and multi-tenant isolation via RLS. Uses `pgvector` for vector storage and PostgreSQL Full-Text Search for lexical search.
- **Storage Layer:** Cloudflare R2 provides fast, cost-effective S3-compatible object storage for uploaded documents.
- **Background Workers / Job Queue:** Redis-backed worker nodes (or serverless queues like Inngest/Upstash) to handle long-running document processing tasks.
- **AI/LLM Layer:** OpenRouter API is used as the gateway to multiple AI models (GPT-4o, Claude 3.5, Gemini, DeepSeek, etc.) for generation and embeddings.

## 2. Folder Structure

```
knowledgeos/
├── .github/                 # GitHub Actions for CI/CD
├── docs/                    # Documentation (Architecture, APIs)
├── src/
│   ├── app/                 # Next.js App Router pages and layouts
│   │   ├── (auth)/          # Authentication pages
│   │   ├── (dashboard)/     # Main application UI
│   │   ├── api/             # API routes and webhooks
│   │   └── layout.tsx
│   ├── components/          # Reusable UI components (shadcn, etc.)
│   │   ├── ui/
│   │   └── shared/
│   ├── features/            # Feature-based modular code
│   │   ├── chat/            # Chat UI and hooks
│   │   ├── documents/       # Document upload and list UI
│   │   ├── graph/           # React Flow knowledge graph
│   │   └── wiki/            # Wiki page rendering
│   ├── lib/                 # Core utilities
│   │   ├── ai/              # OpenRouter integrations
│   │   ├── db/              # Supabase clients
│   │   ├── r2/              # Cloudflare R2 clients
│   │   ├── search/          # Hybrid search logic
│   │   └── utils.ts
│   ├── server/              # Server Actions and internal APIs
│   ├── types/               # TypeScript type definitions
│   └── workers/             # Background job processors
├── supabase/
│   ├── migrations/          # PostgreSQL schema migrations
│   └── seed.sql             # Seed data
├── public/                  # Static assets
├── docker-compose.yml       # Local and self-hosted deployment
├── Dockerfile               # Production container definition
├── package.json
└── tailwind.config.ts
```

## 3. API Design

The API uses a mix of Next.js Server Actions (for mutations and form submissions) and standard REST/Serverless API routes for webhooks and streaming.

- **`POST /api/documents/upload`**
  Generates presigned R2 URLs for direct-to-R2 file uploads from the client, bypassing server payload limits.
- **`POST /api/webhooks/document-uploaded`**
  Triggered when R2 receives a file or the client confirms upload. Enqueues a processing job.
- **`POST /api/chat`**
  Handles RAG queries. Streams the AI response back using Vercel AI SDK or custom streams.
- **`GET /api/graph/entities?org_id={id}`**
  Returns nodes and edges for the Knowledge Graph visualization.
- **`POST /api/rules/evaluate`**
  Accepts a query and returns the evaluated decision using the Rule Engine.

## 4. Hybrid Search Architecture

To ensure high quality and scalability across tens of thousands of documents, the search architecture avoids relying entirely on pgvector.

1. **Query Processing:** The user's query is analyzed.
2. **First-stage Retrieval:**
   - **Semantic Search:** `pgvector` finds chunks with high cosine similarity to the query embedding.
   - **Lexical Search:** PostgreSQL Full-Text Search (`tsvector`) finds exact keyword matches.
3. **Merging & Reciprocal Rank Fusion (RRF):** Results from both retrievers are merged and scored using RRF.
4. **Reranking (Second-stage):** A fast cross-encoder (or an LLM reranking prompt) scores the top N results to ensure the absolute most relevant chunks are sent to the generation model.

## 5. Job Queue Architecture

Document processing is asynchronous and stateful.

- **Queue System:** BullMQ backed by Redis (or an equivalent serverless queue).
- **Workflow:**
  1. `pending`: Document record created.
  2. `processing`: Worker picks up the job.
     - Downloads document from R2.
     - Extracts text (using Unstructured.io or similar).
     - Chunks text.
     - Embeds chunks via OpenRouter and saves to Supabase.
     - Extracts entities and updates the Knowledge Graph.
     - Updates/generates Wiki Pages.
  3. `completed` / `failed`: Status updated in the `documents` table.

## 6. OpenRouter Integration Architecture

OpenRouter provides a unified API for various LLMs.

- **Embeddings:** Routed to an OpenAI-compatible embedding model (e.g., `text-embedding-3-small` or an open-source equivalent provided by OpenRouter) for generating vectors.
- **Generation:** Routing to different models based on user selection or task requirements (e.g., GPT-4o for complex reasoning, Claude 3.5 Sonnet for fast analysis).
- **Fallback Logic:** Implemented robust retries and fallback models in case the primary selected model is rate-limited or down.

## 7. Cloudflare R2 Integration Architecture

- **Storage:** Securely stores raw uploaded files and parsed derivatives.
- **Security:** R2 buckets are private. Access is mediated through short-lived presigned URLs generated by the backend API.
- **Cost Efficiency:** Zero egress fees allow for inexpensive large-scale document downloads by the worker nodes during processing.

## 8. Knowledge Graph Architecture

- **Extraction:** During document processing, LLMs extract named entities and their relationships.
- **Storage:** Stored in relational tables (`wiki_entities`, `wiki_relationships`, `knowledge_graph_nodes`, `knowledge_graph_edges`).
- **Visualization:** The frontend queries the graph API and renders the interactive UI using `React Flow`, enabling pan, zoom, and entity details panels.

## 9. Rule Engine Architecture

Transforming policies into executable code:
- **Definitions:** Rules are defined based on ingested policies.
- **Evaluation Service:** When a user asks "Can Employee A exchange duty with Employee B?", the Rule Engine triggers a specialized RAG pipeline.
  - Retrieves specific policy chunks.
  - Formulates a strict, logical prompt for the LLM.
  - The LLM acts as the decision engine, returning a JSON structured output with `verdict`, `reasoning`, and `citations`.
- **Audit Logging:** Every rule evaluation is logged in the `rule_evaluations` and `audit_logs` tables for compliance and traceability.

## 10. Implementation Roadmap

### Phase 1: Foundation & Infrastructure (Weeks 1-2)
- Set up Next.js, Tailwind, shadcn/ui.
- Configure Supabase, RLS, multi-tenant tables.
- Setup Cloudflare R2 for uploads.

### Phase 2: Ingestion & Search (Weeks 3-5)
- Implement Job Queue and background workers.
- Integrate text extraction and chunking.
- Implement Hybrid Search (FTS + pgvector + RRF).
- Integrate OpenRouter for embeddings.

### Phase 3: AI Core Features (Weeks 6-8)
- Build RAG-based AI Chat Assistant.
- Develop the AI Wiki Engine for automatic page generation.
- Implement the Knowledge Graph visualization with React Flow.

### Phase 4: Advanced Features (Weeks 9-10)
- Implement Knowledge Diff Engine (document version tracking and analysis).
- Build the Rule Engine.

### Phase 5: Production Readiness (Weeks 11-12)
- Security audits, rate limiting, and analytics dashboards.
- Refine Docker setup.
- Beta deployment and testing.
