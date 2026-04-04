-- ============================================================
-- Migration 00005: Default currency JPY for new rows
-- ============================================================
-- Existing rows keep their stored currency; only column DEFAULTs
-- change so new signups and new records use yen unless overridden.

ALTER TABLE public.profiles
  ALTER COLUMN default_currency SET DEFAULT 'JPY';

ALTER TABLE public.groups
  ALTER COLUMN currency SET DEFAULT 'JPY';

ALTER TABLE public.settlements
  ALTER COLUMN currency SET DEFAULT 'JPY';

ALTER TABLE public.income
  ALTER COLUMN currency SET DEFAULT 'JPY';

ALTER TABLE public.expenses
  ALTER COLUMN currency SET DEFAULT 'JPY';

ALTER TABLE public.accounts
  ALTER COLUMN currency SET DEFAULT 'JPY';
