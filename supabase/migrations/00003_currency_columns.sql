-- ============================================================
-- Migration 00003: Group / settlement / income currency
-- ============================================================
-- Aligns with profiles.default_currency and expenses.currency.
-- Run after 00002 (accounts + income exist).

-- Group ledger currency (new expenses inherit in app via group.currency)
ALTER TABLE public.groups
  ADD COLUMN IF NOT EXISTS currency TEXT NOT NULL DEFAULT 'USD';

-- Settlements match their group's currency
ALTER TABLE public.settlements
  ADD COLUMN IF NOT EXISTS currency TEXT NOT NULL DEFAULT 'USD';

UPDATE public.settlements s
SET currency = COALESCE(g.currency, 'USD')
FROM public.groups g
WHERE s.group_id = g.id;

-- Income rows follow account when present, else default
ALTER TABLE public.income
  ADD COLUMN IF NOT EXISTS currency TEXT NOT NULL DEFAULT 'USD';

UPDATE public.income i
SET currency = COALESCE(a.currency, 'USD')
FROM public.accounts a
WHERE i.account_id = a.id;

-- Rows with no linked account keep USD default from column
