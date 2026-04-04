"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Plus } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { createClient } from "@/lib/supabase/client";
import type { Category, Account } from "@/lib/types";
import { useCurrency } from "@/components/currency/currency-provider";
import { amountFieldLabel, amountInputAttrs } from "@/lib/currencies";

interface AddExpenseButtonProps {
  categories: Category[];
  accounts?: Account[];
  userId: string;
}

export function AddExpenseButton({ categories, accounts = [], userId }: AddExpenseButtonProps) {
  const defaultCurrency = useCurrency();
  const [open, setOpen] = useState(false);
  const [title, setTitle] = useState("");
  const [amount, setAmount] = useState("");
  const [categoryId, setCategoryId] = useState("");
  const [accountId, setAccountId] = useState("");
  const [date, setDate] = useState(new Date().toISOString().split("T")[0]);
  const [notes, setNotes] = useState("");
  const [loading, setLoading] = useState(false);
  const router = useRouter();
  const supabase = createClient();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    const cents = Math.round(parseFloat(amount) * 100);
    const fromAccount = accountId
      ? accounts.find((a) => a.id === accountId)
      : undefined;
    const rowCurrency = fromAccount?.currency ?? defaultCurrency;

    const { error } = await supabase.from("expenses").insert({
      title,
      amount: cents,
      currency: rowCurrency,
      category_id: categoryId || null,
      account_id: accountId || null,
      date,
      notes: notes || null,
      payer_id: userId,
      group_id: null,
    });

    if (!error) {
      if (accountId) {
        const account = accounts.find((a) => a.id === accountId);
        if (account) {
          await supabase
            .from("accounts")
            .update({ balance: account.balance - cents })
            .eq("id", accountId);
        }
      }
      setOpen(false);
      setTitle("");
      setAmount("");
      setCategoryId("");
      setAccountId("");
      setNotes("");
      router.refresh();
    }

    setLoading(false);
  };

  const categoryOptions = [
    { value: "", label: "Select category" },
    ...categories.map((c) => ({ value: c.id, label: c.name })),
  ];

  const accountOptions = [
    { value: "", label: "No account" },
    ...accounts.map((a) => ({ value: a.id, label: a.name })),
  ];

  return (
    <>
      <Button onClick={() => setOpen(true)} className="gap-2">
        <Plus size={18} />
        Add Expense
      </Button>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent onClose={() => setOpen(false)}>
          <DialogHeader>
            <DialogTitle>Add Personal Expense</DialogTitle>
          </DialogHeader>

          <form onSubmit={handleSubmit} className="space-y-4">
            <Input
              id="title"
              label="Description"
              placeholder="e.g. Whole Foods Market"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              required
            />

            <Input
              id="amount"
              label={amountFieldLabel(defaultCurrency)}
              type="number"
              {...amountInputAttrs(defaultCurrency)}
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              required
            />

            <Select
              id="category"
              label="Category"
              options={categoryOptions}
              value={categoryId}
              onChange={(e) => setCategoryId(e.target.value)}
            />

            <Input
              id="date"
              label="Date"
              type="date"
              value={date}
              onChange={(e) => setDate(e.target.value)}
              required
            />

            {accounts.length > 0 && (
              <Select
                id="payFrom"
                label="Pay from"
                options={accountOptions}
                value={accountId}
                onChange={(e) => setAccountId(e.target.value)}
              />
            )}

            <Input
              id="notes"
              label="Notes (optional)"
              placeholder="Any additional details..."
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
            />

            <div className="flex gap-3 pt-2">
              <Button
                type="button"
                variant="secondary"
                className="flex-1"
                onClick={() => setOpen(false)}
              >
                Cancel
              </Button>
              <Button type="submit" className="flex-1" disabled={loading}>
                {loading ? "Saving..." : "Save Expense"}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>
    </>
  );
}
