import { useEffect, useState } from "react";
import { api } from "@/api/client";
import { formatCents } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";
import type { Account, Income } from "@/lib/types";
import { useAuth } from "@/contexts/AuthContext";

export function AccountsPage() {
  const { user } = useAuth();
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [income, setIncome] = useState<Income[]>([]);
  const [name, setName] = useState("");
  const [balance, setBalance] = useState("");

  const load = async () => {
    setAccounts(await api<Account[]>("/api/accounts"));
    setIncome(await api<Income[]>("/api/income"));
  };
  useEffect(() => { load(); }, []);

  const addAccount = async () => {
    const cents = Math.round(parseFloat(balance || "0") * 100);
    await api("/api/accounts", {
      method: "POST",
      body: JSON.stringify({ name, balance: cents, currency: user?.default_currency ?? "JPY" }),
    });
    setName("");
    setBalance("");
    await load();
  };

  const total = accounts.reduce((s, a) => s + a.balance, 0);

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-headline font-bold">Accounts</h1>
      <p className="text-secondary">Total: <strong className="text-on-surface tabular-nums">{formatCents(total)}</strong></p>
      <Card className="p-4 flex gap-2 flex-wrap">
        <Input id="aname" label="Account name" value={name} onChange={(e) => setName(e.target.value)} />
        <Input id="abal" label="Balance" type="number" step="0.01" value={balance} onChange={(e) => setBalance(e.target.value)} />
        <Button onClick={addAccount} className="self-end">Add account</Button>
      </Card>
      <div className="grid md:grid-cols-3 gap-4">
        {accounts.map((a) => (
          <Card key={a.id} className="p-6">
            <p className="font-semibold">{a.name}</p>
            <p className="text-xs text-secondary capitalize">{a.type}</p>
            <p className="text-xl font-bold tabular-nums mt-2">{formatCents(a.balance, a.currency)}</p>
          </Card>
        ))}
      </div>
      {income.length > 0 && (
        <div>
          <h2 className="font-bold mb-2">Recent income</h2>
          {income.map((i) => (
            <Card key={i.id} className="p-3 mb-2 flex justify-between text-sm">
              <span>{i.source}</span>
              <span className="text-green-700 tabular-nums">+{formatCents(i.amount, i.currency)}</span>
            </Card>
          ))}
        </div>
      )}
    </div>
  );
}
