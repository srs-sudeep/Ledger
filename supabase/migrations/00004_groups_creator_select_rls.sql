-- ============================================================
-- Migration 00004: Let group creators read new rows (INSERT RETURNING)
-- ============================================================
-- Problem: SELECT on groups only allowed is_group_member(id, auth.uid()).
-- Create flow uses .insert(...).select().single() before group_members exists,
-- so RETURNING failed RLS and surfaced as "new row violates row-level security".
-- Fix: allow SELECT when created_by = auth.uid() (bootstrap path).

DROP POLICY IF EXISTS "Group members can view their groups" ON public.groups;

CREATE POLICY "Group members can view their groups"
  ON public.groups FOR SELECT
  USING (
    public.is_group_member(id, auth.uid())
    OR created_by = auth.uid()
  );

-- Ensure INSERT policy exists (safe if already applied from 00001)
DROP POLICY IF EXISTS "Authenticated users can create groups" ON public.groups;

CREATE POLICY "Authenticated users can create groups"
  ON public.groups FOR INSERT
  TO authenticated
  WITH CHECK (auth.uid() = created_by);
