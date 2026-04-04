export interface Profile {
  id: string;
  full_name: string | null;
  avatar_url: string | null;
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
  notes: string | null;
  created_at: string;
  categories?: Category;
  profiles?: Profile;
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
