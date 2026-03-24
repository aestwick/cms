-- Migration 003: Media library, Flags, and Audit Log
-- Supporting tables for Phase 1

-- ============================================================
-- cms_media — Metadata for files in Supabase Storage
-- ============================================================
CREATE TABLE IF NOT EXISTS cms_media (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  station_id uuid NOT NULL REFERENCES cms_stations(id),
  storage_path text NOT NULL,
  filename text NOT NULL,
  alt_text text,
  mime_type text NOT NULL,
  size_bytes bigint NOT NULL DEFAULT 0,
  width integer,
  height integer,
  tags text[] NOT NULL DEFAULT '{}',
  uploaded_by uuid REFERENCES cms_profiles(id),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_cms_media_station_created ON cms_media(station_id, created_at DESC);
CREATE INDEX idx_cms_media_station_mime ON cms_media(station_id, mime_type);
CREATE INDEX idx_cms_media_tags ON cms_media USING GIN (tags);

-- ============================================================
-- cms_flags — Lightweight bug/issue reporting
-- ============================================================
CREATE TABLE IF NOT EXISTS cms_flags (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  station_id uuid NOT NULL REFERENCES cms_stations(id),
  reporter_id uuid REFERENCES cms_profiles(id),
  url text NOT NULL,
  message text,
  user_agent text,
  status text NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'resolved', 'dismissed')),
  resolved_by uuid REFERENCES cms_profiles(id),
  resolved_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_cms_flags_station_status ON cms_flags(station_id, status);
CREATE INDEX idx_cms_flags_station_created ON cms_flags(station_id, created_at DESC);

-- ============================================================
-- cms_audit_log — Field-level change tracking
-- ============================================================
CREATE TABLE IF NOT EXISTS cms_audit_log (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  station_id uuid NOT NULL REFERENCES cms_stations(id),
  user_id uuid,
  action text NOT NULL CHECK (action IN ('create', 'update', 'delete')),
  table_name text NOT NULL,
  record_id uuid,
  old_data jsonb,
  new_data jsonb,
  ip_address inet,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX idx_cms_audit_log_table_record ON cms_audit_log(table_name, record_id);
CREATE INDEX idx_cms_audit_log_user_created ON cms_audit_log(user_id, created_at DESC);
CREATE INDEX idx_cms_audit_log_table_created ON cms_audit_log(table_name, created_at DESC);
