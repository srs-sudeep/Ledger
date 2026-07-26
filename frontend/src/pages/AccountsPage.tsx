import { useEffect, useState } from "react";
import { api } from "@/api/client";
import { formatCents } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import { Card } from "@/components/ui/card";
import type { Account, Income } from "@/lib/types";
import { useAuth } from "@/contexts/AuthContext";
import { Trash2 } from "lucide-react";

export function AccountsPage() {
  const { user } = useAuth();
  const currency = user?.default_currency ?? "JPY";
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [income, setIncome] = useState<Income[]>([]);
  const [name, setName] = useState("");
  const [balance, setBalance] = useState("");
  const [source, setSource] = useState("");
  const [incomeAmount, setIncomeAmount] = useState("");
  const [incomeAccountId, setIncomeAccountId] = useState("");
  const [error, setError] = useState("");

  const load = async () => {
    setAccounts(await api<Account[]>("/api/accounts"));
    setIncome(await api<Income[]>("/api/income?limit=50"));
  };
  useEffect(() => {
    load();
  }, []);

  const addAccount = async () => {
    if (!name.trim()) return;
    const cents = Math.round(parseFloat(balance || "0") * 100);
    await api("/api/accounts", {
      method: "POST",
      body: JSON.stringify({ name, balance: cents, currency }),
    });
    setName("");
    setBalance("");
    await load();
  };

  const deleteAccount = async (id: string) => {
    if (!confirm("Delete this account?")) return;
    await api(`/api/accounts/${id}`, { method: "DELETE" });
    await load();
  };

  const addIncome = async () => {
    const cents = Math.round(parseFloat(incomeAmount || "0") * 100);
    if (!source.trim() || !cents) {
      setError("Source and amount required");
      return;
    }
    setError("");
    await api("/api/income", {
      method: "POST",
      body: JSON.stringify({
        source,
        amount: cents,
        currency,
        account_id: incomeAccountId || null,
        date: new Date().toISOString().split("T")[0],
      }),
    });
    setSource("");
    setIncomeAmount("");
    await load();
  };

  const deleteIncome = async (id: string) => {
    if (!confirm("Delete this income?")) return;
    await api(`/api/income/${id}`, { method: "DELETE" });
    await load();
  };

  const total = accounts.reduce((s, a) => s + a.balance, 0);

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-headline font-bold">Accounts</h1>
      <p className="text-secondary">
        Net worth:{" "}
        <strong className="text-on-surface tabular-nums">{formatCents(total)}</strong>
      </p>
      <Card className="p-4 flex gap-2 flex-wrap">
        <Input id="aname" label="Account name" value={name} onChange={(e) => setName(e.target.value)} />
        <Input id="abal" label="Balance" type="number" step="0.01" value={balance} onChange={(e) => setBalance(e.target.value)} />
        <Button onClick={addAccount} className="self-end">
          Add account
        </Button>
      </Card>
      <div className="grid md:grid-cols-3 gap-4">
        {accounts.length === 0 && <p className="text-secondary text-sm">No accounts yet</p>}
        {accounts.map((a) => (
          <Card key={a.id} className="p-6 relative">
            <button
              type="button"
              aria-label="Delete account"
              className="absolute top-3 right-3 text-secondary hover:text-error"
              onClick={() => deleteAccount(a.id)}
            >
              <Trash2 size={16} />
            </button>
            <p className="font-semibold pr-6">{a.name}</p>
            <p className="text-xs text-secondary capitalize">{a.type}</p>
            <p className="text-xl font-bold tabular-nums mt-2">{formatCents(a.balance, a.currency)}</p>
          </Card>
        ))}
      </div>

      <h2 className="font-bold text-lg">Income</h2>
      <Card className="p-4 grid md:grid-cols-4 gap-2">
        <Input id="src" label="Source" value={source} onChange={(e) => setSource(e.target.value)} />
        <Input id="iamt" label="Amount" type="number" step="0.01" value={incomeAmount} onChange={(e) => setIncomeAmount(e.target.value)} />
        <Select
          id="iacc"
          label="Account"
          value={incomeAccountId}
          onChange={(e) => setIncomeAccountId(e.target.value)}
          options={[{ value: "", label: "—" }, ...accounts.map((a) => ({ value: a.id, label: a.name }))]}
        />
        <Button onClick={addIncome} className="self-end">
          Add income
        </Button>
      </Card>
      {error && <p className="text-xs text-error">{error}</p>}
      <div className="space-y-2">
        {income.map((i) => (
          <Card key={i.id} className="p-3 flex justify-between text-sm items-center">
            <span>{i.source}</span>
            <div className="flex items-center gap-2">
              <span className="text-green-700 tabular-nums">+{formatCents(i.amount, i.currency)}</span>
              <button type="button" aria-label="Delete" onClick={() => deleteIncome(i.id)} className="text-secondary hover:text-error">
                <Trash2 size={14} />
              </button>
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
}
