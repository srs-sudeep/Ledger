import { useEffect, useState } from "react";
import { api } from "@/api/client";
import { formatCents } from "@/lib/utils";
import { Card } from "@/components/ui/card";
import type { Expense } from "@/lib/types";

export function AnalyticsPage() {
  const [personal, setPersonal] = useState<Expense[]>([]);
  const [group, setGroup] = useState<Expense[]>([]);

  useEffect(() => {
    const start = new Date();
    start.setMonth(start.getMonth() - 6);
    const from = start.toISOString().split("T")[0];
    api<Expense[]>(`/api/expenses?personal=true&from_date=${from}&limit=500`).then(setPersonal);
    api<Expense[]>(`/api/expenses?from_date=${from}&limit=500`).then((all) =>
      setGroup(all.filter((e) => e.group_id))
    );
  }, []);

  const personalTotal = personal.reduce((s, e) => s + e.amount, 0);
  const groupTotal = group.reduce((s, e) => s + e.amount, 0);

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-headline font-bold">Analytics</h1>
      <div className="grid md:grid-cols-2 gap-4">
        <Card className="p-6">
          <p className="text-secondary text-sm">Personal (6 mo)</p>
          <p className="text-2xl font-bold tabular-nums">{formatCents(personalTotal)}</p>
        </Card>
        <Card className="p-6">
          <p className="text-secondary text-sm">Group (6 mo)</p>
          <p className="text-2xl font-bold tabular-nums">{formatCents(groupTotal)}</p>
        </Card>
      </div>
    </div>
  );
}
