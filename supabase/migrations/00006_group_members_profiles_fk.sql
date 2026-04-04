-- ============================================================
-- Migration 00006: FK group_members.user_id -> profiles(id)
-- ============================================================
-- PostgREST only auto-embeds relations when a foreign key exists between
-- the tables. Previously user_id referenced auth.users only, so
-- .select("*, profiles(*)") on group_members did not resolve and members
-- appeared empty in the app. Pointing at public.profiles keeps the same
-- semantics (profile id == auth user id) and enables optional embeds.

ALTER TABLE public.group_members
  DROP CONSTRAINT IF EXISTS group_members_user_id_fkey;

ALTER TABLE public.group_members
  ADD CONSTRAINT group_members_user_id_fkey
  FOREIGN KEY (user_id)
  REFERENCES public.profiles(id)
  ON DELETE CASCADE;
