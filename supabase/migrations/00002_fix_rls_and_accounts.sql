-- ============================================================
-- Migration 00002: Fix RLS recursion + accounts ledger + email on profiles
-- ============================================================

-- ============================================================
-- 1. SECURITY DEFINER helpers (bypass RLS for membership checks)
-- ============================================================

CREATE OR REPLACE FUNCTION public.is_group_member(p_group_id UUID, p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.group_members
    WHERE group_id = p_group_id AND user_id = p_user_id
  );
$$;

CREATE OR REPLACE FUNCTION public.is_group_admin(p_group_id UUID, p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.group_members
    WHERE group_id = p_group_id AND user_id = p_user_id AND role = 'admin'
  );
$$;

CREATE OR REPLACE FUNCTION public.is_expense_group_member(p_expense_id UUID, p_user_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.expenses e
    JOIN public.group_members gm ON gm.group_id = e.group_id
    WHERE e.id = p_expense_id AND gm.user_id = p_user_id
  );
$$;

CREATE OR REPLACE FUNCTION public.group_has_no_members(p_group_id UUID)
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT NOT EXISTS (
    SELECT 1 FROM public.group_members WHERE group_id = p_group_id
  );
$$;

-- ============================================================
-- 2. Drop all recursive policies
-- ============================================================

-- group_members policies
DROP POLICY IF EXISTS "Group members can view other members"   ON public.group_members;
DROP POLICY IF EXISTS "Group admins can add members"           ON public.group_members;
DROP POLICY IF EXISTS "Group admins can remove members"        ON public.group_members;

-- groups policies
DROP POLICY IF EXISTS "Group members can view their groups"    ON public.groups;
DROP POLICY IF EXISTS "Group admins can update their groups"   ON public.groups;
DROP POLICY IF EXISTS "Group admins can delete their groups"   ON public.groups;

-- expenses policies
DROP POLICY IF EXISTS "Users can view own personal expenses"   ON public.expenses;
DROP POLICY IF EXISTS "Users can insert personal expenses"     ON public.expenses;
DROP POLICY IF EXISTS "Users can update own personal expenses" ON public.expenses;

-- expense_splits policies
DROP POLICY IF EXISTS "Users can view splits for their group expenses" ON public.expense_splits;
DROP POLICY IF EXISTS "Group members can insert splits"                ON public.expense_splits;

-- settlements policies
DROP POLICY IF EXISTS "Group members can create settlements"   ON public.settlements;

-- ============================================================
-- 3. Recreate policies using helper functions
-- ============================================================

-- ---- group_members ----

CREATE POLICY "Group members can view other members"
  ON public.group_members FOR SELECT
  USING (public.is_group_member(group_id, auth.uid()));

CREATE POLICY "Group admins can add members"
  ON public.group_members FOR INSERT
  TO authenticated
  WITH CHECK (
    public.is_group_admin(group_id, auth.uid())
    OR
    (auth.uid() = user_id AND role = 'admin' AND public.group_has_no_members(group_id))
  );

CREATE POLICY "Group admins can remove members"
  ON public.group_members FOR DELETE
  USING (public.is_group_admin(group_id, auth.uid()));

-- ---- groups ----

CREATE POLICY "Group members can view their groups"
  ON public.groups FOR SELECT
  USING (public.is_group_member(id, auth.uid()));

CREATE POLICY "Group admins can update their groups"
  ON public.groups FOR UPDATE
  USING (public.is_group_admin(id, auth.uid()));

CREATE POLICY "Group admins can delete their groups"
  ON public.groups FOR DELETE
  USING (public.is_group_admin(id, auth.uid()));

-- ---- expenses ----

CREATE POLICY "Users can view own personal expenses"
  ON public.expenses FOR SELECT
  USING (
    (group_id IS NULL AND payer_id = auth.uid())
    OR
    (group_id IS NOT NULL AND public.is_group_member(group_id, auth.uid()))
  );

CREATE POLICY "Users can insert personal expenses"
  ON public.expenses FOR INSERT
  TO authenticated
  WITH CHECK (
    (group_id IS NULL AND payer_id = auth.uid())
    OR
    (group_id IS NOT NULL AND public.is_group_member(group_id, auth.uid()))
  );

CREATE POLICY "Users can update own personal expenses"
  ON public.expenses FOR UPDATE
  USING (
    (group_id IS NULL AND payer_id = auth.uid())
    OR
    (group_id IS NOT NULL AND payer_id = auth.uid() AND public.is_group_member(group_id, auth.uid()))
  );

-- ---- expense_splits ----

CREATE POLICY "Users can view splits for their group expenses"
  ON public.expense_splits FOR SELECT
  USING (public.is_expense_group_member(expense_id, auth.uid()));

CREATE POLICY "Group members can insert splits"
  ON public.expense_splits FOR INSERT
  TO authenticated
  WITH CHECK (public.is_expense_group_member(expense_id, auth.uid()));

-- ---- settlements ----

CREATE POLICY "Group members can create settlements"
  ON public.settlements FOR INSERT
  TO authenticated
  WITH CHECK (
    from_user_id = auth.uid()
    AND public.is_group_member(group_id, auth.uid())
  );

-- ============================================================
-- 4. Add email column to profiles + update trigger
-- ============================================================

ALTER TABLE public.profiles ADD COLUMN IF NOT EXISTS email TEXT;

CREATE INDEX IF NOT EXISTS idx_profiles_email ON public.profiles(email);

-- Allow group members to look up other profiles (for invite-by-email)
DROP POLICY IF EXISTS "Users can view own profile" ON public.profiles;
CREATE POLICY "Users can view own profile"
  ON public.profiles FOR SELECT
  USING (true);

-- Backfill existing profiles with email from auth.users
UPDATE public.profiles p
SET email = u.email
FROM auth.users u
WHERE u.id = p.id AND p.email IS NULL;

-- Update the trigger to include email
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, full_name, avatar_url, email)
  VALUES (
    NEW.id,
    COALESCE(NEW.raw_user_meta_data->>'full_name', NEW.raw_user_meta_data->>'name', ''),
    COALESCE(NEW.raw_user_meta_data->>'avatar_url', NEW.raw_user_meta_data->>'picture', ''),
    NEW.email
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 5. Accounts ledger
-- ============================================================

CREATE TYPE account_type AS ENUM ('bank', 'credit_card', 'debit_card', 'wallet', 'cash', 'other');

CREATE TABLE public.accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type account_type NOT NULL DEFAULT 'bank',
  balance INTEGER NOT NULL DEFAULT 0,
  currency TEXT NOT NULL DEFAULT 'USD',
  icon TEXT,
  color TEXT,
  is_default BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.accounts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own accounts"
  ON public.accounts FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own accounts"
  ON public.accounts FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own accounts"
  ON public.accounts FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "Users can delete own accounts"
  ON public.accounts FOR DELETE
  USING (user_id = auth.uid());

CREATE INDEX idx_accounts_user_id ON public.accounts(user_id);

-- ============================================================
-- 6. Income table
-- ============================================================

CREATE TABLE public.income (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  account_id UUID REFERENCES public.accounts(id) ON DELETE SET NULL,
  amount INTEGER NOT NULL CHECK (amount > 0),
  source TEXT NOT NULL,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.income ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view own income"
  ON public.income FOR SELECT
  USING (user_id = auth.uid());

CREATE POLICY "Users can insert own income"
  ON public.income FOR INSERT
  TO authenticated
  WITH CHECK (user_id = auth.uid());

CREATE POLICY "Users can update own income"
  ON public.income FOR UPDATE
  USING (user_id = auth.uid());

CREATE POLICY "Users can delete own income"
  ON public.income FOR DELETE
  USING (user_id = auth.uid());

CREATE INDEX idx_income_user_id ON public.income(user_id);
CREATE INDEX idx_income_account_id ON public.income(account_id);
CREATE INDEX idx_income_date ON public.income(date DESC);

-- ============================================================
-- 7. Add account_id to expenses
-- ============================================================

ALTER TABLE public.expenses
  ADD COLUMN IF NOT EXISTS account_id UUID REFERENCES public.accounts(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_expenses_account_id ON public.expenses(account_id);
