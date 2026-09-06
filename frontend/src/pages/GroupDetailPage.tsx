import { useEffect, useMemo, useState } from "react";
import { useParams } from "react-router-dom";
import { api, ApiError } from "@/api/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import { Card, CardTitle } from "@/components/ui/card";
import { Avatar } from "@/components/ui/avatar";
import { SectionHeader } from "@/components/finance/SectionHeader";
import { SummaryCard } from "@/components/finance/SummaryCard";
import { formatCents } from "@/lib/utils";
import type {
  Expense,
  Group,
  GroupMember,
  DebtSimplifierResponse,
  Settlement,
  Category,
} from "@/lib/types";
import { useAuth } from "@/contexts/AuthContext";
import { Pencil, ReceiptText, Trash2, Users } from "lucide-react";

type SplitMode = "equal" | "exact" | "percentage";

export function GroupDetailPage() {
  const { id } = useParams<{ id: string }>();
  const { user } = useAuth();
  const [group, setGroup] = useState<Group | null>(null);
  const [members, setMembers] = useState<GroupMember[]>([]);
  const [expenses, setExpenses] = useState<Expense[]>([]);
  const [settlements, setSettlements] = useState<Settlement[]>([]);
  const [categories, setCategories] = useState<Category[]>([]);
  const [inviteEmail, setInviteEmail] = useState("");
  const [debts, setDebts] = useState<DebtSimplifierResponse | null>(null);
  const [error, setError] = useState("");

  const [title, setTitle] = useState("");
  const [amount, setAmount] = useState("");
  const [categoryId, setCategoryId] = useState("");
  const [editingExpense, setEditingExpense] = useState<Expense | null>(null);
  const [splitMode, setSplitMode] = useState<SplitMode>("equal");
  const [exactShares, setExactShares] = useState<Record<string, string>>({});
  const [pctShares, setPctShares] = useState<Record<string, string>>({});
  const [selected, setSelected] = useState<Record<string, boolean>>({});

  const nameOf = (uid: string) => {
    if (uid === user?.id) return "You";
    const m = members.find((x) => x.user_id === uid);
    return m?.profiles?.full_name || m?.profiles?.email || uid.slice(0, 8);
  };

  const load = async () => {
    if (!id) return;
    const [g, m, e, s] = await Promise.all([
      api<Group>(`/api/groups/${id}`),
      api<GroupMember[]>(`/api/groups/${id}/members`),
      api<Expense[]>(`/api/expenses?group_id=${id}`),
      api<Settlement[]>(`/api/groups/${id}/settlements`),
    ]);
    setGroup(g);
    setMembers(m);
    setExpenses(e);
    setSettlements(s);
    const sel: Record<string, boolean> = {};
    m.forEach((mem) => {
      sel[mem.user_id] = true;
    });
    setSelected(sel);
  };

  useEffect(() => {
    load();
    api<Category[]>("/api/categories").then(setCategories);
  }, [id]);

  const participantIds = useMemo(
    () => members.filter((m) => selected[m.user_id]).map((m) => m.user_id),
    [members, selected]
  );

  const buildSplits = (cents: number) => {
    const ids = participantIds;
    if (ids.length === 0) throw new Error("Select at least one member");
    if (splitMode === "equal") {
      const base = Math.floor(cents / ids.length);
      let rem = cents - base * ids.length;
      return ids.map((uid, i) => ({
        user_id: uid,
        owed_amount: base + (i < rem ? 1 : 0),
        split_type: "equal",
      }));
    }
    if (splitMode === "exact") {
      const splits = ids.map((uid) => ({
        user_id: uid,
        owed_amount: Math.round(parseFloat(exactShares[uid] || "0") * 100),
        split_type: "exact",
      }));
      const total = splits.reduce((s, x) => s + x.owed_amount, 0);
      if (total !== cents) throw new Error(`Exact shares (${total / 100}) must equal amount`);
      return splits;
    }
    const pcts = ids.map((uid) => parseFloat(pctShares[uid] || "0"));
    const pctSum = pcts.reduce((a, b) => a + b, 0);
    if (Math.abs(pctSum - 100) > 0.01) throw new Error("Percentages must sum to 100");
    let allocated = 0;
    return ids.map((uid, i) => {
      const owed =
        i === ids.length - 1
          ? cents - allocated
          : Math.round((cents * pcts[i]) / 100);
      allocated += owed;
      return { user_id: uid, owed_amount: owed, split_type: "percentage" };
    });
  };

  const invite = async () => {
    if (!id || !inviteEmail.trim()) {
      setError("Member email is required.");
      return;
    }
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

  const addExpense = async () => {
    if (!id) return;
    setError("");
    try {
      const cents = Math.round(parseFloat(amount) * 100);
      if (!title || !cents) throw new Error("Title and amount required");
      const splits = buildSplits(cents);
      await api(`/api/expenses${editingExpense ? `/${editingExpense.id}` : ""}`, {
        method: editingExpense ? "PATCH" : "POST",
        body: JSON.stringify({
          title,
          amount: cents,
          date: editingExpense?.date ?? new Date().toISOString().split("T")[0],
          group_id: id,
          category_id: categoryId || null,
          payer_id: user?.id,
          splits,
        }),
      });
      setTitle("");
      setAmount("");
      setCategoryId("");
      setEditingExpense(null);
      setDebts(null);
      await load();
    } catch (e) {
      setError(e instanceof Error ? e.message : "Failed to add expense");
    }
  };

  const startExpenseEdit = (expense: Expense) => {
    setEditingExpense(expense);
    setTitle(expense.title);
    setAmount((expense.amount / 100).toFixed(2));
    setCategoryId(expense.category_id ?? "");
    setSplitMode("equal");
    setSelected(
      Object.fromEntries(members.map((member) => [member.user_id, true]))
    );
    setExactShares({});
    setPctShares({});
    setError("");
  };

  const cancelExpenseEdit = () => {
    setEditingExpense(null);
    setTitle("");
    setAmount("");
    setCategoryId("");
    setSplitMode("equal");
    setExactShares({});
    setPctShares({});
    setError("");
  };

  const removeExpense = async (expenseId: string) => {
    if (!confirm("Delete this expense?")) return;
    await api(`/api/expenses/${expenseId}`, { method: "DELETE" });
    setDebts(null);
    await load();
  };

  const simplify = async () => {
    if (!id) return;
    const res = await api<DebtSimplifierResponse>(`/api/groups/${id}/simplify-debts`, {
      method: "POST",
    });
    setDebts(res);
  };

  const markPaid = async (from: string, to: string, amt: number) => {
    if (!id || !user) return;
    await api(`/api/groups/${id}/settlements`, {
      method: "POST",
      body: JSON.stringify({
        from_user_id: from,
        to_user_id: to,
        amount: amt,
        group_id: id,
        status: "completed",
      }),
    });
    setDebts(null);
    await load();
    await simplify();
  };

  if (!group) return <p className="text-secondary">Loading...</p>;

  const balances = debts?.balances ?? {};

  return (
    <div className="space-y-8">
      <SectionHeader
        eyebrow={group.type}
        title={group.name}
        description="Track members, shared expenses, balances, and settlement activity for this group."
      />

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        <SummaryCard
          title="Members"
          value={String(members.length)}
          subtitle="People currently included in this split."
          icon={Users}
          tone="neutral"
        />
        <SummaryCard
          title="Expenses"
          value={String(expenses.length)}
          subtitle="Shared entries recorded for this group."
          icon={ReceiptText}
          tone="activity"
        />
      </div>

      <Card className="rounded-[28px] border border-outline/10 bg-white/88 p-6 space-y-4 shadow-ambient">
        <CardTitle>{editingExpense ? "Edit group expense" : "Add group expense"}</CardTitle>
        <div className="grid md:grid-cols-4 gap-2">
          <Input id="gtitle" label="Title" required value={title} onChange={(e) => setTitle(e.target.value)} />
          <Input id="gamt" label="Amount" required type="number" step="0.01" value={amount} onChange={(e) => setAmount(e.target.value)} />
          <Select
            id="gcat"
            label="Category"
            value={categoryId}
            onChange={(e) => setCategoryId(e.target.value)}
            options={[{ value: "", label: "—" }, ...categories.map((c) => ({ value: c.id, label: c.name }))]}
          />
          <Select
            id="gsplit"
            label="Split mode"
            required
            value={splitMode}
            onChange={(e) => setSplitMode(e.target.value as SplitMode)}
            options={[
              { value: "equal", label: "Equal" },
              { value: "exact", label: "Exact amounts" },
              { value: "percentage", label: "Percentage" },
            ]}
          />
        </div>
        <div className="flex flex-wrap gap-3">
          {members.map((m) => (
            <label key={m.id} className="flex items-center gap-2 text-sm">
              <input
                type="checkbox"
                checked={!!selected[m.user_id]}
                onChange={(e) =>
                  setSelected((s) => ({ ...s, [m.user_id]: e.target.checked }))
                }
              />
              {nameOf(m.user_id)}
            </label>
          ))}
        </div>
        {splitMode !== "equal" && (
          <div className="grid md:grid-cols-2 gap-2">
            {participantIds.map((uid) => (
              <Input
                key={uid}
                id={`share-${uid}`}
                label={`${nameOf(uid)} (${splitMode === "percentage" ? "%" : "amount"})`}
                type="number"
                step="0.01"
                value={splitMode === "exact" ? exactShares[uid] ?? "" : pctShares[uid] ?? ""}
                onChange={(e) =>
                  splitMode === "exact"
                    ? setExactShares((s) => ({ ...s, [uid]: e.target.value }))
                    : setPctShares((s) => ({ ...s, [uid]: e.target.value }))
                }
              />
            ))}
          </div>
        )}
        {error && <p className="text-xs text-error">{error}</p>}
        <div className="flex gap-2">
          <Button onClick={addExpense}>{editingExpense ? "Save changes" : "Add expense"}</Button>
          {editingExpense && (
            <Button variant="outline" onClick={cancelExpenseEdit}>
              Cancel
            </Button>
          )}
        </div>
      </Card>

      <div className="grid lg:grid-cols-[minmax(0,1.1fr)_minmax(320px,0.9fr)] gap-8">
        <div className="space-y-4">
          <h2 className="font-bold">Group expenses</h2>
          {expenses.map((e) => (
            <Card key={e.id} className="rounded-[24px] border border-outline/10 bg-white/88 p-5 flex justify-between items-center gap-3 shadow-sm">
              <div className="min-w-0">
                <p className="font-medium">{e.title}</p>
                <p className="text-xs text-secondary">
                  {e.profiles?.full_name ?? "Unknown"} · {e.date}
                </p>
              </div>
              <div className="flex items-center gap-2">
                <span className="tabular-nums font-semibold">
                  {formatCents(e.amount, e.currency)}
                </span>
                <button
                  type="button"
                  aria-label="Edit"
                  className="text-secondary hover:text-on-surface"
                  onClick={() => startExpenseEdit(e)}
                >
                  <Pencil size={16} />
                </button>
                <button
                  type="button"
                  aria-label="Delete"
                  className="text-secondary hover:text-error"
                  onClick={() => removeExpense(e.id)}
                >
                  <Trash2 size={16} />
                </button>
              </div>
            </Card>
          ))}
          {expenses.length === 0 && <p className="text-secondary text-sm">No expenses yet</p>}
        </div>
        <div className="space-y-4">
          <Card className="rounded-[28px] border border-outline/10 bg-white/88 p-6 shadow-ambient">
            <CardTitle className="mb-4">Members</CardTitle>
            <div className="space-y-3 mb-4">
              {members.map((m) => (
                <div key={m.id} className="flex items-center gap-3">
                  <Avatar fallback={m.profiles?.full_name ?? "?"} src={m.profiles?.avatar_url} size="sm" />
                  <div className="flex-1">
                    <p className="text-sm font-medium">{nameOf(m.user_id)}</p>
                    <p className="text-xs text-secondary capitalize">{m.role}</p>
                  </div>
                  {debts && balances[m.user_id] !== undefined && (
                    <span
                      className={`text-xs tabular-nums ${
                        balances[m.user_id] >= 0 ? "text-green-700" : "text-error"
                      }`}
                    >
                      {balances[m.user_id] >= 0 ? "+" : ""}
                      {formatCents(balances[m.user_id], group.currency)}
                    </span>
                  )}
                </div>
              ))}
            </div>
            <Input
              id="invite"
              label="Invite by email"
              required
              type="email"
              value={inviteEmail}
              onChange={(e) => setInviteEmail(e.target.value)}
            />
            <Button className="mt-2 w-full" onClick={invite}>
              Add member
            </Button>
          </Card>
          <Card className="rounded-[28px] border border-outline/10 bg-white/88 p-6 shadow-ambient">
            <CardTitle className="mb-2">Settle up</CardTitle>
            <Button onClick={simplify} className="w-full">
              Calculate debts
            </Button>
            {debts && (
              <ul className="mt-4 space-y-3 text-sm">
                {debts.transactions.map((t, i) => (
                  <li key={i} className="flex items-center justify-between gap-2">
                    <span>
                      <strong>{nameOf(t.from)}</strong> pays{" "}
                      <strong>{nameOf(t.to)}</strong>{" "}
                      {formatCents(t.amount, group.currency)}
                    </span>
                    {t.from === user?.id && (
                      <Button size="sm" onClick={() => markPaid(t.from, t.to, t.amount)}>
                        Mark paid
                      </Button>
                    )}
                  </li>
                ))}
                {debts.transactions.length === 0 && <li>Nothing to settle</li>}
              </ul>
            )}
          </Card>
          {settlements.length > 0 && (
            <Card className="rounded-[28px] border border-outline/10 bg-white/88 p-6 shadow-ambient">
              <CardTitle className="mb-3">Settlement history</CardTitle>
              <ul className="space-y-2 text-sm">
                {settlements.map((s) => (
                  <li key={s.id} className="flex justify-between">
                    <span>
                      {s.from_profile?.full_name ?? "Someone"} →{" "}
                      {s.to_profile?.full_name ?? "Someone"}
                    </span>
                    <span className="tabular-nums">
                      {formatCents(s.amount, s.currency)} · {s.status}
                    </span>
                  </li>
                ))}
              </ul>
            </Card>
          )}
        </div>
      </div>
    </div>
  );
}
