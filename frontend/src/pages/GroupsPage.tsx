import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "@/api/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";
import type { Group } from "@/lib/types";
import { useAuth } from "@/contexts/AuthContext";
import { SectionHeader } from "@/components/finance/SectionHeader";
import { SummaryCard } from "@/components/finance/SummaryCard";
import { Users, WalletCards } from "lucide-react";

type GroupRow = Group & { member_count?: number; role?: string };

export function GroupsPage() {
  const { user } = useAuth();
  const [groups, setGroups] = useState<GroupRow[]>([]);
  const [name, setName] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");

  const load = () => api<GroupRow[]>("/api/groups").then(setGroups);
  useEffect(() => { load(); }, []);

  const create = async () => {
    if (!name.trim()) {
      setError("Group name is required.");
      return;
    }
    setError("");
    setLoading(true);
    try {
      await api("/api/groups", {
        method: "POST",
        body: JSON.stringify({
          name,
          type: "custom",
          currency: user?.default_currency ?? "JPY",
        }),
      });
      setName("");
      await load();
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="space-y-8">
      <SectionHeader
        eyebrow="Shared spending"
        title="Groups"
        description="Organize shared trips, homes, and custom circles without losing track of who paid and who owes."
      />

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        <SummaryCard
          title="Active groups"
          value={String(groups.length)}
          subtitle="Shared workspaces you can open right now."
          icon={Users}
          tone="primary"
        />
        <SummaryCard
          title="Default currency"
          value={user?.default_currency ?? "JPY"}
          subtitle="New groups start in your current workspace currency."
          icon={WalletCards}
          tone="neutral"
        />
      </div>

      <Card className="rounded-[28px] border border-outline/10 bg-white/85 p-6 shadow-ambient">
        <div className="grid gap-3 md:grid-cols-[minmax(0,1fr)_auto]">
          <Input
            id="gname"
            label="Group name"
            required
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Weekend trip, Tokyo house, Goa split"
          />
          <Button onClick={create} disabled={loading} className="self-end">
            Create group
          </Button>
        </div>
        {error ? <p className="mt-3 text-xs font-medium text-error">{error}</p> : null}
      </Card>

      <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
        {groups.map((g) => (
          <Link key={g.id} to={`/groups/${g.id}`}>
            <Card className="rounded-[28px] border border-outline/10 bg-white/88 p-5 transition-all hover:-translate-y-0.5 hover:shadow-ambient-lg">
              <div className="flex items-start justify-between gap-3">
                <div className="flex h-12 w-12 items-center justify-center rounded-2xl bg-[#e9f0ff] text-sm font-bold text-primary">
                  {g.name.slice(0, 2).toUpperCase()}
                </div>
                <span className="rounded-full bg-surface-container px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.14em] text-secondary">
                  {g.role ?? "member"}
                </span>
              </div>
              <p className="mt-4 text-base font-semibold">{g.name}</p>
              <p className="mt-1 text-sm text-secondary capitalize">
                {g.type} group
              </p>
              <div className="mt-5 flex items-center justify-between text-sm text-secondary">
                <span>{g.member_count ?? 0} members</span>
                <span>{g.currency}</span>
              </div>
            </Card>
          </Link>
        ))}
        {groups.length === 0 ? (
          <Card className="rounded-[28px] border border-dashed border-outline/20 bg-white/70 p-8 text-center text-sm text-secondary md:col-span-2 xl:col-span-3">
            Create your first group to start splitting shared expenses.
          </Card>
        ) : null}
      </div>
    </div>
  );
}
