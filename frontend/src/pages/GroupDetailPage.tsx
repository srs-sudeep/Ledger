import { useEffect, useState } from "react";
import { useParams } from "react-router-dom";
import { api, ApiError } from "@/api/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card, CardTitle } from "@/components/ui/card";
import { Avatar } from "@/components/ui/avatar";
import { formatCents } from "@/lib/utils";
import type { Expense, Group, GroupMember, DebtSimplifierResponse } from "@/lib/types";
import { useAuth } from "@/contexts/AuthContext";

export function GroupDetailPage() {
  const { id } = useParams<{ id: string }>();
  const { user } = useAuth();
  const [group, setGroup] = useState<Group | null>(null);
  const [members, setMembers] = useState<GroupMember[]>([]);
  const [expenses, setExpenses] = useState<Expense[]>([]);
  const [inviteEmail, setInviteEmail] = useState("");
  const [debts, setDebts] = useState<DebtSimplifierResponse | null>(null);
  const [error, setError] = useState("");

  const load = async () => {
    if (!id) return;
    const [g, m, e] = await Promise.all([
      api<Group>(`/api/groups/${id}`),
      api<GroupMember[]>(`/api/groups/${id}/members`),
      api<Expense[]>(`/api/expenses?group_id=${id}`),
    ]);
    setGroup(g);
    setMembers(m);
    setExpenses(e);
  };

  useEffect(() => { load(); }, [id]);

  const invite = async () => {
    if (!id || !inviteEmail) return;
    setError("");
    try {
      await api(`/api/groups/${id}/members`, {
        method: "POST",
        body: JSON.stringify({ email: inviteEmail }),
      });
      setInviteEmail("");
      await load();
    } catch (e) {
      setError(e instanceof ApiError ? e.message : "Invite failed");
    }
  };

  const simplify = async () => {
    if (!id) return;
    const res = await api<DebtSimplifierResponse>(`/api/groups/${id}/simplify-debts`, { method: "POST" });
    setDebts(res);
  };

  if (!group) return <p className="text-secondary">Loading...</p>;

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-2xl font-headline font-bold">{group.name}</h1>
        <p className="text-secondary text-sm capitalize">{group.type} · {members.length} members</p>
      </div>
      <div className="grid lg:grid-cols-2 gap-8">
        <div className="space-y-4">
          <h2 className="font-bold">Group expenses</h2>
          {expenses.map((e) => (
            <Card key={e.id} className="p-4 flex justify-between">
              <div>
                <p className="font-medium">{e.title}</p>
                <p className="text-xs text-secondary">{e.profiles?.full_name ?? "Unknown"}</p>
              </div>
              <span className="tabular-nums font-semibold">{formatCents(e.amount, e.currency)}</span>
            </Card>
          ))}
          {expenses.length === 0 && <p className="text-secondary text-sm">No expenses yet</p>}
        </div>
        <div className="space-y-4">
          <Card className="p-6">
            <CardTitle className="mb-4">Members</CardTitle>
            <div className="space-y-3 mb-4">
              {members.map((m) => (
                <div key={m.id} className="flex items-center gap-3">
                  <Avatar fallback={m.profiles?.full_name ?? "?"} src={m.profiles?.avatar_url} size="sm" />
                  <div>
                    <p className="text-sm font-medium">{m.user_id === user?.id ? "You" : m.profiles?.full_name}</p>
                    <p className="text-xs text-secondary capitalize">{m.role}</p>
                  </div>
                </div>
              ))}
            </div>
            <Input id="invite" label="Invite by email" type="email" value={inviteEmail} onChange={(e) => setInviteEmail(e.target.value)} />
            {error && <p className="text-xs text-error mt-2">{error}</p>}
            <Button className="mt-2 w-full" onClick={invite}>Add member</Button>
          </Card>
          <Card className="p-6">
            <CardTitle className="mb-2">Settle up</CardTitle>
            <Button onClick={simplify} className="w-full">Calculate debts</Button>
            {debts && (
              <ul className="mt-4 space-y-2 text-sm">
                {debts.transactions.map((t, i) => (
                  <li key={i}>Pay {formatCents(t.amount)}</li>
                ))}
                {debts.transactions.length === 0 && <li>Nothing to settle</li>}
              </ul>
            )}
          </Card>
        </div>
      </div>
    </div>
  );
}
