-- KnowledgeOS AI Initial Database Schema

-- Enable pgvector extension
CREATE EXTENSION IF NOT EXISTS vector;

-- 1. Profiles (Users)
CREATE TABLE public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email TEXT UNIQUE NOT NULL,
    full_name TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Organizations
CREATE TABLE public.organizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    slug TEXT UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Memberships
CREATE TYPE org_role AS ENUM ('Owner', 'Admin', 'Editor', 'Viewer');

CREATE TABLE public.memberships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    role org_role NOT NULL DEFAULT 'Viewer',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(organization_id, user_id)
);

-- 4. Documents
CREATE TYPE document_status AS ENUM ('Pending', 'Processing', 'Completed', 'Failed');

CREATE TABLE public.documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    uploader_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    title TEXT NOT NULL,
    file_type TEXT,
    folder_path TEXT DEFAULT '/',
    r2_key TEXT NOT NULL,
    status document_status DEFAULT 'Pending',
    tags TEXT[],
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Document Versions
CREATE TABLE public.document_versions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
    version_number INTEGER NOT NULL,
    r2_key TEXT NOT NULL,
    created_by UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. Document Chunks & Embeddings (Hybrid Search setup)
CREATE TABLE public.document_chunks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    document_id UUID NOT NULL REFERENCES public.documents(id) ON DELETE CASCADE,
    version_id UUID NOT NULL REFERENCES public.document_versions(id) ON DELETE CASCADE,
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    page_number INTEGER,
    chunk_index INTEGER NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Full-Text Search index for chunks
ALTER TABLE public.document_chunks ADD COLUMN fts tsvector GENERATED ALWAYS AS (to_tsvector('english', coalesce(content, ''))) STORED;
CREATE INDEX document_chunks_fts_idx ON public.document_chunks USING GIN (fts);

-- Vectors table for semantic search
CREATE TABLE public.embeddings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    chunk_id UUID NOT NULL REFERENCES public.document_chunks(id) ON DELETE CASCADE,
    embedding vector(1536), -- Assuming OpenAI 1536 dim embeddings
    created_at TIMESTAMPTZ DEFAULT NOW()
);
-- HNSW Index for fast vector similarity search
CREATE INDEX ON public.embeddings USING hnsw (embedding vector_cosine_ops);


-- 7. Wiki Pages
CREATE TABLE public.wiki_pages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    content TEXT NOT NULL,
    is_ai_generated BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. Knowledge Graph Entities
CREATE TABLE public.wiki_entities (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    entity_type TEXT NOT NULL, -- e.g., Person, Organization, Concept
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. Knowledge Graph Relationships
CREATE TABLE public.wiki_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    source_entity_id UUID NOT NULL REFERENCES public.wiki_entities(id) ON DELETE CASCADE,
    target_entity_id UUID NOT NULL REFERENCES public.wiki_entities(id) ON DELETE CASCADE,
    relationship_type TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Graph Nodes & Edges specifically for React Flow (can be derived from entities/relationships or stored explicitly for UI performance)
CREATE TABLE public.knowledge_graph_nodes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    entity_id UUID REFERENCES public.wiki_entities(id) ON DELETE CASCADE,
    ui_x_pos FLOAT NOT NULL DEFAULT 0,
    ui_y_pos FLOAT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.knowledge_graph_edges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    relationship_id UUID REFERENCES public.wiki_relationships(id) ON DELETE CASCADE,
    source_node_id UUID NOT NULL REFERENCES public.knowledge_graph_nodes(id) ON DELETE CASCADE,
    target_node_id UUID NOT NULL REFERENCES public.knowledge_graph_nodes(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. Chat Sessions & Messages
CREATE TABLE public.chat_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    title TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES public.chat_sessions(id) ON DELETE CASCADE,
    role TEXT NOT NULL, -- 'user', 'assistant'
    content TEXT NOT NULL,
    citations JSONB, -- store references to document_chunks
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. Rule Engine
CREATE TABLE public.rule_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    logic_prompt TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.rule_evaluations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    rule_id UUID NOT NULL REFERENCES public.rule_definitions(id) ON DELETE CASCADE,
    evaluated_by UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    input_query TEXT NOT NULL,
    verdict TEXT NOT NULL,
    reasoning TEXT NOT NULL,
    citations JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 12. Audit Logs
CREATE TABLE public.audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    action TEXT NOT NULL,
    resource_type TEXT NOT NULL,
    resource_id UUID,
    details JSONB,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX idx_memberships_org_id ON public.memberships(organization_id);
CREATE INDEX idx_documents_org_id ON public.documents(organization_id);
CREATE INDEX idx_document_chunks_org_id ON public.document_chunks(organization_id);
CREATE INDEX idx_wiki_pages_org_id ON public.wiki_pages(organization_id);
CREATE INDEX idx_chat_sessions_org_id ON public.chat_sessions(organization_id);

-- ==========================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ==========================================

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.organizations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.memberships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_versions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.document_chunks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.embeddings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wiki_pages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wiki_entities ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wiki_relationships ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.knowledge_graph_nodes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.knowledge_graph_edges ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rule_definitions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rule_evaluations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_logs ENABLE ROW LEVEL SECURITY;

-- Helper function to check if user is in an organization
CREATE OR REPLACE FUNCTION auth.is_org_member(org_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.memberships
    WHERE organization_id = org_id AND user_id = auth.uid()
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Profiles: Users can view their own profile and profiles of users in the same organizations
CREATE POLICY "Profiles are viewable by members of shared orgs" ON public.profiles
  FOR SELECT USING (
    id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.memberships m1
      JOIN public.memberships m2 ON m1.organization_id = m2.organization_id
      WHERE m1.user_id = auth.uid() AND m2.user_id = public.profiles.id
    )
  );

CREATE POLICY "Users can update their own profile" ON public.profiles
  FOR UPDATE USING (id = auth.uid());

-- Organizations: Users can view organizations they are members of
CREATE POLICY "View organizations" ON public.organizations
  FOR SELECT USING (auth.is_org_member(id));

-- Memberships: Users can view memberships of their organizations
CREATE POLICY "View memberships" ON public.memberships
  FOR SELECT USING (auth.is_org_member(organization_id));

-- Generic policy template for all organization-owned resources
-- Read access: All members of the organization
-- Write access: Depends on role, but for simplicity here we ensure at least membership

DO $$
DECLARE
  table_name text;
  tables text[] := ARRAY[
    'documents', 'document_chunks', 'wiki_pages', 'wiki_entities',
    'wiki_relationships', 'knowledge_graph_nodes', 'knowledge_graph_edges',
    'chat_sessions', 'rule_definitions', 'rule_evaluations', 'audit_logs'
  ];
BEGIN
  FOREACH table_name IN ARRAY tables LOOP
    EXECUTE format('
      CREATE POLICY "View %I" ON public.%I
        FOR SELECT USING (auth.is_org_member(organization_id));

      CREATE POLICY "Insert %I" ON public.%I
        FOR INSERT WITH CHECK (auth.is_org_member(organization_id));

      CREATE POLICY "Update %I" ON public.%I
        FOR UPDATE USING (auth.is_org_member(organization_id));

      CREATE POLICY "Delete %I" ON public.%I
        FOR DELETE USING (auth.is_org_member(organization_id));
    ', table_name, table_name, table_name, table_name, table_name, table_name, table_name, table_name);
  END LOOP;
END
$$;

-- Note: document_versions, embeddings, and chat_messages derive their security from parent tables
-- Since they don't have organization_id directly (except chunks), we join to check.
-- For brevity and performance in a real app, it is often better to denormalize organization_id.
-- (We did denormalize organization_id onto document_chunks for this reason).

CREATE POLICY "View document_versions" ON public.document_versions
  FOR SELECT USING (EXISTS (SELECT 1 FROM public.documents WHERE documents.id = document_id AND auth.is_org_member(documents.organization_id)));

CREATE POLICY "View embeddings" ON public.embeddings
  FOR SELECT USING (EXISTS (SELECT 1 FROM public.document_chunks WHERE document_chunks.id = chunk_id AND auth.is_org_member(document_chunks.organization_id)));

CREATE POLICY "View chat_messages" ON public.chat_messages
  FOR SELECT USING (EXISTS (SELECT 1 FROM public.chat_sessions WHERE chat_sessions.id = session_id AND auth.is_org_member(chat_sessions.organization_id)));
