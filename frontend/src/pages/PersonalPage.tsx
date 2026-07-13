import { useEffect, useState } from "react";
import { api } from "@/api/client";
import { formatCents } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import { Card } from "@/components/ui/card";
import type { Category, Expense } from "@/lib/types";
import { useAuth } from "@/contexts/AuthContext";

export function PersonalPage() {
  const { user } = useAuth();
  const [expenses, setExpenses] = useState<Expense[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [title, setTitle] = useState("");
  const [amount, setAmount] = useState("");
  const [categoryId, setCategoryId] = useState("");

  const load = () => api<Expense[]>("/api/expenses?personal=true").then(setExpenses);
  useEffect(() => {
    load();
    api<Category[]>("/api/categories").then(setCategories);
  }, []);

  const add = async () => {
    const cents = Math.round(parseFloat(amount) * 100);
    if (!title || !cents) return;
    await api("/api/expenses", {
      method: "POST",
      body: JSON.stringify({
        title,
        amount: cents,
        category_id: categoryId || null,
        date: new Date().toISOString().split("T")[0],
        currency: user?.default_currency ?? "JPY",
      }),
    });
    setTitle("");
    setAmount("");
    await load();
  };

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-headline font-bold">Personal expenses</h1>
      <Card className="p-4 grid md:grid-cols-4 gap-2">
        <Input id="title" label="Description" value={title} onChange={(e) => setTitle(e.target.value)} />
        <Input id="amt" label="Amount" type="number" step="0.01" value={amount} onChange={(e) => setAmount(e.target.value)} />
        <Select id="cat" label="Category" value={categoryId} onChange={(e) => setCategoryId(e.target.value)} options={[{ value: "", label: "—" }, ...categories.map((c) => ({ value: c.id, label: c.name }))]} />
        <Button onClick={add} className="self-end">Add</Button>
      </Card>
      <div className="space-y-2">
        {expenses.map((e) => (
          <Card key={e.id} className="p-4 flex justify-between text-sm">
            <span>{e.title}</span>
            <span className="tabular-nums font-semibold">-{formatCents(e.amount, e.currency)}</span>
          </Card>
        ))}
      </div>
    </div>
  );
}
