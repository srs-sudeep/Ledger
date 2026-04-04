import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

interface SimplifiedTransaction {
  from: string;
  to: string;
  amount: number;
}

interface NetBalance {
  userId: string;
  balance: number; // positive = owed money (creditor), negative = owes money (debtor)
}

function simplifyDebts(balances: NetBalance[]): SimplifiedTransaction[] {
  const creditors: NetBalance[] = [];
  const debtors: NetBalance[] = [];

  for (const b of balances) {
    if (b.balance > 0) creditors.push({ ...b });
    else if (b.balance < 0) debtors.push({ ...b, balance: Math.abs(b.balance) });
  }

  creditors.sort((a, b) => b.balance - a.balance);
  debtors.sort((a, b) => b.balance - a.balance);

  const transactions: SimplifiedTransaction[] = [];
  let i = 0;
  let j = 0;

  while (i < debtors.length && j < creditors.length) {
    const transferAmount = Math.min(debtors[i].balance, creditors[j].balance);

    if (transferAmount > 0) {
      transactions.push({
        from: debtors[i].userId,
        to: creditors[j].userId,
        amount: transferAmount,
      });
    }

    debtors[i].balance -= transferAmount;
    creditors[j].balance -= transferAmount;

    if (debtors[i].balance === 0) i++;
    if (creditors[j].balance === 0) j++;
  }

  return transactions;
}

serve(async (req) => {
  const corsHeaders = {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers":
      "authorization, x-client-info, apikey, content-type",
  };

  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { group_id } = await req.json();

    if (!group_id) {
      return new Response(
        JSON.stringify({ error: "group_id is required" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseKey);

    // Fetch all expenses for this group with their splits
    const { data: expenses, error: expError } = await supabase
      .from("expenses")
      .select("id, amount, payer_id")
      .eq("group_id", group_id);

    if (expError) throw expError;

    const expenseIds = (expenses || []).map((e: { id: string }) => e.id);

    if (expenseIds.length === 0) {
      return new Response(
        JSON.stringify({ transactions: [], balances: {} }),
        { headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const { data: splits, error: splitError } = await supabase
      .from("expense_splits")
      .select("expense_id, user_id, owed_amount")
      .in("expense_id", expenseIds);

    if (splitError) throw splitError;

    // Fetch completed settlements to subtract from balances
    const { data: settlements, error: settleError } = await supabase
      .from("settlements")
      .select("from_user_id, to_user_id, amount")
      .eq("group_id", group_id)
      .eq("status", "completed");

    if (settleError) throw settleError;

    // Build net balance map: positive = others owe you, negative = you owe others
    const balanceMap: Record<string, number> = {};

    const ensure = (uid: string) => {
      if (!(uid in balanceMap)) balanceMap[uid] = 0;
    };

    // For each expense, the payer is owed the total split amounts by others
    const expenseMap = new Map(
      (expenses || []).map((e: { id: string; payer_id: string }) => [e.id, e.payer_id])
    );

    for (const split of splits || []) {
      const payerId = expenseMap.get(split.expense_id)!;
      ensure(payerId);
      ensure(split.user_id);

      if (split.user_id !== payerId) {
        // payer is owed this amount
        balanceMap[payerId] += split.owed_amount;
        // split user owes this amount
        balanceMap[split.user_id] -= split.owed_amount;
      }
    }

    // Subtract completed settlements
    for (const s of settlements || []) {
      ensure(s.from_user_id);
      ensure(s.to_user_id);
      balanceMap[s.from_user_id] += s.amount; // paid off debt
      balanceMap[s.to_user_id] -= s.amount;   // received payment
    }

    const netBalances: NetBalance[] = Object.entries(balanceMap)
      .filter(([, balance]) => Math.abs(balance) > 0)
      .map(([userId, balance]) => ({ userId, balance }));

    const transactions = simplifyDebts(netBalances);

    return new Response(
      JSON.stringify({
        transactions,
        balances: balanceMap,
      }),
      { headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (err) {
    return new Response(
      JSON.stringify({ error: (err as Error).message }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
