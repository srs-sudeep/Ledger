"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Plus } from "lucide-react";
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
import { useCurrency } from "@/components/currency/currency-provider";
import { CURRENCY_OPTIONS } from "@/lib/currencies";

const accountTypeOptions = [
  { value: "bank", label: "Bank Account" },
  { value: "credit_card", label: "Credit Card" },
  { value: "debit_card", label: "Debit Card" },
  { value: "wallet", label: "Wallet (PayPal, GPay, etc.)" },
  { value: "cash", label: "Cash" },
  { value: "other", label: "Other" },
];

const colorOptions = [
  { value: "#6366f1", label: "Indigo" },
  { value: "#3b82f6", label: "Blue" },
  { value: "#10b981", label: "Emerald" },
  { value: "#f59e0b", label: "Amber" },
  { value: "#ef4444", label: "Red" },
  { value: "#8b5cf6", label: "Violet" },
  { value: "#ec4899", label: "Pink" },
  { value: "#6b7280", label: "Gray" },
];

interface AddAccountButtonProps {
  userId: string;
}

export function AddAccountButton({ userId }: AddAccountButtonProps) {
  const profileDefault = useCurrency();
  const [open, setOpen] = useState(false);
  const [name, setName] = useState("");
  const [type, setType] = useState("bank");
  const [balance, setBalance] = useState("");
  const [currency, setCurrency] = useState(profileDefault);
  const [color, setColor] = useState("#6366f1");
  const [loading, setLoading] = useState(false);
  const router = useRouter();
  const supabase = createClient();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    const cents = Math.round(parseFloat(balance || "0") * 100);

    const { error } = await supabase.from("accounts").insert({
      user_id: userId,
      name,
      type,
      balance: cents,
      currency,
      color,
    });

    if (!error) {
      setOpen(false);
      setName("");
      setBalance("");
      setType("bank");
      setColor("#6366f1");
      setCurrency(profileDefault);
      router.refresh();
    }

    setLoading(false);
  };

  return (
    <>
      <Button onClick={() => setOpen(true)} className="gap-2">
        <Plus size={18} />
        Add Account
      </Button>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent onClose={() => setOpen(false)}>
          <DialogHeader>
            <DialogTitle>Add Account</DialogTitle>
          </DialogHeader>

          <form onSubmit={handleSubmit} className="space-y-4">
            <Input
              id="accountName"
              label="Account Name"
              placeholder="e.g. Chase Checking, GPay"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
            />

            <Select
              id="accountType"
              label="Account Type"
              options={accountTypeOptions}
              value={type}
              onChange={(e) => setType(e.target.value)}
            />

            <Select
              id="accountCurrency"
              label="Currency"
              options={CURRENCY_OPTIONS.map((c) => ({
                value: c.code,
                label: c.label,
              }))}
              value={currency}
              onChange={(e) => setCurrency(e.target.value)}
            />

            <Input
              id="balance"
              label={`Current balance (${currency})`}
              type="number"
              step="0.01"
              placeholder="0.00"
              value={balance}
              onChange={(e) => setBalance(e.target.value)}
            />

            <div>
              <label className="block text-xs font-medium text-on-surface-variant font-label mb-2">
                Color
              </label>
              <div className="flex gap-2">
                {colorOptions.map((c) => (
                  <button
                    key={c.value}
                    type="button"
                    onClick={() => setColor(c.value)}
                    className={`w-8 h-8 rounded-full transition-all ${
                      color === c.value
                        ? "ring-2 ring-offset-2 ring-primary scale-110"
                        : "hover:scale-105"
                    }`}
                    style={{ backgroundColor: c.value }}
                    title={c.label}
                  />
                ))}
              </div>
            </div>

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
                {loading ? "Saving..." : "Add Account"}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>
    </>
  );
}
