-- Run once on existing databases: docker exec -i ledger-dev-db-1 psql -U ledger -d ledger < backend/migrations/001_users_oauth.sql

ALTER TABLE users ALTER COLUMN password_hash DROP NOT NULL;
ALTER TABLE users ADD COLUMN IF NOT EXISTS google_id TEXT UNIQUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS email_verified BOOLEAN NOT NULL DEFAULT true;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'users_auth_method'
  ) THEN
    ALTER TABLE users ADD CONSTRAINT users_auth_method
      CHECK (password_hash IS NOT NULL OR google_id IS NOT NULL);
  END IF;
END $$;
