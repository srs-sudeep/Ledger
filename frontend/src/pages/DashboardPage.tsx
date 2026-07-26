import { useEffect, useState } from "react";
import { api } from "@/api/client";
import { formatCents } from "@/lib/utils";
import { Card, CardTitle } from "@/components/ui/card";
import type { Expense, Settlement } from "@/lib/types";

interface DashboardSummary {
  net_worth: number;
  group_net: number;
  owed_to_me: number;
  i_owe: number;
  monthly_spend: number;
}

export function DashboardPage() {
  const [summary, setSummary] = useState<DashboardSummary | null>(null);
  const [recent, setRecent] = useState<Expense[]>([]);
  const [settlements, setSettlements] = useState<Settlement[]>([]);

  useEffect(() => {
    api<DashboardSummary>("/api/dashboard/summary").then(setSummary);
    api<Expense[]>("/api/expenses?limit=5").then(setRecent);
    api<Settlement[]>("/api/dashboard/settlements/pending").then(setSettlements);
  }, []);

  return (
    <div className="space-y-8">
      <h1 className="text-2xl font-headline font-bold">Dashboard</h1>
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-5 gap-4">
        {[
          { label: "Net worth", value: summary?.net_worth ?? 0 },
          { label: "Group net", value: summary?.group_net ?? 0 },
          { label: "Owed to me", value: summary?.owed_to_me ?? 0 },
          { label: "I owe", value: summary?.i_owe ?? 0 },
          { label: "Monthly spend", value: summary?.monthly_spend ?? 0 },
        ].map((c) => (
          <Card key={c.label} className="p-6">
            <p className="text-xs text-secondary uppercase tracking-wide">{c.label}</p>
            <p className="text-2xl font-bold tabular-nums mt-2">{formatCents(c.value)}</p>
          </Card>
        ))}
      </div>
      <div className="grid lg:grid-cols-2 gap-6">
        <Card className="p-6">
          <CardTitle className="mb-4">Recent transactions</CardTitle>
          <div className="space-y-3">
            {recent.map((e) => (
              <div key={e.id} className="flex justify-between text-sm">
                <span>{e.title}</span>
                <span className="tabular-nums font-semibold">
                  {formatCents(e.amount, e.currency)}
                </span>
              </div>
            ))}
            {recent.length === 0 && (
              <p className="text-secondary text-sm">No transactions yet</p>
            )}
          </div>
        </Card>
        <Card className="p-6">
          <CardTitle className="mb-4">Pending settlements</CardTitle>
          <div className="space-y-3">
            {settlements.map((s) => (
              <div key={s.id} className="text-sm flex justify-between gap-2">
                <span>
                  {s.from_profile?.full_name ?? "Someone"} →{" "}
                  {s.to_profile?.full_name ?? "Someone"}
                </span>
                <span className="tabular-nums">{formatCents(s.amount, s.currency)}</span>
              </div>
            ))}
            {settlements.length === 0 && (
              <p className="text-secondary text-sm">All settled up</p>
            )}
          </div>
        </Card>
      </div>
    </div>
  );
}
