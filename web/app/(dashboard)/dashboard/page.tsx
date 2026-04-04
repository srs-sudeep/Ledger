import { createClient } from "@/lib/supabase/server";
import { SummaryCards } from "./summary-cards";
import { SpendingChart } from "./spending-chart";
import { RecentTransactions } from "./recent-transactions";
import { ActiveGroups } from "./active-groups";
import { PendingSettlements } from "./pending-settlements";
import { InsightCard } from "./insight-card";
import { AccountsOverview } from "./accounts-overview";
import type { Group, Settlement, Account } from "@/lib/types";

export default async function DashboardPage() {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) return null;

  // Fetch personal expenses for current month
  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1)
    .toISOString()
    .split("T")[0];
  const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0)
    .toISOString()
    .split("T")[0];

  const [
    { data: personalExpenses },
    { data: recentExpenses },
    { data: groups },
    { data: owedToMe },
    { data: iOwe },
    { data: pendingSettlements },
    { data: userAccounts },
  ] = await Promise.all([
    supabase
      .from("expenses")
      .select("amount")
      .eq("payer_id", user.id)
      .is("group_id", null)
      .gte("date", startOfMonth)
      .lte("date", endOfMonth),
    supabase
      .from("expenses")
      .select("*, categories(*), profiles!expenses_payer_id_fkey(*)")
      .or(`payer_id.eq.${user.id},group_id.not.is.null`)
      .order("date", { ascending: false })
      .limit(5),
    supabase
      .from("group_members")
      .select("group_id, groups(*)")
      .eq("user_id", user.id)
      .limit(5),
    supabase
      .from("expense_splits")
      .select("owed_amount, expenses!inner(payer_id, group_id)")
      .neq("user_id", user.id)
      .filter("expenses.payer_id", "eq", user.id),
    supabase
      .from("expense_splits")
      .select("owed_amount, expenses!inner(payer_id)")
      .eq("user_id", user.id)
      .neq("expenses.payer_id", user.id),
    supabase
      .from("settlements")
      .select(
        "*, from_profile:profiles!settlements_from_user_id_fkey(*), to_profile:profiles!settlements_to_user_id_fkey(*)"
      )
      .or(`from_user_id.eq.${user.id},to_user_id.eq.${user.id}`)
      .eq("status", "pending")
      .limit(5),
    supabase
      .from("accounts")
      .select("*")
      .eq("user_id", user.id)
      .order("is_default", { ascending: false })
      .limit(4),
  ]);

  const monthlySpend = (personalExpenses || []).reduce(
    (sum, e) => sum + e.amount,
    0
  );
  const totalOwedToMe = (owedToMe || []).reduce(
    (sum, s) => sum + s.owed_amount,
    0
  );
  const totalIOwe = (iOwe || []).reduce((sum, s) => sum + s.owed_amount, 0);
  const netWorth = totalOwedToMe - totalIOwe;

  // Compute weekly spending for the bar chart
  const weeklyData = Array.from({ length: 7 }, (_, i) => {
    const d = new Date();
    d.setDate(d.getDate() - (6 - i));
    const dayStr = d.toISOString().split("T")[0];
    const dayExpenses = (recentExpenses || [])
      .filter((e) => e.date === dayStr && !e.group_id)
      .reduce((sum, e) => sum + e.amount, 0);
    return {
      day: d.toLocaleDateString("en-US", { weekday: "short" }),
      amount: dayExpenses,
    };
  });

  return (
    <div className="space-y-8">
      <SummaryCards
        netWorth={netWorth}
        owedToMe={totalOwedToMe}
        iOwe={totalIOwe}
        monthlySpend={monthlySpend}
      />

      <div className="grid grid-cols-12 gap-8">
        <div className="col-span-12 lg:col-span-7 space-y-8">
          <SpendingChart data={weeklyData} />
          <RecentTransactions
            expenses={recentExpenses || []}
            userId={user.id}
          />
        </div>

        <div className="col-span-12 lg:col-span-5 space-y-8">
          <AccountsOverview
            accounts={(userAccounts || []) as Account[]}
          />
          <ActiveGroups
            groups={(groups || []).map((g) => g.groups as unknown as Group).filter(Boolean)}
          />
          <PendingSettlements
            settlements={(pendingSettlements || []) as unknown as Settlement[]}
            userId={user.id}
          />
          <InsightCard />
        </div>
      </div>
    </div>
  );
}
