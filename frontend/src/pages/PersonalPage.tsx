import { useEffect, useState } from "react";
import { api } from "@/api/client";
import { formatCents } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import { Card } from "@/components/ui/card";
import type { Account, Category, Expense } from "@/lib/types";
import { useAuth } from "@/contexts/AuthContext";
import { Pencil, Trash2 } from "lucide-react";

function toMinor(amount: string) {
  const n = parseFloat(amount);
  if (Number.isNaN(n)) return 0;
  return Math.round(n * 100);
}

function fromMinor(amount: number) {
  return (amount / 100).toFixed(2);
}

export function PersonalPage() {
  const { user } = useAuth();
  const currency = user?.default_currency ?? "JPY";
  const [expenses, setExpenses] = useState<Expense[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [accounts, setAccounts] = useState<Account[]>([]);
  const [title, setTitle] = useState("");
  const [amount, setAmount] = useState("");
  const [categoryId, setCategoryId] = useState("");
  const [accountId, setAccountId] = useState("");
  const [editing, setEditing] = useState<Expense | null>(null);
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  const load = async () => {
    setExpenses(await api<Expense[]>("/api/expenses?personal=true&limit=100"));
  };
  useEffect(() => {
    load();
    api<Category[]>("/api/categories").then(setCategories);
    api<Account[]>("/api/accounts").then(setAccounts);
  }, []);

  const resetForm = () => {
    setTitle("");
    setAmount("");
    setCategoryId("");
    setAccountId("");
    setEditing(null);
  };

  const save = async () => {
    const cents = toMinor(amount);
    if (!title || !cents) {
      setError("Title and amount required");
      return;
    }
    setLoading(true);
    setError("");
    try {
      const body = {
        title,
        amount: cents,
        category_id: categoryId || null,
        account_id: accountId || null,
        date: editing?.date ?? new Date().toISOString().split("T")[0],
        currency,
      };
      if (editing) {
        await api(`/api/expenses/${editing.id}`, {
          method: "PATCH",
          body: JSON.stringify(body),
        });
      } else {
        await api("/api/expenses", {
          method: "POST",
          body: JSON.stringify(body),
        });
      }
      resetForm();
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Save failed");
    } finally {
      setLoading(false);
    }
  };

  const startEdit = (e: Expense) => {
    setEditing(e);
    setTitle(e.title);
    setAmount(fromMinor(e.amount));
    setCategoryId(e.category_id ?? "");
    setAccountId(e.account_id ?? "");
  };

  const remove = async (id: string) => {
    if (!confirm("Delete this expense?")) return;
    await api(`/api/expenses/${id}`, { method: "DELETE" });
    await load();
  };

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-headline font-bold">Personal expenses</h1>
      <Card className="p-4 grid md:grid-cols-5 gap-2">
        <Input id="title" label="Description" value={title} onChange={(e) => setTitle(e.target.value)} />
        <Input id="amt" label={`Amount (${currency})`} type="number" step={currency === "JPY" ? "1" : "0.01"} value={amount} onChange={(e) => setAmount(e.target.value)} />
        <Select id="cat" label="Category" value={categoryId} onChange={(e) => setCategoryId(e.target.value)} options={[{ value: "", label: "—" }, ...categories.map((c) => ({ value: c.id, label: c.name }))]} />
        <Select id="acc" label="Account" value={accountId} onChange={(e) => setAccountId(e.target.value)} options={[{ value: "", label: "—" }, ...accounts.map((a) => ({ value: a.id, label: a.name }))]} />
        <div className="flex gap-2 self-end">
          <Button onClick={save} disabled={loading} className="flex-1">
            {editing ? "Update" : "Add"}
          </Button>
          {editing && (
            <Button variant="outline" onClick={resetForm}>
              Cancel
            </Button>
          )}
        </div>
      </Card>
      {error && <p className="text-xs text-error">{error}</p>}
      <div className="space-y-2">
        {expenses.length === 0 && <p className="text-secondary text-sm">No expenses yet</p>}
        {expenses.map((e) => (
          <Card key={e.id} className="p-4 flex justify-between items-center text-sm gap-3">
            <div className="min-w-0">
              <p className="font-medium truncate">{e.title}</p>
              <p className="text-xs text-secondary">{e.date}</p>
            </div>
            <div className="flex items-center gap-2 shrink-0">
              <span className="tabular-nums font-semibold">-{formatCents(e.amount, e.currency)}</span>
              <button type="button" aria-label="Edit" onClick={() => startEdit(e)} className="text-secondary hover:text-on-surface">
                <Pencil size={16} />
              </button>
              <button type="button" aria-label="Delete" onClick={() => remove(e.id)} className="text-secondary hover:text-error">
                <Trash2 size={16} />
              </button>
            </div>
          </Card>
        ))}
      </div>
    </div>
  );
}
