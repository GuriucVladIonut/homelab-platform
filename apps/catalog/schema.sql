CREATE TABLE media (
  id uuid PRIMARY KEY,
  media_type text NOT NULL,
  title text NOT NULL,
  canonical_path text NOT NULL,
  filename text NOT NULL,
  mime_type text,
  size_bytes bigint NOT NULL CHECK (size_bytes >= 0),
  sha256 text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  ingested_at timestamptz,
  source text NOT NULL,
  tags jsonb NOT NULL DEFAULT '[]',
  description text,
  status text NOT NULL,
  UNIQUE (sha256)
);
CREATE TABLE media_audit (id bigserial PRIMARY KEY, media_id uuid NOT NULL, action text NOT NULL, actor text NOT NULL, changed_at timestamptz NOT NULL DEFAULT now(), before_state jsonb, after_state jsonb);
