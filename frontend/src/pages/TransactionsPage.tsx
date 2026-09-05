import { useEffect, useMemo, useState } from "react";
import { Link, useParams, useSearchParams } from "react-router-dom";
import { Cell, Pie, PieChart, ResponsiveContainer, Tooltip } from "recharts";
import { api, downloadWithAuth } from "@/api/client";
import { Card, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import { Button } from "@/components/ui/button";
import { formatCents } from "@/lib/utils";
import { DataTable, type DataTableColumn } from "@/components/finance/DataTable";
import { ModalShell } from "@/components/finance/ModalShell";
import { SummaryCard } from "@/components/finance/SummaryCard";
import { SectionHeader } from "@/components/finance/SectionHeader";
import { TransactionDetailPanel } from "@/components/finance/TransactionDetailPanel";
import type {
  Account,
  Category,
  LedgerTransaction,
  LedgerTransactionSummary,
} from "@/lib/types";

const CATEGORY_COLORS = ["#0053db", "#3f72ff", "#7a5cff", "#00a76f", "#f97316"];

export function TransactionsPage() {
  const { accountId: routeAccountId } = useParams();
  const [searchParams, setSearchParams] = useSearchParams();
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [transactions, setTransactions] = useState<LedgerTransaction[]>([]);
  const [summary, setSummary] = useState<LedgerTransactionSummary | null>(null);
  const [selectedId, setSelectedId] = useState<string | null>(null);
  const [detailOpen, setDetailOpen] = useState(false);
  const [loading, setLoading] = useState(true);

  const accountId = routeAccountId ?? searchParams.get("account_id") ?? "";
  const txType = searchParams.get("tx_type") ?? "";
  const direction = searchParams.get("direction") ?? "";
  const categoryId = searchParams.get("category_id") ?? "";
  const search = searchParams.get("search") ?? "";
  const fromDate = searchParams.get("from_date") ?? "";
  const toDate = searchParams.get("to_date") ?? "";
  const page = Math.max(1, Number(searchParams.get("page") ?? "1") || 1);
  const pageSize = Math.max(10, Number(searchParams.get("page_size") ?? "25") || 25);
  const sort = searchParams.get("sort") ?? "date_desc";

  const activeAccount = accounts.find((row) => row.id === accountId);

  const query = useMemo(() => {
    const params = new URLSearchParams();
    if (accountId) params.set("account_id", accountId);
    if (txType) params.set("tx_type", txType);
    if (direction) params.set("direction", direction);
    if (categoryId) params.set("category_id", categoryId);
    if (search) params.set("search", search);
    if (fromDate) params.set("from_date", fromDate);
    if (toDate) params.set("to_date", toDate);
    if (sort) params.set("sort", sort);
    params.set("limit", String(pageSize));
    params.set("offset", String((page - 1) * pageSize));
    return params.toString();
  }, [accountId, categoryId, direction, fromDate, page, pageSize, search, sort, toDate, txType]);

  const summaryQuery = useMemo(() => {
    const params = new URLSearchParams();
    if (accountId) params.set("account_id", accountId);
    if (txType) params.set("tx_type", txType);
    if (direction) params.set("direction", direction);
    if (categoryId) params.set("category_id", categoryId);
    if (search) params.set("search", search);
    if (fromDate) params.set("from_date", fromDate);
    if (toDate) params.set("to_date", toDate);
    if (sort) params.set("sort", sort);
    return params.toString();
  }, [accountId, categoryId, direction, fromDate, search, sort, toDate, txType]);

  useEffect(() => {
    api<Account[]>("/api/accounts").then(setAccounts);
    api<Category[]>("/api/categories").then(setCategories);
  }, []);

  useEffect(() => {
    setLoading(true);
    Promise.all([
      api<LedgerTransaction[]>(`/api/transactions?${query}`),
      api<LedgerTransactionSummary>(`/api/transactions/summary?${summaryQuery}`),
    ])
      .then(([rows, stats]) => {
        setTransactions(rows);
        setSummary(stats);
        setSelectedId((current) =>
          current && rows.some((row) => row.id === current) ? current : rows[0]?.id ?? null
        );
      })
      .finally(() => setLoading(false));
  }, [query, summaryQuery]);

  const updateParam = (key: string, value: string) => {
    const next = new URLSearchParams(searchParams);
    if (value) next.set(key, value);
    else next.delete(key);
    if (key !== "page") next.set("page", "1");
    setSearchParams(next);
  };

  const clearFilters = () => {
    setSearchParams({ page: "1" });
  };

  const resetSecondaryFilters = () => {
    setSearchParams({ page: "1" });
  };

  const selectedTransaction =
    transactions.find((row) => row.id === selectedId) ?? transactions[0] ?? null;

  const openDetails = (row: LedgerTransaction) => {
    setSelectedId(row.id);
    setDetailOpen(true);
  };

  const filterChips = [
    accountId && !routeAccountId ? `Account: ${activeAccount?.name ?? "Selected"}` : null,
    txType ? `Type: ${txType}` : null,
    direction ? `Direction: ${direction}` : null,
    categoryId ? `Category: ${categories.find((row) => row.id === categoryId)?.name ?? "Selected"}` : null,
    search ? `Search: ${search}` : null,
    fromDate ? `From: ${fromDate}` : null,
    toDate ? `To: ${toDate}` : null,
  ].filter(Boolean) as string[];

  const totalMovement =
    (summary?.income_total ?? 0) +
    (summary?.expense_total ?? 0) +
    (summary?.transfer_in_total ?? 0) +
    (summary?.transfer_out_total ?? 0);
  const outflowShare =
    totalMovement > 0 ? Math.round(((summary?.expense_total ?? 0) / totalMovement) * 100) : 0;
  const inflowShare =
    totalMovement > 0 ? Math.round(((summary?.income_total ?? 0) / totalMovement) * 100) : 0;

  const cleanNotes = (value: string | null) =>
    value?.replace(/\s*\|\s*import:[^|]+$/i, "").trim() ?? null;
  const exportBaseQuery = query
    .replace(/(^|&)limit=\d+(&|$)/, "$1")
    .replace(/(^|&)offset=\d+(&|$)/, "$1")
    .replace(/^&|&$/g, "")
    .replace(/&&+/g, "&");
  const exportPath = (format: "csv" | "excel" | "pdf") =>
    `/api/export/transactions?format=${format}${exportBaseQuery ? `&${exportBaseQuery}` : ""}`;
  const columns: DataTableColumn<LedgerTransaction>[] = [
    {
      key: "date",
      header: "Date",
      sortable: true,
      width: "120px",
      render: (row) => <span className="text-secondary">{row.date}</span>,
    },
    {
      key: "type",
      header: "Type",
      sortable: true,
      width: "110px",
      render: (row) => (
        <span
          className={`chip w-fit ${
            row.tx_type === "income"
              ? "bg-emerald-100 text-emerald-700"
              : row.tx_type === "expense"
                ? "bg-rose-100 text-rose-700"
                : "bg-blue-100 text-blue-700"
          }`}
        >
          {row.tx_type}
        </span>
      ),
    },
    {
      key: "title",
      header: "Description",
      sortable: true,
      render: (row) => (
        <div className="min-w-0 max-w-[360px]">
          <p className="truncate font-medium">{row.title}</p>
          <p className="truncate text-xs text-secondary mt-0.5">
            {cleanNotes(row.notes) || row.merchant_original || "Open for details"}
          </p>
        </div>
      ),
    },
    {
      key: "account",
      header: "From / To",
      sortable: true,
      width: "180px",
      render: (row) => (
        <span className="truncate block max-w-[180px] text-secondary">
          {row.account_name}
          {row.counterparty_account_name ? ` → ${row.counterparty_account_name}` : ""}
        </span>
      ),
    },
    {
      key: "category",
      header: "Category",
      sortable: true,
      width: "140px",
      render: (row) => (
        <span className="truncate block max-w-[140px] text-secondary">
          {row.category_name || "—"}
        </span>
      ),
    },
    {
      key: "amount",
      header: "Amount",
      sortable: true,
      align: "right",
      width: "140px",
      render: (row) => (
        <span
          className={`tabular-nums font-semibold ${
            row.signed_amount > 0
              ? "text-emerald-700"
              : row.signed_amount < 0
                ? "text-rose-700"
                : "text-secondary"
          }`}
        >
          {row.signed_amount > 0 ? "+" : row.signed_amount < 0 ? "-" : ""}
          {formatCents(Math.abs(row.signed_amount), row.currency)}
        </span>
      ),
    },
  ];

  return (
    <div className="space-y-8">
      <SectionHeader
        eyebrow={routeAccountId ? "Account drill-down" : "Finance explorer"}
        title={activeAccount ? `${activeAccount.name} activity` : "Transactions"}
        description="Inspect expenses, income, and transfers with clearer descriptions, account paths, and signed amounts."
        actions={
          activeAccount ? (
            <Link to="/accounts">
              <Button variant="outline">Back to accounts</Button>
            </Link>
          ) : undefined
        }
      />

      <Card className="p-4 space-y-4">
        <div className="grid md:grid-cols-[minmax(0,1.6fr)_140px] gap-3">
          <Input
            id="ledger-search-prominent"
            label="Search transactions"
            value={search}
            onChange={(e) => updateParam("search", e.target.value)}
            placeholder="Search merchant, note, account, transfer type"
          />
          <div className="flex items-end">
            <Button
              variant="outline"
              className="w-full"
              onClick={routeAccountId ? resetSecondaryFilters : clearFilters}
            >
              {routeAccountId ? "Reset view filters" : "Reset filters"}
            </Button>
          </div>
        </div>
        <div className="grid md:grid-cols-3 lg:grid-cols-7 gap-2">
        <Select
          id="ledger-account"
          label="Account"
          value={accountId}
          onChange={(e) => updateParam("account_id", e.target.value)}
          disabled={Boolean(routeAccountId)}
          options={[
            { value: "", label: "All accounts" },
            ...accounts.map((row) => ({ value: row.id, label: row.name })),
          ]}
        />
        <Select
          id="ledger-type"
          label="Type"
          value={txType}
          onChange={(e) => updateParam("tx_type", e.target.value)}
          options={[
            { value: "", label: "All types" },
            { value: "expense", label: "Expenses" },
            { value: "income", label: "Income" },
            { value: "transfer", label: "Transfers" },
          ]}
        />
        <Select
          id="ledger-category"
          label="Category"
          value={categoryId}
          onChange={(e) => updateParam("category_id", e.target.value)}
          options={[
            { value: "", label: "All categories" },
            ...categories.map((row) => ({ value: row.id, label: row.name })),
          ]}
        />
        <Select
          id="ledger-direction"
          label="Direction"
          value={direction}
          onChange={(e) => updateParam("direction", e.target.value)}
          options={[
            { value: "", label: "All directions" },
            { value: "inflow", label: "Inflow" },
            { value: "outflow", label: "Outflow" },
            { value: "transfer", label: "Transfer" },
          ]}
        />
        <Select
          id="ledger-sort"
          label="Sort by"
          value={sort}
          onChange={(e) => updateParam("sort", e.target.value)}
          options={[
            { value: "date_desc", label: "Newest first" },
            { value: "date_asc", label: "Oldest first" },
            { value: "amount_desc", label: "Largest amount" },
            { value: "amount_asc", label: "Smallest amount" },
            { value: "title_asc", label: "Title A-Z" },
            { value: "title_desc", label: "Title Z-A" },
            { value: "type_asc", label: "Type A-Z" },
            { value: "account_asc", label: "Account A-Z" },
            { value: "category_asc", label: "Category A-Z" },
          ]}
        />
        <Input
          id="ledger-from"
          label="From"
          type="date"
          value={fromDate}
          onChange={(e) => updateParam("from_date", e.target.value)}
        />
        <Input
          id="ledger-to"
          label="To"
          type="date"
          value={toDate}
          onChange={(e) => updateParam("to_date", e.target.value)}
        />
        <Select
          id="ledger-page-size"
          label="Per page"
          value={String(pageSize)}
          onChange={(e) => updateParam("page_size", e.target.value)}
          options={[
            { value: "10", label: "10 rows" },
            { value: "25", label: "25 rows" },
            { value: "50", label: "50 rows" },
            { value: "100", label: "100 rows" },
          ]}
        />
        </div>
        <div className="flex items-center justify-between gap-3 flex-wrap">
          <div className="flex flex-wrap gap-2">
            {routeAccountId && (
              <span className="chip bg-surface-container text-secondary">
                Locked account: {activeAccount?.name ?? "Current account"}
              </span>
            )}
            {filterChips.map((chip) => (
              <span key={chip} className="chip bg-white text-secondary border border-outline/10">
                {chip}
              </span>
            ))}
            {!routeAccountId && filterChips.length === 0 && (
              <span className="text-sm text-secondary">No active filters</span>
            )}
          </div>
          <div className="flex flex-wrap gap-2">
            <Button
              variant="outline"
              onClick={() => downloadWithAuth(exportPath("csv"), "transactions.csv")}
            >
              CSV
            </Button>
            <Button
              variant="outline"
              onClick={() => downloadWithAuth(exportPath("excel"), "transactions.xls")}
            >
              Excel
            </Button>
            <Button
              variant="outline"
              onClick={() => downloadWithAuth(exportPath("pdf"), "transactions.pdf")}
            >
              PDF
            </Button>
          </div>
        </div>
      </Card>

      <div className="grid md:grid-cols-2 xl:grid-cols-4 gap-4">
        <SummaryCard
          title="Net flow"
          value={summary?.net_flow ?? 0}
          tone="primary"
          emphasized
          subtitle={`${summary?.transaction_count ?? 0} transactions in this view`}
          helper="Net of income, expenses, and account-specific transfer effects."
        />
        <SummaryCard
          title="Inflow"
          value={summary?.income_total ?? 0}
          tone="positive"
          subtitle={`${inflowShare}% of tracked movement`}
        />
        <SummaryCard
          title="Outflow"
          value={summary?.expense_total ?? 0}
          tone="negative"
          subtitle={`${outflowShare}% of tracked movement`}
        />
        <SummaryCard
          title="Transfers"
          value={(summary?.transfer_in_total ?? 0) + (summary?.transfer_out_total ?? 0)}
          tone="activity"
          subtitle={`${formatCents(summary?.transfer_in_total ?? 0)} in · ${formatCents(summary?.transfer_out_total ?? 0)} out`}
        />
      </div>

      <SectionHeader
        eyebrow="Ledger"
        title={summary ? `Activity (${summary.transaction_count})` : "Activity"}
        description="Compact transaction rows for scanning, with a modal for full transaction details."
      />
      <DataTable
        columns={columns}
        rows={transactions}
        rowKey={(row) => `${row.tx_type}-${row.id}`}
        loading={loading}
        empty="No matching transactions"
        sort={sort}
        onSort={(next) => updateParam("sort", next)}
        page={page}
        pageSize={pageSize}
        total={summary?.transaction_count ?? 0}
        onPageChange={(next) => updateParam("page", String(next))}
        onPageSizeChange={(size) => updateParam("page_size", String(size))}
        onRowClick={openDetails}
        selectedKey={selectedTransaction ? `${selectedTransaction.tx_type}-${selectedTransaction.id}` : null}
        idPrefix="transactions"
      />

      <div className="grid xl:grid-cols-[minmax(0,1fr)_380px] gap-6 items-start">
        <Card className="p-5">
          <div className="flex items-center justify-between gap-3 mb-4">
            <div>
              <CardTitle>Top categories</CardTitle>
              <p className="text-sm text-secondary mt-1">Share of spending in this filtered view</p>
            </div>
            <div className="h-24 w-24 shrink-0">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie data={summary?.top_categories ?? []} dataKey="total" innerRadius={28} outerRadius={42}>
                    {(summary?.top_categories ?? []).map((row, index) => (
                      <Cell
                        key={row.category_name}
                        fill={row.color || CATEGORY_COLORS[index % CATEGORY_COLORS.length]}
                      />
                    ))}
                  </Pie>
                  <Tooltip formatter={(value: number) => formatCents(value)} />
                </PieChart>
              </ResponsiveContainer>
            </div>
          </div>
          <div className="space-y-3">
            {summary?.top_categories.length ? (
              summary.top_categories.map((row, index) => {
                const total = summary.top_categories.reduce((sum, item) => sum + item.total, 0);
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
                          backgroundColor: row.color || CATEGORY_COLORS[index % CATEGORY_COLORS.length],
                        }}
                      />
                    </div>
                  </div>
                );
              })
            ) : (
              <p className="text-secondary text-sm">No category data</p>
            )}
          </div>
        </Card>
        <Card className="p-5">
          <CardTitle className="mb-4">Top merchants</CardTitle>
          <div className="space-y-2">
            {summary?.top_merchants.length ? (
              summary.top_merchants.map((row) => (
                <div key={row.name} className="flex justify-between text-sm gap-3 rounded-2xl bg-surface-container-low px-4 py-3">
                  <span className="truncate">{row.name}</span>
                  <span className="tabular-nums">{formatCents(row.total)}</span>
                </div>
              ))
            ) : (
              <p className="text-secondary text-sm">No merchant data</p>
            )}
          </div>
        </Card>
      </div>

      <ModalShell
        open={detailOpen}
        onClose={() => setDetailOpen(false)}
        title={selectedTransaction?.title ?? "Transaction details"}
        description="Full transaction context, metadata, and translated/original labels."
        size="lg"
      >
        <TransactionDetailPanel transaction={selectedTransaction} showTitle={false} className="border-none shadow-none p-0" />
      </ModalShell>
    </div>
  );
}
