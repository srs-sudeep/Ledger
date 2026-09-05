import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { Cell, Pie, PieChart, ResponsiveContainer, Tooltip } from "recharts";
import { api } from "@/api/client";
import { formatCents } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import { Card } from "@/components/ui/card";
import { DataTable, type DataTableColumn } from "@/components/finance/DataTable";
import { SectionHeader } from "@/components/finance/SectionHeader";
import { SummaryCard } from "@/components/finance/SummaryCard";
import { ModalShell } from "@/components/finance/ModalShell";
import type { Account, Income, Transfer } from "@/lib/types";
import { useAuth } from "@/contexts/AuthContext";
import { ArrowRightLeft, Landmark, Plus, Trash2, Wallet } from "lucide-react";

const ACCOUNT_COLORS = ["#0053db", "#3f72ff", "#7a5cff", "#00a76f", "#f97316", "#ef4444"];

export function AccountsPage() {
  const { user } = useAuth();
  const currency = user?.default_currency ?? "JPY";
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [income, setIncome] = useState<Income[]>([]);
  const [transfers, setTransfers] = useState<Transfer[]>([]);
  const [accountNameInput, setAccountNameInput] = useState("");
  const [accountTypeInput, setAccountTypeInput] = useState("bank");
  const [accountCurrencyInput, setAccountCurrencyInput] = useState(currency);
  const [accountBalanceInput, setAccountBalanceInput] = useState("");
  const [accountColorInput, setAccountColorInput] = useState("");
  const [incomeSourceInput, setIncomeSourceInput] = useState("");
  const [incomeAmountInput, setIncomeAmountInput] = useState("");
  const [incomeAccountInput, setIncomeAccountInput] = useState("");
  const [incomeSearch, setIncomeSearch] = useState("");
  const [incomeFilterAccount, setIncomeFilterAccount] = useState("");
  const [incomeFromDate, setIncomeFromDate] = useState("");
  const [incomeToDate, setIncomeToDate] = useState("");
  const [incomePage, setIncomePage] = useState(1);
  const [incomePageSize, setIncomePageSize] = useState(10);
  const [incomeSort, setIncomeSort] = useState("date_desc");
  const [incomeTotal, setIncomeTotal] = useState(0);
  const [incomeLoading, setIncomeLoading] = useState(false);
  const [transferAmountInput, setTransferAmountInput] = useState("");
  const [transferFromInput, setTransferFromInput] = useState("");
  const [transferToInput, setTransferToInput] = useState("");
  const [transferKindInput, setTransferKindInput] = useState("");
  const [transferNotesInput, setTransferNotesInput] = useState("");
  const [transferSearch, setTransferSearch] = useState("");
  const [transferFilterAccount, setTransferFilterAccount] = useState("");
  const [transferFromDate, setTransferFromDate] = useState("");
  const [transferToDate, setTransferToDate] = useState("");
  const [transferPage, setTransferPage] = useState(1);
  const [transferPageSize, setTransferPageSize] = useState(10);
  const [transferSort, setTransferSort] = useState("date_desc");
  const [transferTotal, setTransferTotal] = useState(0);
  const [transferLoading, setTransferLoading] = useState(false);
  const [accountModalOpen, setAccountModalOpen] = useState(false);
  const [incomeModalOpen, setIncomeModalOpen] = useState(false);
  const [transferModalOpen, setTransferModalOpen] = useState(false);
  const [error, setError] = useState("");

  const load = async () => {
    const incomeParams = new URLSearchParams({
      limit: String(incomePageSize),
      offset: String((incomePage - 1) * incomePageSize),
      sort: incomeSort,
    });
    if (incomeSearch) incomeParams.set("search", incomeSearch);
    if (incomeFilterAccount) incomeParams.set("account_id", incomeFilterAccount);
    if (incomeFromDate) incomeParams.set("from_date", incomeFromDate);
    if (incomeToDate) incomeParams.set("to_date", incomeToDate);

    const transferParams = new URLSearchParams({
      limit: String(transferPageSize),
      offset: String((transferPage - 1) * transferPageSize),
      sort: transferSort,
    });
    if (transferSearch) transferParams.set("search", transferSearch);
    if (transferFilterAccount) transferParams.set("account_id", transferFilterAccount);
    if (transferFromDate) transferParams.set("from_date", transferFromDate);
    if (transferToDate) transferParams.set("to_date", transferToDate);

    const incomeCountParams = new URLSearchParams(incomeParams);
    incomeCountParams.delete("limit");
    incomeCountParams.delete("offset");
    incomeCountParams.delete("sort");
    const transferCountParams = new URLSearchParams(transferParams);
    transferCountParams.delete("limit");
    transferCountParams.delete("offset");
    transferCountParams.delete("sort");

    setIncomeLoading(true);
    setTransferLoading(true);
    try {
      setAccounts(await api<Account[]>("/api/accounts"));
      const [incomeRows, incomeCount, transferRows, transferCount] = await Promise.all([
        api<Income[]>(`/api/income?${incomeParams.toString()}`),
        api<{ count: number }>(`/api/income/count?${incomeCountParams.toString()}`),
        api<Transfer[]>(`/api/transfers?${transferParams.toString()}`),
        api<{ count: number }>(`/api/transfers/count?${transferCountParams.toString()}`),
      ]);
      setIncome(incomeRows);
      setIncomeTotal(incomeCount.count);
      setTransfers(transferRows);
      setTransferTotal(transferCount.count);
    } finally {
      setIncomeLoading(false);
      setTransferLoading(false);
    }
  };
  useEffect(() => {
    load();
  }, [
    incomeSearch,
    incomeFilterAccount,
    incomeFromDate,
    incomeToDate,
    incomePage,
    incomePageSize,
    incomeSort,
    transferSearch,
    transferFilterAccount,
    transferFromDate,
    transferToDate,
    transferPage,
    transferPageSize,
    transferSort,
  ]);

  useEffect(() => {
    setAccountCurrencyInput(currency);
  }, [currency]);

  const addAccount = async () => {
    if (!accountNameInput.trim()) return;
    const cents = Math.round(parseFloat(accountBalanceInput || "0") * 100);
    await api("/api/accounts", {
      method: "POST",
      body: JSON.stringify({
        name: accountNameInput,
        type: accountTypeInput,
        balance: cents,
        currency: accountCurrencyInput || currency,
        color: accountColorInput || null,
      }),
    });
    setAccountNameInput("");
    setAccountTypeInput("bank");
    setAccountBalanceInput("");
    setAccountColorInput("");
    setAccountCurrencyInput(currency);
    setAccountModalOpen(false);
    await load();
  };

  const deleteAccount = async (id: string) => {
    if (!confirm("Delete this account?")) return;
    await api(`/api/accounts/${id}`, { method: "DELETE" });
    await load();
  };

  const addIncome = async () => {
    const cents = Math.round(parseFloat(incomeAmountInput || "0") * 100);
    if (!incomeSourceInput.trim() || !cents) {
      setError("Source and amount required");
      return;
    }
    setError("");
    await api("/api/income", {
      method: "POST",
      body: JSON.stringify({
        source: incomeSourceInput,
        amount: cents,
        currency,
        account_id: incomeAccountInput || null,
        date: new Date().toISOString().split("T")[0],
      }),
    });
    setIncomeSourceInput("");
    setIncomeAmountInput("");
    setIncomeAccountInput("");
    setIncomeModalOpen(false);
    await load();
  };

  const addTransfer = async () => {
    const cents = Math.round(parseFloat(transferAmountInput || "0") * 100);
    if (!cents || (!transferFromInput && !transferToInput)) {
      setError("Transfer amount and at least one account required");
      return;
    }
    if (transferFromInput && transferFromInput === transferToInput) {
      setError("Choose different source and destination accounts");
      return;
    }
    setError("");
    await api("/api/transfers", {
      method: "POST",
      body: JSON.stringify({
        amount: cents,
        currency,
        from_account_id: transferFromInput || null,
        to_account_id: transferToInput || null,
        kind: transferKindInput || null,
        notes: transferNotesInput || null,
        date: new Date().toISOString().split("T")[0],
      }),
    });
    setTransferAmountInput("");
    setTransferFromInput("");
    setTransferToInput("");
    setTransferKindInput("");
    setTransferNotesInput("");
    setTransferModalOpen(false);
    await load();
  };

  const deleteIncome = async (id: string) => {
    if (!confirm("Delete this income?")) return;
    await api(`/api/income/${id}`, { method: "DELETE" });
    await load();
  };

  const deleteTransfer = async (id: string) => {
    if (!confirm("Delete this transfer?")) return;
    await api(`/api/transfers/${id}`, { method: "DELETE" });
    await load();
  };

  const accountName = (id: string | null) =>
    accounts.find((a) => a.id === id)?.name ?? "External";

  const total = accounts.reduce((s, a) => s + a.balance, 0);
  const assets = accounts.filter((a) => a.balance > 0).reduce((s, a) => s + a.balance, 0);
  const liabilities = accounts
    .filter((a) => a.balance < 0)
    .reduce((s, a) => s + Math.abs(a.balance), 0);
  const composition = accounts
    .filter((a) => Math.abs(a.balance) > 0)
    .map((a) => ({ name: a.name, value: Math.abs(a.balance) }));
  const balanceTotal = composition.reduce((sum, item) => sum + item.value, 0);
  const incomeColumns: DataTableColumn<Income>[] = [
    {
      key: "date",
      header: "Date",
      sortable: true,
      width: "120px",
      render: (row) => <span className="text-secondary">{row.date}</span>,
    },
    {
      key: "title",
      header: "Source",
      sortable: true,
      render: (row) => <span className="font-medium">{row.source}</span>,
    },
    {
      key: "account",
      header: "Account",
      width: "160px",
      render: (row) => (
        <span className="truncate block max-w-[160px] text-secondary">
          {accountName(row.account_id)}
        </span>
      ),
    },
    {
      key: "notes",
      header: "Notes",
      render: (row) => (
        <span className="truncate block max-w-[240px] text-secondary">{row.notes || "—"}</span>
      ),
    },
    {
      key: "amount",
      header: "Amount",
      sortable: true,
      align: "right",
      width: "140px",
      render: (row) => (
        <span className="tabular-nums font-semibold text-emerald-700">
          +{formatCents(row.amount, row.currency)}
        </span>
      ),
    },
    {
      key: "actions",
      header: "",
      align: "right",
      width: "56px",
      render: (row) => (
        <button
          type="button"
          aria-label="Delete income"
          onClick={(event) => {
            event.stopPropagation();
            deleteIncome(row.id);
          }}
          className="text-secondary hover:text-error"
        >
          <Trash2 size={14} />
        </button>
      ),
    },
  ];

  const transferColumns: DataTableColumn<Transfer>[] = [
    {
      key: "date",
      header: "Date",
      sortable: true,
      width: "120px",
      render: (row) => <span className="text-secondary">{row.date}</span>,
    },
    {
      key: "from",
      header: "From",
      width: "150px",
      render: (row) => (
        <span className="truncate block max-w-[150px]">{accountName(row.from_account_id)}</span>
      ),
    },
    {
      key: "to",
      header: "To",
      width: "150px",
      render: (row) => (
        <span className="truncate block max-w-[150px]">{accountName(row.to_account_id)}</span>
      ),
    },
    {
      key: "title",
      header: "Type",
      sortable: true,
      width: "140px",
      render: (row) => <span className="text-secondary">{row.kind || "Transfer"}</span>,
    },
    {
      key: "notes",
      header: "Notes",
      render: (row) => (
        <span className="truncate block max-w-[240px] text-secondary">{row.notes || "—"}</span>
      ),
    },
    {
      key: "amount",
      header: "Amount",
      sortable: true,
      align: "right",
      width: "140px",
      render: (row) => (
        <span className="tabular-nums font-semibold">{formatCents(row.amount, row.currency)}</span>
      ),
    },
    {
      key: "actions",
      header: "",
      align: "right",
      width: "56px",
      render: (row) => (
        <button
          type="button"
          aria-label="Delete transfer"
          onClick={(event) => {
            event.stopPropagation();
            deleteTransfer(row.id);
          }}
          className="text-secondary hover:text-error"
        >
          <Trash2 size={14} />
        </button>
      ),
    },
  ];

  const sortOptions = [
    { value: "date_desc", label: "Newest first" },
    { value: "date_asc", label: "Oldest first" },
    { value: "amount_desc", label: "Largest amount" },
    { value: "amount_asc", label: "Smallest amount" },
    { value: "title_asc", label: "Name A-Z" },
    { value: "title_desc", label: "Name Z-A" },
  ];

  return (
    <div className="space-y-8">
      <SectionHeader
        eyebrow="Money movement"
        title="Accounts"
        description="Track balances, review inflows and transfers, and add new entries from focused modal flows."
      />
      <div className="grid md:grid-cols-2 xl:grid-cols-4 gap-4">
        <SummaryCard
          title="Net worth"
          value={total}
          tone="primary"
          emphasized
          icon={Wallet}
          subtitle={`${accounts.length} tracked accounts`}
          helper="Transfers are neutral; card liabilities stay negative until repaid."
        />
        <SummaryCard
          title="Assets"
          value={assets}
          tone="positive"
          icon={Landmark}
          subtitle="Positive balances across cash, bank, and wallet accounts"
        />
        <SummaryCard
          title="Liabilities"
          value={liabilities}
          tone="negative"
          icon={ArrowRightLeft}
          subtitle="Outstanding credit-card balances"
        />
        <Card className="p-5">
          <div className="flex items-center justify-between gap-4">
            <div>
              <p className="text-[11px] uppercase tracking-[0.18em] text-secondary">Balance mix</p>
              <p className="mt-2 text-lg font-semibold">Account composition</p>
            </div>
            <div className="h-24 w-24 shrink-0">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie data={composition} dataKey="value" innerRadius={24} outerRadius={42}>
                    {composition.map((item, index) => (
                      <Cell key={item.name} fill={ACCOUNT_COLORS[index % ACCOUNT_COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip formatter={(value: number) => formatCents(value)} />
                </PieChart>
              </ResponsiveContainer>
            </div>
          </div>
        </Card>
      </div>
      <SectionHeader
        eyebrow="Overview"
        title="Accounts"
        description="Use cards for the accounts themselves, then review income and transfers in denser ledger-style lists."
        actions={
          <Button className="gap-2" onClick={() => setAccountModalOpen(true)}>
            <Plus size={16} />
            Add account
          </Button>
        }
      />
      <div className="grid md:grid-cols-3 gap-4">
        {accounts.length === 0 && <p className="text-secondary text-sm">No accounts yet</p>}
        {accounts.map((a) => (
          <Card
            key={a.id}
            className={`p-6 relative ${a.balance < 0 ? "summary-card-negative" : "summary-card-neutral"}`}
          >
            <button
              type="button"
              aria-label="Delete account"
              className="absolute top-3 right-3 text-secondary hover:text-error"
              onClick={() => deleteAccount(a.id)}
            >
              <Trash2 size={16} />
            </button>
            <div className="pr-6">
              <Link to={`/accounts/${a.id}`} className="font-semibold hover:underline">
                {a.name}
              </Link>
            </div>
            <p className="text-xs text-secondary capitalize">{a.type}</p>
            <p className={`text-xl font-bold tabular-nums mt-2 ${a.balance < 0 ? "text-red-700" : ""}`}>
              {a.balance > 0 ? "+" : ""}
              {formatCents(a.balance, a.currency)}
            </p>
          </Card>
        ))}
      </div>
      {error && <p className="text-xs text-error">{error}</p>}
      <SectionHeader
        eyebrow="Income"
        title={`Income (${incomeTotal})`}
        description="Server-filtered income ledger with sortable columns and pagination."
        actions={
          <Button variant="outline" className="gap-2" onClick={() => setIncomeModalOpen(true)}>
            <Plus size={16} />
            Add income
          </Button>
        }
      />
      <Card className="p-0 overflow-hidden hover:bg-white hover:shadow-ambient">
        <div className="grid md:grid-cols-2 lg:grid-cols-5 gap-2 p-4">
          <Input
            id="income-search"
            label="Search"
            value={incomeSearch}
            onChange={(e) => {
              setIncomeSearch(e.target.value);
              setIncomePage(1);
            }}
            placeholder="Source or note"
          />
          <Select
            id="income-filter-account"
            label="Account"
            value={incomeFilterAccount}
            onChange={(e) => {
              setIncomeFilterAccount(e.target.value);
              setIncomePage(1);
            }}
            options={[
              { value: "", label: "All accounts" },
              ...accounts.map((a) => ({ value: a.id, label: a.name })),
            ]}
          />
          <Input
            id="income-from-date"
            label="From"
            type="date"
            value={incomeFromDate}
            onChange={(e) => {
              setIncomeFromDate(e.target.value);
              setIncomePage(1);
            }}
          />
          <Input
            id="income-to-date"
            label="To"
            type="date"
            value={incomeToDate}
            onChange={(e) => {
              setIncomeToDate(e.target.value);
              setIncomePage(1);
            }}
          />
          <Select
            id="income-sort"
            label="Sort by"
            value={incomeSort}
            onChange={(e) => {
              setIncomeSort(e.target.value);
              setIncomePage(1);
            }}
            options={sortOptions}
          />
        </div>
        <DataTable
          columns={incomeColumns}
          rows={income}
          rowKey={(row) => row.id}
          loading={incomeLoading}
          empty="No matching income"
          sort={incomeSort}
          onSort={(next) => {
            setIncomeSort(next);
            setIncomePage(1);
          }}
          page={incomePage}
          pageSize={incomePageSize}
          total={incomeTotal}
          onPageChange={setIncomePage}
          onPageSizeChange={(size) => {
            setIncomePageSize(size);
            setIncomePage(1);
          }}
          idPrefix="income"
          embedded
        />
      </Card>

      <SectionHeader
        eyebrow="Transfers"
        title={`Transfers (${transferTotal})`}
        description="Internal movements with from/to accounts, sortable columns, and pagination."
        actions={
          <Button variant="outline" className="gap-2" onClick={() => setTransferModalOpen(true)}>
            <Plus size={16} />
            Add transfer
          </Button>
        }
      />
      <Card className="p-0 overflow-hidden hover:bg-white hover:shadow-ambient">
        <div className="grid md:grid-cols-2 lg:grid-cols-5 gap-2 p-4">
          <Input
            id="transfer-search"
            label="Search"
            value={transferSearch}
            onChange={(e) => {
              setTransferSearch(e.target.value);
              setTransferPage(1);
            }}
            placeholder="Kind or note"
          />
          <Select
            id="transfer-filter-account"
            label="Account"
            value={transferFilterAccount}
            onChange={(e) => {
              setTransferFilterAccount(e.target.value);
              setTransferPage(1);
            }}
            options={[
              { value: "", label: "All accounts" },
              ...accounts.map((a) => ({ value: a.id, label: a.name })),
            ]}
          />
          <Input
            id="transfer-from-date"
            label="From"
            type="date"
            value={transferFromDate}
            onChange={(e) => {
              setTransferFromDate(e.target.value);
              setTransferPage(1);
            }}
          />
          <Input
            id="transfer-to-date"
            label="To"
            type="date"
            value={transferToDate}
            onChange={(e) => {
              setTransferToDate(e.target.value);
              setTransferPage(1);
            }}
          />
          <Select
            id="transfer-sort"
            label="Sort by"
            value={transferSort}
            onChange={(e) => {
              setTransferSort(e.target.value);
              setTransferPage(1);
            }}
            options={sortOptions}
          />
        </div>
        <DataTable
          columns={transferColumns}
          rows={transfers}
          rowKey={(row) => row.id}
          loading={transferLoading}
          empty="No matching transfers"
          sort={transferSort}
          onSort={(next) => {
            setTransferSort(next);
            setTransferPage(1);
          }}
          page={transferPage}
          pageSize={transferPageSize}
          total={transferTotal}
          onPageChange={setTransferPage}
          onPageSizeChange={(size) => {
            setTransferPageSize(size);
            setTransferPage(1);
          }}
          minWidth={980}
          idPrefix="transfers"
          embedded
        />
      </Card>

      <Card className="p-5">
        <div className="mb-4">
          <p className="text-[11px] uppercase tracking-[0.18em] text-secondary">Composition</p>
          <h2 className="text-xl font-headline font-bold mt-1">Where balances sit</h2>
        </div>
        <div className="grid lg:grid-cols-[280px_minmax(0,1fr)] gap-6 items-center">
          <div className="h-56">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie data={composition} dataKey="value" innerRadius={42} outerRadius={78}>
                  {composition.map((item, index) => (
                    <Cell key={item.name} fill={ACCOUNT_COLORS[index % ACCOUNT_COLORS.length]} />
                  ))}
                </Pie>
                <Tooltip formatter={(value: number) => formatCents(value)} />
              </PieChart>
            </ResponsiveContainer>
          </div>
          <div className="space-y-3">
            {composition.map((item, index) => {
              const pct = balanceTotal > 0 ? Math.round((item.value / balanceTotal) * 100) : 0;
              return (
                <div key={item.name} className="space-y-1">
                  <div className="flex justify-between gap-3 text-sm">
                    <span>{item.name}</span>
                    <span className="tabular-nums">
                      {formatCents(item.value)} · {pct}%
                    </span>
                  </div>
                  <div className="h-2 rounded-full bg-surface-container overflow-hidden">
                    <div
                      className="h-full rounded-full"
                      style={{
                        width: `${pct}%`,
                        backgroundColor: ACCOUNT_COLORS[index % ACCOUNT_COLORS.length],
                      }}
                    />
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      </Card>

      <ModalShell
        open={accountModalOpen}
        onClose={() => setAccountModalOpen(false)}
        title="Add account"
        description="Create a new account with its type, opening balance, and display styling."
      >
        <div className="grid md:grid-cols-2 gap-3">
          <Input
            id="account-name"
            label="Account name"
            value={accountNameInput}
            onChange={(e) => setAccountNameInput(e.target.value)}
          />
          <Select
            id="account-type"
            label="Type"
            value={accountTypeInput}
            onChange={(e) => setAccountTypeInput(e.target.value)}
            options={[
              { value: "bank", label: "Bank" },
              { value: "credit_card", label: "Credit card" },
              { value: "wallet", label: "Wallet" },
              { value: "cash", label: "Cash" },
              { value: "other", label: "Other" },
            ]}
          />
          <Input
            id="account-balance"
            label="Opening balance"
            type="number"
            step="0.01"
            value={accountBalanceInput}
            onChange={(e) => setAccountBalanceInput(e.target.value)}
          />
          <Input
            id="account-currency"
            label="Currency"
            value={accountCurrencyInput}
            onChange={(e) => setAccountCurrencyInput(e.target.value)}
          />
          <Input
            id="account-color"
            label="Accent color"
            value={accountColorInput}
            onChange={(e) => setAccountColorInput(e.target.value)}
            placeholder="#0053db"
          />
        </div>
        <div className="mt-5 flex justify-end">
          <Button onClick={addAccount}>Create account</Button>
        </div>
      </ModalShell>

      <ModalShell
        open={incomeModalOpen}
        onClose={() => setIncomeModalOpen(false)}
        title="Add income"
        description="Log income without keeping a large form open on the page."
      >
        <div className="grid md:grid-cols-3 gap-3">
          <Input
            id="income-source"
            label="Source"
            value={incomeSourceInput}
            onChange={(e) => setIncomeSourceInput(e.target.value)}
          />
          <Input
            id="income-amount"
            label="Amount"
            type="number"
            step="0.01"
            value={incomeAmountInput}
            onChange={(e) => setIncomeAmountInput(e.target.value)}
          />
          <Select
            id="income-account"
            label="Account"
            value={incomeAccountInput}
            onChange={(e) => setIncomeAccountInput(e.target.value)}
            options={[
              { value: "", label: "Unassigned" },
              ...accounts.map((a) => ({ value: a.id, label: a.name })),
            ]}
          />
        </div>
        <div className="mt-5 flex justify-end">
          <Button onClick={addIncome}>Save income</Button>
        </div>
      </ModalShell>

      <ModalShell
        open={transferModalOpen}
        onClose={() => setTransferModalOpen(false)}
        title="Add transfer"
        description="Move money between accounts without keeping a permanent form on the page."
      >
        <div className="grid md:grid-cols-2 gap-3">
          <Input
            id="transfer-amount"
            label="Amount"
            type="number"
            step="0.01"
            value={transferAmountInput}
            onChange={(e) => setTransferAmountInput(e.target.value)}
          />
          <Input
            id="transfer-kind"
            label="Type"
            value={transferKindInput}
            onChange={(e) => setTransferKindInput(e.target.value)}
            placeholder="Top-up, cash withdrawal, card payment"
          />
          <Select
            id="transfer-from"
            label="From"
            value={transferFromInput}
            onChange={(e) => setTransferFromInput(e.target.value)}
            options={[
              { value: "", label: "External" },
              ...accounts.map((a) => ({ value: a.id, label: a.name })),
            ]}
          />
          <Select
            id="transfer-to"
            label="To"
            value={transferToInput}
            onChange={(e) => setTransferToInput(e.target.value)}
            options={[
              { value: "", label: "External" },
              ...accounts.map((a) => ({ value: a.id, label: a.name })),
            ]}
          />
          <div className="md:col-span-2">
            <Input
              id="transfer-notes"
              label="Notes"
              value={transferNotesInput}
              onChange={(e) => setTransferNotesInput(e.target.value)}
            />
          </div>
        </div>
        <div className="mt-5 flex justify-end">
          <Button onClick={addTransfer}>Save transfer</Button>
        </div>
      </ModalShell>
    </div>
  );
}
