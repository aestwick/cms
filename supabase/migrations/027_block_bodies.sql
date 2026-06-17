-- Migration 027: Block-based bodies for Stories and Episodes
-- Both content streams move to a typed JSONB block array (see
-- src/lib/blocks.ts — the canonical, versioned contract the podcast app
-- consumes). The legacy text bodies are kept for backfill/fallback and
-- are not dropped here.

-- Stories (cms_posts.body is the legacy rich-text field; keep it).
ALTER TABLE cms_posts
  ADD COLUMN IF NOT EXISTS body_blocks jsonb NOT NULL DEFAULT '[]'::jsonb;

-- Episodes (cms_episode_metadata.description is the legacy summary; keep it).
ALTER TABLE cms_episode_metadata
  ADD COLUMN IF NOT EXISTS body_blocks jsonb NOT NULL DEFAULT '[]'::jsonb;

-- GIN indexes so external consumers / queries can filter on block content.
CREATE INDEX IF NOT EXISTS idx_cms_posts_body_blocks
  ON cms_posts USING gin (body_blocks);

CREATE INDEX IF NOT EXISTS idx_cms_episode_metadata_body_blocks
  ON cms_episode_metadata USING gin (body_blocks);
