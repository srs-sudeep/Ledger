import { useEffect, useState } from "react";
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Legend,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { api } from "@/api/client";
import { formatAxisCents, formatCents } from "@/lib/utils";
import { Card, CardTitle } from "@/components/ui/card";
import { SectionHeader } from "@/components/finance/SectionHeader";
import { SummaryCard } from "@/components/finance/SummaryCard";
import type { Account, LedgerTransaction, LedgerTransactionSummary } from "@/lib/types";
import { ArrowDownCircle, ArrowUpCircle, ChartPie, Wallet } from "lucide-react";

interface AnalyticsOut {
  personal_total: number;
  group_total: number;
  by_category: {
    category_id: string | null;
    category_name: string;
    color: string | null;
    total: number;
  }[];
  by_month: { month: string; personal: number; group: number }[];
}

const FALLBACK_COLORS = ["#4CAF50", "#FF9800", "#2196F3", "#9C27B0", "#E91E63", "#607D8B"];

export function AnalyticsPage() {
  const [data, setData] = useState<AnalyticsOut | null>(null);
  const [ledgerSummary, setLedgerSummary] = useState<LedgerTransactionSummary | null>(null);
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [transactions, setTransactions] = useState<LedgerTransaction[]>([]);

  useEffect(() => {
    api<AnalyticsOut>("/api/analytics/summary?months=6").then(setData).catch(() => setData(null));
    api<LedgerTransactionSummary>("/api/transactions/summary").then(setLedgerSummary).catch(() => setLedgerSummary(null));
    api<Account[]>("/api/accounts").then(setAccounts).catch(() => setAccounts([]));
    api<LedgerTransaction[]>("/api/transactions?limit=500").then(setTransactions).catch(() => setTransactions([]));
  }, []);

  if (!data) {
    return <p className="text-secondary">Loading analytics…</p>;
  }

  const expenseByAccount = accounts
    .map((account) => ({
      name: account.name,
      total: transactions
        .filter((row) => row.tx_type === "expense" && row.account_id === account.id)
        .reduce((sum, row) => sum + row.amount, 0),
    }))
    .filter((row) => row.total > 0)
    .sort((a, b) => b.total - a.total)
    .slice(0, 6);

  const flowMix = [
    { name: "Income", value: ledgerSummary?.income_total ?? 0, color: "#00a76f" },
    { name: "Expenses", value: ledgerSummary?.expense_total ?? 0, color: "#ef4444" },
    {
      name: "Transfers",
      value: (ledgerSummary?.transfer_in_total ?? 0) + (ledgerSummary?.transfer_out_total ?? 0),
      color: "#0053db",
    },
  ].filter((row) => row.value > 0);

  return (
    <div className="space-y-8">
      <SectionHeader
        eyebrow="Breakdowns"
        title="Analytics"
        description="See how personal spending, shared costs, merchants, and transfer activity stack up."
      />
      <div className="grid md:grid-cols-2 xl:grid-cols-4 gap-4">
        <SummaryCard
          title="Personal spend"
          value={data.personal_total}
          tone="primary"
          emphasized
          icon={Wallet}
          subtitle="Last 6 months"
        />
        <SummaryCard
          title="Group spend"
          value={data.group_total}
          tone="neutral"
          icon={ChartPie}
          subtitle="Last 6 months"
        />
        <SummaryCard
          title="Ledger inflow"
          value={ledgerSummary?.income_total ?? 0}
          tone="positive"
          icon={ArrowDownCircle}
          subtitle="Across the current ledger history"
        />
        <SummaryCard
          title="Transfer volume"
          value={
            (ledgerSummary?.transfer_in_total ?? 0) + (ledgerSummary?.transfer_out_total ?? 0)
          }
          tone="activity"
          icon={ArrowUpCircle}
          subtitle="Internal movement tracked separately from spend"
        />
      </div>

      <div className="grid lg:grid-cols-2 gap-6">
        <Card className="p-6">
          <div className="mb-4">
            <CardTitle>By category</CardTitle>
            <p className="text-sm text-secondary mt-1">Personal spending share over the last 6 months</p>
          </div>
          {data.by_category.length === 0 ? (
            <p className="text-secondary text-sm">No personal spend yet</p>
          ) : (
            <div className="grid md:grid-cols-[220px_minmax(0,1fr)] gap-4 items-center">
              <div className="h-56">
                <ResponsiveContainer width="100%" height="100%">
                  <PieChart>
                    <Pie
                      data={data.by_category}
                      dataKey="total"
                      nameKey="category_name"
                      outerRadius={90}
                      innerRadius={45}
                    >
                      {data.by_category.map((c, i) => (
                        <Cell key={i} fill={c.color || FALLBACK_COLORS[i % FALLBACK_COLORS.length]} />
                      ))}
                    </Pie>
                    <Tooltip formatter={(v: number) => formatCents(v)} />
                  </PieChart>
                </ResponsiveContainer>
              </div>
              <div className="space-y-3">
                {data.by_category.map((row, index) => {
                  const total = data.by_category.reduce((sum, item) => sum + item.total, 0);
                  const pct = total > 0 ? Math.round((row.total / total) * 100) : 0;
                  return (
                    <div key={row.category_name} className="space-y-1">
                      <div className="flex justify-between gap-3 text-sm">
                        <span>{row.category_name}</span>
                        <span className="tabular-nums">
                          {formatCents(row.total)} · {pct}%
                        </span>
                      </div>
                      <div className="h-2 rounded-full bg-surface-container overflow-hidden">
                        <div
                          className="h-full rounded-full"
                          style={{
                            width: `${pct}%`,
                            backgroundColor: row.color || FALLBACK_COLORS[index % FALLBACK_COLORS.length],
                          }}
                        />
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>
          )}
        </Card>
        <Card className="p-6">
          <div className="mb-4">
            <CardTitle>Monthly burn</CardTitle>
            <p className="text-sm text-secondary mt-1">Personal vs group spending by month</p>
          </div>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={data.by_month}>
                <CartesianGrid strokeDasharray="3 3" opacity={0.3} />
                <XAxis dataKey="month" tick={{ fontSize: 11 }} />
                <YAxis tickFormatter={(v) => formatAxisCents(v)} width={64} tick={{ fontSize: 11 }} />
                <Tooltip formatter={(v: number) => formatCents(v)} />
                <Legend />
                <Bar dataKey="personal" name="Personal" fill="#0053db" radius={4} />
                <Bar dataKey="group" name="Group" fill="#9C27B0" radius={4} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </Card>
      </div>
      <div className="grid xl:grid-cols-2 2xl:grid-cols-3 gap-6">
        <Card className="p-6">
          <div className="mb-4">
            <CardTitle>Spend by account</CardTitle>
            <p className="text-sm text-secondary mt-1">Where your expense flow is actually landing</p>
          </div>
          <div className="space-y-3">
            {expenseByAccount.length ? (
              expenseByAccount.map((row, index) => {
                const total = expenseByAccount.reduce((sum, item) => sum + item.total, 0);
                const pct = total > 0 ? Math.round((row.total / total) * 100) : 0;
                return (
                  <div key={row.name} className="space-y-1">
                    <div className="flex justify-between gap-3 text-sm">
                      <span className="min-w-0 truncate">{row.name}</span>
                      <span className="tabular-nums shrink-0">
                        {formatCents(row.total)} · {pct}%
                      </span>
                    </div>
                    <div className="h-2 rounded-full bg-surface-container overflow-hidden">
                      <div
                        className="h-full rounded-full"
                        style={{
                          width: `${pct}%`,
                          backgroundColor: FALLBACK_COLORS[index % FALLBACK_COLORS.length],
                        }}
                      />
                    </div>
                  </div>
                );
              })
            ) : (
              <p className="text-secondary text-sm">No account-level expense data yet</p>
            )}
          </div>
        </Card>
        <Card className="p-6">
          <div className="mb-4">
            <CardTitle>Flow mix</CardTitle>
            <p className="text-sm text-secondary mt-1">Relative size of income, expenses, and transfers</p>
          </div>
          <div className="grid md:grid-cols-[180px_minmax(0,1fr)] gap-4 items-center">
            <div className="h-44">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie data={flowMix} dataKey="value" innerRadius={34} outerRadius={64}>
                    {flowMix.map((row) => (
                      <Cell key={row.name} fill={row.color} />
                    ))}
                  </Pie>
                  <Tooltip formatter={(value: number) => formatCents(value)} />
                </PieChart>
              </ResponsiveContainer>
            </div>
            <div className="space-y-3">
              {flowMix.map((row) => {
                const total = flowMix.reduce((sum, item) => sum + item.value, 0);
                const pct = total > 0 ? Math.round((row.value / total) * 100) : 0;
                return (
                  <div key={row.name} className="space-y-1">
                    <div className="flex justify-between gap-3 text-sm">
                      <span className="min-w-0 truncate">{row.name}</span>
                      <span className="tabular-nums shrink-0">
                        {formatCents(row.value)} · {pct}%
                      </span>
                    </div>
                    <div className="h-2 rounded-full bg-surface-container overflow-hidden">
                      <div
                        className="h-full rounded-full"
                        style={{ width: `${pct}%`, backgroundColor: row.color }}
                      />
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        </Card>
        <Card className="p-6">
          <div className="mb-4">
            <CardTitle>Top merchants</CardTitle>
            <p className="text-sm text-secondary mt-1">Largest expense destinations in the ledger</p>
          </div>
          <div className="space-y-3">
            {ledgerSummary?.top_merchants.length ? (
              ledgerSummary.top_merchants.map((row) => (
                <div key={row.name} className="flex justify-between gap-3 rounded-2xl bg-surface-container-low px-4 py-3 text-sm">
                  <span className="min-w-0 truncate">{row.name}</span>
                  <span className="tabular-nums shrink-0">{formatCents(row.total)}</span>
                </div>
              ))
            ) : (
              <p className="text-secondary text-sm">No merchant data yet</p>
            )}
          </div>
        </Card>
        <Card className="p-6">
          <div className="mb-4">
            <CardTitle>Ledger totals</CardTitle>
            <p className="text-sm text-secondary mt-1">Overall movement across income, expenses, and transfers</p>
          </div>
          <div className="space-y-3 text-sm">
            <div className="flex justify-between gap-3 rounded-2xl bg-surface-container-low px-4 py-3">
              <span>Expenses</span>
              <span className="tabular-nums shrink-0">{formatCents(ledgerSummary?.expense_total ?? 0)}</span>
            </div>
            <div className="flex justify-between gap-3 rounded-2xl bg-surface-container-low px-4 py-3">
              <span>Transfer in</span>
              <span className="tabular-nums shrink-0">{formatCents(ledgerSummary?.transfer_in_total ?? 0)}</span>
            </div>
            <div className="flex justify-between gap-3 rounded-2xl bg-surface-container-low px-4 py-3">
              <span>Transfer out</span>
              <span className="tabular-nums shrink-0">{formatCents(ledgerSummary?.transfer_out_total ?? 0)}</span>
            </div>
            <div className="flex justify-between gap-3 rounded-2xl bg-surface-container-low px-4 py-3 font-semibold">
              <span>Net flow</span>
              <span className="tabular-nums shrink-0">{formatCents(ledgerSummary?.net_flow ?? 0)}</span>
            </div>
          </div>
        </Card>
      </div>
    </div>
  );
}
