import { useEffect, useState } from "react";
import { api } from "@/api/client";
import { formatCents } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import { Card, CardTitle } from "@/components/ui/card";
import type { Category } from "@/lib/types";
import { useAuth } from "@/contexts/AuthContext";
import { Trash2 } from "lucide-react";

interface Budget {
  id: string;
  category_id: string;
  amount: number;
  month: string;
  currency: string;
  spent: number;
  category?: Category;
}

interface Recurring {
  id: string;
  title: string;
  amount: number;
  currency: string;
  frequency: string;
  next_due: string;
  active: boolean;
}

function currentMonth() {
  const d = new Date();
  return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, "0")}`;
}

export function BudgetsPage() {
  const { user } = useAuth();
  const currency = user?.default_currency ?? "JPY";
  const [budgets, setBudgets] = useState<Budget[]>([]);
  const [recurring, setRecurring] = useState<Recurring[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [categoryId, setCategoryId] = useState("");
  const [amount, setAmount] = useState("");
  const [rtitle, setRtitle] = useState("");
  const [ramount, setRamount] = useState("");
  const [rfreq, setRfreq] = useState("monthly");

  const load = async () => {
    const month = currentMonth();
    setBudgets(await api<Budget[]>(`/api/budgets?month=${month}`));
    setRecurring(await api<Recurring[]>("/api/recurring"));
  };

  useEffect(() => {
    load();
    api<Category[]>("/api/categories").then(setCategories);
  }, []);

  const addBudget = async () => {
    const cents = Math.round(parseFloat(amount) * 100);
    if (!categoryId || !cents) return;
    await api("/api/budgets", {
      method: "POST",
      body: JSON.stringify({
        category_id: categoryId,
        amount: cents,
        month: currentMonth(),
        currency,
      }),
    });
    setAmount("");
    await load();
  };

  const deleteBudget = async (id: string) => {
    await api(`/api/budgets/${id}`, { method: "DELETE" });
    await load();
  };

  const addRecurring = async () => {
    const cents = Math.round(parseFloat(ramount) * 100);
    if (!rtitle || !cents) return;
    await api("/api/recurring", {
      method: "POST",
      body: JSON.stringify({
        title: rtitle,
        amount: cents,
        currency,
        frequency: rfreq,
        next_due: new Date().toISOString().split("T")[0],
      }),
    });
    setRtitle("");
    setRamount("");
    await load();
  };

  const runRecurring = async (id: string) => {
    await api(`/api/recurring/${id}/run`, { method: "POST" });
    await load();
  };

  const deleteRecurring = async (id: string) => {
    await api(`/api/recurring/${id}`, { method: "DELETE" });
    await load();
  };

  return (
    <div className="space-y-8">
      <h1 className="text-2xl font-headline font-bold">Budgets & recurring</h1>

      <section className="space-y-4">
        <h2 className="font-bold">Monthly budgets ({currentMonth()})</h2>
        <Card className="p-4 grid md:grid-cols-3 gap-2">
          <Select
            id="bcat"
            label="Category"
            value={categoryId}
            onChange={(e) => setCategoryId(e.target.value)}
            options={[
              { value: "", label: "—" },
              ...categories.map((c) => ({ value: c.id, label: c.name })),
            ]}
          />
          <Input
            id="bamt"
            label="Budget amount"
            type="number"
            step="0.01"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
          />
          <Button onClick={addBudget} className="self-end">
            Add budget
          </Button>
        </Card>
        <div className="space-y-3">
          {budgets.length === 0 && (
            <p className="text-secondary text-sm">No budgets this month</p>
          )}
          {budgets.map((b) => {
            const pct = b.amount > 0 ? Math.min(100, (b.spent / b.amount) * 100) : 0;
            return (
              <Card key={b.id} className="p-4">
                <div className="flex justify-between items-center mb-2">
                  <p className="font-medium">{b.category?.name ?? "Category"}</p>
                  <div className="flex items-center gap-2">
                    <span className="text-sm tabular-nums">
                      {formatCents(b.spent, b.currency)} / {formatCents(b.amount, b.currency)}
                    </span>
                    <button
                      type="button"
                      aria-label="Delete"
                      onClick={() => deleteBudget(b.id)}
                      className="text-secondary hover:text-error"
                    >
                      <Trash2 size={14} />
                    </button>
                  </div>
                </div>
                <div className="h-2 rounded-full bg-surface-container overflow-hidden">
                  <div
                    className={`h-full ${pct >= 100 ? "bg-error" : "bg-surface-tint"}`}
                    style={{ width: `${pct}%` }}
                  />
                </div>
              </Card>
            );
          })}
        </div>
      </section>

      <section className="space-y-4">
        <h2 className="font-bold">Recurring expenses</h2>
        <Card className="p-4 grid md:grid-cols-4 gap-2">
          <Input id="rt" label="Title" value={rtitle} onChange={(e) => setRtitle(e.target.value)} />
          <Input
            id="ra"
            label="Amount"
            type="number"
            step="0.01"
            value={ramount}
            onChange={(e) => setRamount(e.target.value)}
          />
          <Select
            id="rf"
            label="Frequency"
            value={rfreq}
            onChange={(e) => setRfreq(e.target.value)}
            options={[
              { value: "weekly", label: "Weekly" },
              { value: "monthly", label: "Monthly" },
              { value: "yearly", label: "Yearly" },
            ]}
          />
          <Button onClick={addRecurring} className="self-end">
            Add
          </Button>
        </Card>
        <div className="space-y-2">
          {recurring.map((r) => (
            <Card key={r.id} className="p-4 flex justify-between items-center gap-2 text-sm">
              <div>
                <p className="font-medium">{r.title}</p>
                <p className="text-xs text-secondary">
                  {r.frequency} · next {r.next_due}
                </p>
              </div>
              <div className="flex items-center gap-2">
                <span className="tabular-nums font-semibold">
                  {formatCents(r.amount, r.currency)}
                </span>
                <Button size="sm" onClick={() => runRecurring(r.id)}>
                  Run
                </Button>
                <button
                  type="button"
                  aria-label="Delete"
                  onClick={() => deleteRecurring(r.id)}
                  className="text-secondary hover:text-error"
                >
                  <Trash2 size={14} />
                </button>
              </div>
            </Card>
          ))}
        </div>
      </section>
    </div>
  );
}
