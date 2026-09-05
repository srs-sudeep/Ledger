-- Ledger schema baseline v0.1

CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TYPE group_type AS ENUM ('trip', 'home', 'custom');
CREATE TYPE group_role AS ENUM ('admin', 'member');
CREATE TYPE split_type AS ENUM ('equal', 'exact', 'percentage');
CREATE TYPE settlement_status AS ENUM ('pending', 'completed');
CREATE TYPE account_type AS ENUM ('bank', 'credit_card', 'debit_card', 'wallet', 'cash', 'other');
CREATE TYPE invitation_status AS ENUM ('pending', 'accepted', 'declined');

CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  email TEXT NOT NULL UNIQUE,
  password_hash TEXT,
  google_id TEXT UNIQUE,
  email_verified BOOLEAN NOT NULL DEFAULT true,
  full_name TEXT,
  phone_primary TEXT,
  phone_secondary TEXT,
  avatar_url TEXT,
  default_currency TEXT NOT NULL DEFAULT 'JPY',
  is_superuser BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT users_auth_method CHECK (password_hash IS NOT NULL OR google_id IS NOT NULL)
);

CREATE TABLE IF NOT EXISTS categories (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL UNIQUE,
  icon TEXT NOT NULL,
  color TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS groups (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  type group_type NOT NULL DEFAULT 'custom',
  currency TEXT NOT NULL DEFAULT 'JPY',
  created_by UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS group_members (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role group_role NOT NULL DEFAULT 'member',
  joined_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (group_id, user_id)
);

CREATE TABLE IF NOT EXISTS accounts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  type account_type NOT NULL DEFAULT 'bank',
  balance INTEGER NOT NULL DEFAULT 0,
  currency TEXT NOT NULL DEFAULT 'JPY',
  icon TEXT,
  color TEXT,
  is_default BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS income (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  account_id UUID REFERENCES accounts(id) ON DELETE SET NULL,
  amount INTEGER NOT NULL CHECK (amount > 0),
  currency TEXT NOT NULL DEFAULT 'JPY',
  source TEXT NOT NULL,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS transfers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  from_account_id UUID REFERENCES accounts(id) ON DELETE SET NULL,
  to_account_id UUID REFERENCES accounts(id) ON DELETE SET NULL,
  amount INTEGER NOT NULL CHECK (amount > 0),
  currency TEXT NOT NULL DEFAULT 'JPY',
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  kind TEXT,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CONSTRAINT transfers_accounts_differ CHECK (
    from_account_id IS NULL OR to_account_id IS NULL OR from_account_id <> to_account_id
  )
);

CREATE TABLE IF NOT EXISTS expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  amount INTEGER NOT NULL CHECK (amount > 0),
  currency TEXT NOT NULL DEFAULT 'JPY',
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  date DATE NOT NULL DEFAULT CURRENT_DATE,
  payer_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  group_id UUID REFERENCES groups(id) ON DELETE CASCADE,
  account_id UUID REFERENCES accounts(id) ON DELETE SET NULL,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS expense_splits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  expense_id UUID NOT NULL REFERENCES expenses(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  owed_amount INTEGER NOT NULL CHECK (owed_amount >= 0),
  split_type split_type NOT NULL DEFAULT 'equal',
  UNIQUE (expense_id, user_id)
);

CREATE TABLE IF NOT EXISTS settlements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  to_user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL CHECK (amount > 0),
  currency TEXT NOT NULL DEFAULT 'JPY',
  group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  status settlement_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  settled_at TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS group_invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id UUID NOT NULL REFERENCES groups(id) ON DELETE CASCADE,
  inviter_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  invitee_email TEXT NOT NULL,
  invitee_user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  status invitation_status NOT NULL DEFAULT 'pending',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (group_id, invitee_email, status)
);

CREATE INDEX IF NOT EXISTS idx_expenses_payer_id ON expenses(payer_id);
CREATE INDEX IF NOT EXISTS idx_expenses_group_id ON expenses(group_id);
CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date DESC);
CREATE INDEX IF NOT EXISTS idx_transfers_user_id ON transfers(user_id);
CREATE INDEX IF NOT EXISTS idx_transfers_date ON transfers(date DESC);
CREATE INDEX IF NOT EXISTS idx_group_members_group_id ON group_members(group_id);
CREATE INDEX IF NOT EXISTS idx_group_members_user_id ON group_members(user_id);
CREATE INDEX IF NOT EXISTS idx_accounts_user_id ON accounts(user_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

CREATE TABLE IF NOT EXISTS budgets (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  category_id UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL CHECK (amount > 0),
  month TEXT NOT NULL,
  currency TEXT NOT NULL DEFAULT 'JPY',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, category_id, month)
);

CREATE TABLE IF NOT EXISTS recurring_expenses (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  amount INTEGER NOT NULL CHECK (amount > 0),
  currency TEXT NOT NULL DEFAULT 'JPY',
  category_id UUID REFERENCES categories(id) ON DELETE SET NULL,
  account_id UUID REFERENCES accounts(id) ON DELETE SET NULL,
  frequency TEXT NOT NULL DEFAULT 'monthly',
  next_due DATE NOT NULL,
  notes TEXT,
  auto_create BOOLEAN NOT NULL DEFAULT false,
  active BOOLEAN NOT NULL DEFAULT true,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_budgets_user_month ON budgets(user_id, month);
CREATE INDEX IF NOT EXISTS idx_recurring_user ON recurring_expenses(user_id);

INSERT INTO categories (name, icon, color) VALUES
  ('Groceries',      'shopping_basket',   '#4CAF50'),
  ('Dining',         'restaurant',        '#FF9800'),
  ('Transport',      'directions_car',    '#2196F3'),
  ('Entertainment',  'movie',             '#9C27B0'),
  ('Shopping',       'shopping_bag',      '#E91E63'),
  ('Utilities',      'bolt',              '#FF5722'),
  ('Rent',           'home',              '#607D8B'),
  ('Healthcare',     'local_hospital',    '#00BCD4'),
  ('Education',      'school',            '#3F51B5'),
  ('Travel',         'flight',            '#009688'),
  ('Subscriptions',  'subscriptions',     '#795548'),
  ('Coffee',         'local_cafe',        '#8D6E63'),
  ('Fuel',           'local_gas_station', '#FF6F00'),
  ('Fitness',        'fitness_center',    '#E040FB'),
  ('Gifts',          'redeem',            '#F44336'),
  ('Insurance',      'shield',            '#546E7A'),
  ('Investments',    'trending_up',       '#00C853'),
  ('Other',          'category',          '#9E9E9E')
ON CONFLICT (name) DO NOTHING;
