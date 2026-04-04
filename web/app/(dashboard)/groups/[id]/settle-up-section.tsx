"use client";

import { useState, useCallback } from "react";
import { useRouter } from "next/navigation";
import { Card, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Avatar } from "@/components/ui/avatar";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { formatCents } from "@/lib/utils";
import { createClient } from "@/lib/supabase/client";
import { ArrowRight, CheckCircle, Loader2 } from "lucide-react";
import type { GroupMember, SimplifiedTransaction } from "@/lib/types";

interface SettleUpSectionProps {
  groupId: string;
  groupCurrency: string;
  members: GroupMember[];
  userId: string;
}

export function SettleUpSection({
  groupId,
  groupCurrency,
  members,
  userId,
}: SettleUpSectionProps) {
  const [open, setOpen] = useState(false);
  const [transactions, setTransactions] = useState<SimplifiedTransaction[]>([]);
  const [loading, setLoading] = useState(false);
  const [settling, setSettling] = useState<string | null>(null);
  const router = useRouter();
  const supabase = createClient();

  const memberMap = Object.fromEntries(
    members.map((m) => [m.user_id, m.profiles])
  );

  const fetchSimplified = useCallback(async () => {
    setLoading(true);
    try {
      const { data, error } = await supabase.functions.invoke("debt-simplifier", {
        body: { group_id: groupId },
      });

      if (!error && data?.transactions) {
        setTransactions(data.transactions);
      }
    } catch {
      // Edge function may not be deployed yet
    }
    setLoading(false);
  }, [groupId, supabase]);

  const handleOpen = async () => {
    setOpen(true);
    await fetchSimplified();
  };

  const handleSettle = async (txn: SimplifiedTransaction) => {
    setSettling(`${txn.from}-${txn.to}`);

    await supabase.from("settlements").insert({
      from_user_id: txn.from,
      to_user_id: txn.to,
      amount: txn.amount,
      currency: groupCurrency,
      group_id: groupId,
      status: "completed",
      settled_at: new Date().toISOString(),
    });

    setTransactions((prev) =>
      prev.filter((t) => !(t.from === txn.from && t.to === txn.to))
    );
    setSettling(null);
    router.refresh();
  };

  const getName = (id: string) => {
    if (id === userId) return "You";
    return memberMap[id]?.full_name || "Unknown";
  };

  return (
    <>
      <Card className="p-6">
        <CardTitle className="mb-4">Settle Up</CardTitle>
        <p className="text-sm text-secondary mb-4">
          Simplify group debts into the minimum number of transactions.
        </p>
        <Button onClick={handleOpen} className="w-full">
          Calculate & Settle
        </Button>
      </Card>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent onClose={() => setOpen(false)} className="max-w-md">
          <DialogHeader>
            <DialogTitle>Settle Up</DialogTitle>
          </DialogHeader>

          {loading ? (
            <div className="flex flex-col items-center py-8">
              <Loader2 className="animate-spin text-surface-tint mb-3" size={32} />
              <p className="text-sm text-secondary">Calculating simplified debts...</p>
            </div>
          ) : transactions.length === 0 ? (
            <div className="flex flex-col items-center py-8">
              <CheckCircle className="text-on-tertiary-fixed-variant mb-3" size={40} />
              <p className="font-headline font-bold text-lg mb-1">All settled!</p>
              <p className="text-sm text-secondary">No outstanding debts in this group.</p>
            </div>
          ) : (
            <div className="space-y-4">
              <p className="text-xs text-secondary">
                Simplified to {transactions.length} transaction
                {transactions.length !== 1 ? "s" : ""}
              </p>

              {transactions.map((txn) => {
                const key = `${txn.from}-${txn.to}`;
                const isSettling = settling === key;
                const involvesMe = txn.from === userId || txn.to === userId;

                return (
                  <div
                    key={key}
                    className="flex items-center justify-between p-4 rounded-xl bg-surface-container-low"
                  >
                    <div className="flex items-center gap-2 text-sm">
                      <Avatar
                        src={memberMap[txn.from]?.avatar_url}
                        fallback={getName(txn.from)}
                        size="sm"
                      />
                      <span className="font-semibold">{getName(txn.from)}</span>
                      <ArrowRight size={14} className="text-secondary" />
                      <Avatar
                        src={memberMap[txn.to]?.avatar_url}
                        fallback={getName(txn.to)}
                        size="sm"
                      />
                      <span className="font-semibold">{getName(txn.to)}</span>
                    </div>

                    <div className="flex items-center gap-3">
                      <span className="font-headline font-bold tabular-nums">
                        {formatCents(txn.amount, groupCurrency)}
                      </span>
                      {involvesMe && (
                        <Button
                          size="sm"
                          variant={txn.from === userId ? "default" : "outline"}
                          onClick={() => handleSettle(txn)}
                          disabled={isSettling}
                        >
                          {isSettling ? "..." : "Settle"}
                        </Button>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </DialogContent>
      </Dialog>
    </>
  );
}
