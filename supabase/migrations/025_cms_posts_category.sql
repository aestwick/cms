-- Migration 025: Link stories to coverage areas
-- Phase 2a (chunk 2): a story (cms_posts row) can be filed under one
-- coverage area or sub-category. Nullable — existing posts stay
-- uncategorized until edited.

ALTER TABLE cms_posts
  ADD COLUMN IF NOT EXISTS category_id uuid REFERENCES cms_categories(id);

-- Feed/category-page queries: published posts in a category by date.
CREATE INDEX IF NOT EXISTS idx_cms_posts_category
  ON cms_posts (category_id, status, published_at DESC)
  WHERE deleted_at IS NULL AND category_id IS NOT NULL;
