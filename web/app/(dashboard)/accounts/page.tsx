import { createClient } from "@/lib/supabase/server";
import type { Account, Income } from "@/lib/types";
import { AccountCard } from "./account-card";
import { AddAccountButton } from "./add-account-button";
import { AddIncomeButton } from "./add-income-button";
import { formatCents } from "@/lib/utils";

export default async function AccountsPage() {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) return null;

  const [{ data: accounts }, { data: recentIncome }] = await Promise.all([
    supabase
      .from("accounts")
      .select("*")
      .eq("user_id", user.id)
      .order("is_default", { ascending: false })
      .order("created_at", { ascending: false }),
    supabase
      .from("income")
      .select("*")
      .eq("user_id", user.id)
      .order("date", { ascending: false })
      .limit(10),
  ]);

  const typedAccounts = (accounts || []) as Account[];
  const typedIncome = (recentIncome || []) as Income[];
  const totalBalance = typedAccounts.reduce((sum, a) => sum + a.balance, 0);

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold font-headline text-on-surface">
            Accounts
          </h1>
          <p className="text-sm text-secondary mt-1">
            Total balance:{" "}
            <span className="font-semibold text-on-surface tabular-nums">
              {formatCents(totalBalance)}
            </span>
          </p>
        </div>
        <div className="flex gap-3">
          <AddIncomeButton accounts={typedAccounts} userId={user.id} />
          <AddAccountButton userId={user.id} />
        </div>
      </div>

      {typedAccounts.length === 0 ? (
        <div className="text-center py-20 text-secondary">
          <p className="text-lg font-medium">No accounts yet</p>
          <p className="text-sm mt-1">
            Add a bank account, credit card, or wallet to start tracking.
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-6">
          {typedAccounts.map((account) => (
            <AccountCard key={account.id} account={account} />
          ))}
        </div>
      )}

      {typedIncome.length > 0 && (
        <div className="space-y-4">
          <h2 className="text-lg font-bold font-headline text-on-surface">
            Recent Income
          </h2>
          <div className="bg-surface-container-lowest rounded-xl shadow-ambient p-8">
            <div className="space-y-3">
              {typedIncome.map((inc) => (
                <div
                  key={inc.id}
                  className="flex items-center justify-between py-2"
                >
                  <div>
                    <p className="text-sm font-semibold text-on-surface">
                      {inc.source}
                    </p>
                    <p className="text-xs text-secondary">
                      {new Date(inc.date).toLocaleDateString("en-US", {
                        month: "short",
                        day: "numeric",
                        year: "numeric",
                      })}
                    </p>
                  </div>
                  <span className="text-sm font-semibold text-green-600 tabular-nums">
                    +{formatCents(inc.amount)}
                  </span>
                </div>
              ))}
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
