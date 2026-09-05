export interface Profile {
  id: string;
  full_name: string | null;
  phone_primary: string | null;
  phone_secondary: string | null;
  avatar_url: string | null;
  email: string | null;
  default_currency: string;
  created_at: string;
  updated_at: string;
}

export interface Category {
  id: string;
  name: string;
  icon: string;
  color: string | null;
}

export type GroupType = "trip" | "home" | "custom";
export type GroupRole = "admin" | "member";
export type SplitType = "equal" | "exact" | "percentage";
export type SettlementStatus = "pending" | "completed";

export interface Group {
  id: string;
  name: string;
  type: GroupType;
  currency: string;
  created_by: string;
  created_at: string;
}

export interface GroupMember {
  id: string;
  group_id: string;
  user_id: string;
  role: GroupRole;
  joined_at: string;
  profiles?: Profile;
}

export interface Expense {
  id: string;
  title: string;
  amount: number;
  currency: string;
  category_id: string | null;
  date: string;
  payer_id: string;
  group_id: string | null;
  account_id: string | null;
  notes: string | null;
  created_at: string;
  categories?: Category;
  profiles?: Profile;
  accounts?: Account;
}

export interface ExpenseSplit {
  id: string;
  expense_id: string;
  user_id: string;
  owed_amount: number;
  split_type: SplitType;
  profiles?: Profile;
}

export interface Settlement {
  id: string;
  from_user_id: string;
  to_user_id: string;
  amount: number;
  currency: string;
  group_id: string;
  status: SettlementStatus;
  created_at: string;
  settled_at: string | null;
  from_profile?: Profile;
  to_profile?: Profile;
}

export interface SimplifiedTransaction {
  from: string;
  to: string;
  amount: number;
}

export interface DebtSimplifierResponse {
  transactions: SimplifiedTransaction[];
  balances: Record<string, number>;
}

export interface GroupWithBalance extends Group {
  memberCount: number;
  userBalance: number;
}

// Accounts ledger
export type AccountType = "bank" | "credit_card" | "debit_card" | "wallet" | "cash" | "other";

export interface Account {
  id: string;
  user_id: string;
  name: string;
  type: AccountType;
  balance: number;
  currency: string;
  icon: string | null;
  color: string | null;
  is_default: boolean;
  created_at: string;
  updated_at: string;
}

export interface Income {
  id: string;
  user_id: string;
  account_id: string | null;
  amount: number;
  currency: string;
  source: string;
  date: string;
  notes: string | null;
  created_at: string;
}

export interface Transfer {
  id: string;
  user_id: string;
  from_account_id: string | null;
  to_account_id: string | null;
  amount: number;
  currency: string;
  date: string;
  kind: string | null;
  notes: string | null;
  created_at: string;
}

export type LedgerTransactionType = "expense" | "income" | "transfer";
export type LedgerTransactionDirection = "inflow" | "outflow" | "transfer";

export interface LedgerTransaction {
  id: string;
  tx_type: LedgerTransactionType;
  direction: LedgerTransactionDirection;
  amount: number;
  signed_amount: number;
  currency: string;
  title: string;
  merchant_original: string | null;
  merchant_display: string | null;
  date: string;
  created_at: string;
  category_id: string | null;
  category_name: string | null;
  account_id: string | null;
  account_name: string | null;
  counterparty_account_id: string | null;
  counterparty_account_name: string | null;
  notes: string | null;
}

export interface LedgerTransactionSummary {
  transaction_count: number;
  income_total: number;
  expense_total: number;
  transfer_in_total: number;
  transfer_out_total: number;
  net_flow: number;
  top_categories: {
    category_id: string | null;
    category_name: string;
    color: string | null;
    total: number;
  }[];
  top_merchants: { name: string; total: number }[];
}
