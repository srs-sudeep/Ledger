-- ============================================================
-- Migration 00007: Backfill existing USD rows to JPY
-- ============================================================
-- New defaults are already JPY (00005). This updates legacy rows
-- still stored as USD so UI labels (e.g. "Amount (USD)") match the
-- product default of yen everywhere.

UPDATE public.profiles
SET default_currency = 'JPY'
WHERE default_currency = 'USD';

UPDATE public.groups
SET currency = 'JPY'
WHERE currency = 'USD';

UPDATE public.accounts
SET currency = 'JPY'
WHERE currency = 'USD';

UPDATE public.expenses
SET currency = 'JPY'
WHERE currency = 'USD';

UPDATE public.income
SET currency = 'JPY'
WHERE currency = 'USD';

UPDATE public.settlements
SET currency = 'JPY'
WHERE currency = 'USD';
