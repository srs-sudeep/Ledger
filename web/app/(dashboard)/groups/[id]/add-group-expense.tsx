"use client";

import { useState, useEffect } from "react";
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
import { Tabs, TabsList, TabsTrigger, TabsContent } from "@/components/ui/tabs";
import { createClient } from "@/lib/supabase/client";
import type { Category, GroupMember } from "@/lib/types";

interface AddGroupExpenseButtonProps {
  groupId: string;
  members: GroupMember[];
  categories: Category[];
  userId: string;
}

export function AddGroupExpenseButton({
  groupId,
  members,
  categories,
  userId,
}: AddGroupExpenseButtonProps) {
  const [open, setOpen] = useState(false);
  const [title, setTitle] = useState("");
  const [amount, setAmount] = useState("");
  const [categoryId, setCategoryId] = useState("");
  const [date, setDate] = useState(new Date().toISOString().split("T")[0]);
  const [payerId, setPayerId] = useState(userId);
  const [splitType, setSplitType] = useState("equal");
  const [customSplits, setCustomSplits] = useState<Record<string, string>>({});
  const [loading, setLoading] = useState(false);
  const router = useRouter();
  const supabase = createClient();

  useEffect(() => {
    const initial: Record<string, string> = {};
    members.forEach((m) => {
      initial[m.user_id] = "";
    });
    setCustomSplits(initial);
  }, [members]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    const cents = Math.round(parseFloat(amount) * 100);

    const { data: expense, error } = await supabase
      .from("expenses")
      .insert({
        title,
        amount: cents,
        category_id: categoryId || null,
        date,
        payer_id: payerId,
        group_id: groupId,
      })
      .select()
      .single();

    if (error || !expense) {
      setLoading(false);
      return;
    }

    // Create splits
    let splits: { expense_id: string; user_id: string; owed_amount: number; split_type: string }[] = [];

    if (splitType === "equal") {
      const perPerson = Math.floor(cents / members.length);
      const remainder = cents - perPerson * members.length;

      splits = members.map((m, i) => ({
        expense_id: expense.id,
        user_id: m.user_id,
        owed_amount: perPerson + (i === 0 ? remainder : 0),
        split_type: "equal" as const,
      }));
    } else if (splitType === "exact") {
      splits = members
        .filter((m) => customSplits[m.user_id] && parseFloat(customSplits[m.user_id]) > 0)
        .map((m) => ({
          expense_id: expense.id,
          user_id: m.user_id,
          owed_amount: Math.round(parseFloat(customSplits[m.user_id]) * 100),
          split_type: "exact" as const,
        }));
    } else {
      splits = members
        .filter((m) => customSplits[m.user_id] && parseFloat(customSplits[m.user_id]) > 0)
        .map((m) => ({
          expense_id: expense.id,
          user_id: m.user_id,
          owed_amount: Math.round(
            (parseFloat(customSplits[m.user_id]) / 100) * cents
          ),
          split_type: "percentage" as const,
        }));
    }

    if (splits.length > 0) {
      await supabase.from("expense_splits").insert(splits);
    }

    setOpen(false);
    setTitle("");
    setAmount("");
    setCategoryId("");
    setLoading(false);
    router.refresh();
  };

  const payerOptions = members.map((m) => ({
    value: m.user_id,
    label: m.user_id === userId ? "You" : m.profiles?.full_name || "Unknown",
  }));

  const categoryOptions = [
    { value: "", label: "Select category" },
    ...categories.map((c) => ({ value: c.id, label: c.name })),
  ];

  return (
    <>
      <Button onClick={() => setOpen(true)} size="sm" className="gap-1">
        <Plus size={16} />
        Add Expense
      </Button>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent onClose={() => setOpen(false)} className="max-w-xl">
          <DialogHeader>
            <DialogTitle>Add Group Expense</DialogTitle>
          </DialogHeader>

          <form onSubmit={handleSubmit} className="space-y-4">
            <Input
              id="gtitle"
              label="Description"
              placeholder="e.g. Dinner at Italian Place"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              required
            />

            <div className="grid grid-cols-2 gap-4">
              <Input
                id="gamount"
                label="Amount ($)"
                type="number"
                step="0.01"
                min="0.01"
                placeholder="0.00"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                required
              />
              <Select
                id="payer"
                label="Paid by"
                options={payerOptions}
                value={payerId}
                onChange={(e) => setPayerId(e.target.value)}
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <Select
                id="gcategory"
                label="Category"
                options={categoryOptions}
                value={categoryId}
                onChange={(e) => setCategoryId(e.target.value)}
              />
              <Input
                id="gdate"
                label="Date"
                type="date"
                value={date}
                onChange={(e) => setDate(e.target.value)}
                required
              />
            </div>

            <div className="space-y-3">
              <label className="block text-xs font-medium text-on-surface-variant font-label">
                Split Type
              </label>
              <Tabs value={splitType} onValueChange={setSplitType}>
                <TabsList>
                  <TabsTrigger value="equal">Equal</TabsTrigger>
                  <TabsTrigger value="exact">Exact</TabsTrigger>
                  <TabsTrigger value="percentage">Percentage</TabsTrigger>
                </TabsList>

                <TabsContent value="equal">
                  <p className="text-xs text-secondary">
                    Split equally among all {members.length} members
                    {amount &&
                      ` — ${(parseFloat(amount) / members.length).toFixed(2)} each`}
                  </p>
                </TabsContent>

                <TabsContent value="exact">
                  <div className="space-y-2">
                    {members.map((m) => (
                      <div
                        key={m.user_id}
                        className="flex items-center justify-between gap-3"
                      >
                        <span className="text-sm font-medium flex-1">
                          {m.user_id === userId
                            ? "You"
                            : m.profiles?.full_name || "Unknown"}
                        </span>
                        <div className="w-32">
                          <Input
                            type="number"
                            step="0.01"
                            min="0"
                            placeholder="0.00"
                            value={customSplits[m.user_id] || ""}
                            onChange={(e) =>
                              setCustomSplits({
                                ...customSplits,
                                [m.user_id]: e.target.value,
                              })
                            }
                          />
                        </div>
                      </div>
                    ))}
                  </div>
                </TabsContent>

                <TabsContent value="percentage">
                  <div className="space-y-2">
                    {members.map((m) => (
                      <div
                        key={m.user_id}
                        className="flex items-center justify-between gap-3"
                      >
                        <span className="text-sm font-medium flex-1">
                          {m.user_id === userId
                            ? "You"
                            : m.profiles?.full_name || "Unknown"}
                        </span>
                        <div className="w-32 flex items-center gap-1">
                          <Input
                            type="number"
                            step="1"
                            min="0"
                            max="100"
                            placeholder="0"
                            value={customSplits[m.user_id] || ""}
                            onChange={(e) =>
                              setCustomSplits({
                                ...customSplits,
                                [m.user_id]: e.target.value,
                              })
                            }
                          />
                          <span className="text-sm text-secondary">%</span>
                        </div>
                      </div>
                    ))}
                  </div>
                </TabsContent>
              </Tabs>
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
                {loading ? "Saving..." : "Add Expense"}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>
    </>
  );
}
