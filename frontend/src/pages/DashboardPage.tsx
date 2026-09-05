import { useEffect, useState } from "react";
import { ArrowRightLeft, HandCoins, Landmark, Wallet } from "lucide-react";
import { Cell, Pie, PieChart, ResponsiveContainer, Tooltip } from "recharts";
import { api } from "@/api/client";
import { formatCents } from "@/lib/utils";
import { Card, CardTitle } from "@/components/ui/card";
import { SectionHeader } from "@/components/finance/SectionHeader";
import { SummaryCard } from "@/components/finance/SummaryCard";
import type { LedgerTransaction, Settlement } from "@/lib/types";

const BALANCE_COLORS = ["#0053db", "#ef4444"];

interface DashboardSummary {
  net_worth: number;
  asset_total: number;
  liability_total: number;
  group_net: number;
  owed_to_me: number;
  i_owe: number;
  monthly_spend: number;
}

export function DashboardPage() {
  const [summary, setSummary] = useState<DashboardSummary | null>(null);
  const [recent, setRecent] = useState<LedgerTransaction[]>([]);
  const [settlements, setSettlements] = useState<Settlement[]>([]);

  useEffect(() => {
    api<DashboardSummary>("/api/dashboard/summary").then(setSummary);
    api<LedgerTransaction[]>("/api/transactions?limit=20").then((rows) =>
      setRecent(rows.filter((row) => row.title !== "Balance adjustment").slice(0, 6))
    );
    api<Settlement[]>("/api/dashboard/settlements/pending").then(setSettlements);
  }, []);

  return (
    <div className="space-y-8">
      <SectionHeader
        eyebrow="Overview"
        title="Dashboard"
        description="Balance health, recent activity, and group obligations."
      />
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-4">
        <SummaryCard
          title="Net worth"
          value={summary?.net_worth ?? 0}
          tone="primary"
          emphasized
          icon={Wallet}
          subtitle={`${formatCents(summary?.asset_total ?? 0)} assets against ${formatCents(summary?.liability_total ?? 0)} liabilities`}
        />
        <SummaryCard
          title="Assets"
          value={summary?.asset_total ?? 0}
          tone="positive"
          icon={Landmark}
          subtitle="Positive balances across bank, wallet, and cash accounts"
        />
        <SummaryCard
          title="Liabilities"
          value={summary?.liability_total ?? 0}
          tone="negative"
          icon={HandCoins}
          subtitle="Outstanding card balances still to be paid"
        />
        <SummaryCard
          title="Monthly spend"
          value={summary?.monthly_spend ?? 0}
          tone="activity"
          icon={ArrowRightLeft}
          subtitle={`Group net ${formatCents(summary?.group_net ?? 0)}`}
        />
      </div>
      <div className="grid xl:grid-cols-[minmax(0,1.2fr)_360px] gap-6 items-start">
        <Card className="p-6">
          <div className="mb-4">
            <CardTitle>Recent activity</CardTitle>
            <p className="text-sm text-secondary mt-1">Latest personal ledger entries across your accounts</p>
          </div>
          <div className="space-y-3">
            {recent.map((e) => (
              <div
                key={`${e.tx_type}-${e.id}`}
                className="flex justify-between gap-3 text-sm rounded-2xl bg-surface-container-low px-4 py-3"
              >
                <div className="min-w-0">
                  <p className="truncate font-medium">{e.title}</p>
                  <p className="text-xs text-secondary mt-1">
                    {e.date} · {e.tx_type}
                    {e.account_name ? ` · ${e.account_name}` : ""}
                  </p>
                </div>
                <span
                  className={`tabular-nums font-semibold shrink-0 ${
                    e.signed_amount > 0
                      ? "text-green-700"
                      : e.signed_amount < 0
                        ? "text-red-700"
                        : ""
                  }`}
                >
                  {e.signed_amount > 0 ? "+" : e.signed_amount < 0 ? "-" : ""}
                  {formatCents(Math.abs(e.signed_amount), e.currency)}
                </span>
              </div>
            ))}
            {recent.length === 0 && (
              <p className="text-secondary text-sm">No transactions yet</p>
            )}
          </div>
        </Card>
        <div className="space-y-6">
          <Card className="p-6">
            <div className="flex items-center justify-between gap-4">
              <div>
                <CardTitle>Balance mix</CardTitle>
                <p className="text-sm text-secondary mt-1">Assets vs liabilities across your accounts</p>
              </div>
              <div className="h-28 w-28 shrink-0">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={[
                        { name: "Assets", value: summary?.asset_total ?? 0 },
                        { name: "Liabilities", value: summary?.liability_total ?? 0 },
                      ]}
                      dataKey="value"
                      innerRadius={28}
                      outerRadius={48}
                    >
                      {BALANCE_COLORS.map((fill) => (
                        <Cell key={fill} fill={fill} />
                      ))}
                    </Pie>
                    <Tooltip formatter={(value: number) => formatCents(value)} />
                  </PieChart>
                </ResponsiveContainer>
              </div>
            </div>
            <div className="mt-4 space-y-3">
              {[
                { label: "Assets", value: summary?.asset_total ?? 0, color: BALANCE_COLORS[0] },
                {
                  label: "Liabilities",
                  value: summary?.liability_total ?? 0,
                  color: BALANCE_COLORS[1],
                },
              ].map((item) => {
                const total = (summary?.asset_total ?? 0) + (summary?.liability_total ?? 0);
                const pct = total > 0 ? Math.round((item.value / total) * 100) : 0;
                return (
                  <div key={item.label} className="space-y-1">
                    <div className="flex justify-between gap-3 text-sm">
                      <span>{item.label}</span>
                      <span className="tabular-nums">
                        {formatCents(item.value)} · {pct}%
                      </span>
                    </div>
                    <div className="h-2 rounded-full bg-surface-container overflow-hidden">
                      <div
                        className="h-full rounded-full"
                        style={{ width: `${pct}%`, backgroundColor: item.color }}
                      />
                    </div>
                  </div>
                );
              })}
            </div>
          </Card>
          <Card className="p-6">
            <div className="mb-4">
              <CardTitle>Group balances</CardTitle>
              <p className="text-sm text-secondary mt-1">
                Personal imports stay separate; these totals only come from split groups.
              </p>
            </div>
            <div className="grid grid-cols-2 gap-3 mb-4">
              <div className="rounded-2xl bg-surface-container-low px-4 py-3">
                <p className="text-xs text-secondary uppercase tracking-wide">Owed to me</p>
                <p className="tabular-nums font-semibold mt-1">{formatCents(summary?.owed_to_me ?? 0)}</p>
              </div>
              <div className="rounded-2xl bg-surface-container-low px-4 py-3">
                <p className="text-xs text-secondary uppercase tracking-wide">I owe</p>
                <p className="tabular-nums font-semibold mt-1">{formatCents(summary?.i_owe ?? 0)}</p>
              </div>
            </div>
            <div className="space-y-3">
              {settlements.map((s) => (
                <div key={s.id} className="text-sm flex justify-between gap-2 rounded-2xl bg-surface-container-low px-4 py-3">
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
    </div>
  );
}
