# KnowledgeOS AI

KnowledgeOS AI is a production-grade SaaS web application functioning as an AI-powered knowledge operating system. It transforms uploaded documents into a living, interconnected, searchable knowledge base, combining features from Wikipedia, Confluence, Notion, Obsidian, ChatGPT, and Enterprise Knowledge Management Systems.

The platform is designed as a multi-tenant SaaS capable of serving thousands of organizations, ensuring that all data is strictly isolated on a per-organization basis.

## Core Features
- **Multi-Tenant Architecture**: Strict isolation of organizations with robust membership and workspace management.
- **Authentication & RBAC**: Powered by Supabase Auth with Owner, Admin, Editor, and Viewer roles enforced by PostgreSQL Row Level Security (RLS).
- **Document Library**: Supports a wide array of formats (PDF, DOCX, CSV, Markdown, etc.) stored securely in Cloudflare R2. Includes drag-and-drop upload, version history, tagging, and previewing.
- **AI Document Processing**: Asynchronous ingestion pipeline that extracts content, chunks text, generates embeddings (via OpenRouter), builds a knowledge graph, and automatically generates wiki pages.
- **AI Wiki Engine**: Automatically creates and updates wiki-style pages for overview, concepts, and entities. Users can edit or request AI regeneration.
- **Knowledge Graph**: Interactive React Flow based visualization of relationships between extracted entities (People, Organizations, Concepts, etc.).
- **AI Chat Assistant**: RAG-based AI assistant using OpenRouter models (GPT, Claude, DeepSeek, etc.) supporting multi-document reasoning, follow-up questions, and precise citations.
- **Knowledge Diff Engine**: Automatically analyzes versions of documents to generate human-readable summaries, impact analysis, and side-by-side comparisons of changes.
- **Rule Engine**: Transforms documents (e.g., policy PDFs) into executable decisions by evaluating retrieved policies, explaining the reasoning, and giving a final verdict with citations.
- **Advanced Search**: A hybrid search architecture leveraging PostgreSQL Full-Text Search, pgvector for semantic search, and an integrated reranking step to ensure scalability and high quality for massive datasets.
- **Analytics & Security**: Comprehensive dashboard metrics, Rate Limiting, Signed R2 URLs, Audit Logs, and Encryption at Rest.

## Tech Stack
- **Frontend**: Next.js 15 (App Router), React 19, TypeScript, Tailwind CSS, shadcn/ui, TanStack Query, React Flow
- **Backend**: Next.js Server Actions, API Routes, Background Workers
- **Database**: Supabase PostgreSQL with `pgvector`
- **Auth**: Supabase Auth (Email/Password, Google OAuth)
- **Storage**: Cloudflare R2
- **Caching & Queues**: Redis
- **AI Models**: OpenRouter API
- **Deployment**: Docker, Vercel-compatible, Self-hosted compatible

## Documentation
Please see the `docs` folder for detailed system architecture, API design, database schema, and implementation roadmap.
- `docs/ARCHITECTURE.md` - System architecture, API design, various subsystem architectures, and the production implementation roadmap.
- `supabase/migrations/` - Database schemas, RLS policies, and initialization scripts.
- `Dockerfile` & `docker-compose.yml` - Deployment configuration.
