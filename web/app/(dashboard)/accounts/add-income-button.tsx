"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { TrendingUp } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { createClient } from "@/lib/supabase/client";
import type { Account } from "@/lib/types";
import { useCurrency } from "@/components/currency/currency-provider";
import {
  amountFieldLabel,
  amountInputAttrs,
} from "@/lib/currencies";

interface AddIncomeButtonProps {
  accounts: Account[];
  userId: string;
}

export function AddIncomeButton({ accounts, userId }: AddIncomeButtonProps) {
  const defaultCurrency = useCurrency();
  const [open, setOpen] = useState(false);
  const [source, setSource] = useState("");
  const [amount, setAmount] = useState("");
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
    const acc = accountId ? accounts.find((a) => a.id === accountId) : undefined;
    const rowCurrency = acc?.currency ?? defaultCurrency;

    const { error } = await supabase.from("income").insert({
      user_id: userId,
      account_id: accountId || null,
      amount: cents,
      currency: rowCurrency,
      source,
      date,
      notes: notes || null,
    });

    if (!error) {
      if (accountId) {
        const account = accounts.find((a) => a.id === accountId);
        if (account) {
          await supabase
            .from("accounts")
            .update({ balance: account.balance + cents })
            .eq("id", accountId);
        }
      }

      setOpen(false);
      setSource("");
      setAmount("");
      setAccountId("");
      setNotes("");
      router.refresh();
    }

    setLoading(false);
  };

  const accountOptions = [
    { value: "", label: "No account" },
    ...accounts.map((a) => ({ value: a.id, label: a.name })),
  ];

  const incomeCurrency = accountId
    ? accounts.find((a) => a.id === accountId)?.currency ?? defaultCurrency
    : defaultCurrency;

  return (
    <>
      <Button onClick={() => setOpen(true)} variant="secondary" className="gap-2">
        <TrendingUp size={18} />
        Add Income
      </Button>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent onClose={() => setOpen(false)}>
          <DialogHeader>
            <DialogTitle>Add Income</DialogTitle>
          </DialogHeader>

          <form onSubmit={handleSubmit} className="space-y-4">
            <Input
              id="source"
              label="Source"
              placeholder="e.g. Salary, Freelance"
              value={source}
              onChange={(e) => setSource(e.target.value)}
              required
            />

            <Input
              id="incomeAmount"
              label={amountFieldLabel(incomeCurrency)}
              type="number"
              {...amountInputAttrs(incomeCurrency)}
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              required
            />

            <Select
              id="depositTo"
              label="Deposit to"
              options={accountOptions}
              value={accountId}
              onChange={(e) => setAccountId(e.target.value)}
            />

            <Input
              id="incomeDate"
              label="Date"
              type="date"
              value={date}
              onChange={(e) => setDate(e.target.value)}
              required
            />

            <Input
              id="incomeNotes"
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
                {loading ? "Saving..." : "Add Income"}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>
    </>
  );
}
