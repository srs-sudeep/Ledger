import { useEffect, useState } from "react";
import { Link } from "react-router-dom";
import { api } from "@/api/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Card } from "@/components/ui/card";
import type { Group } from "@/lib/types";
import { useAuth } from "@/contexts/AuthContext";

type GroupRow = Group & { member_count?: number; role?: string };

export function GroupsPage() {
  const { user } = useAuth();
  const [groups, setGroups] = useState<GroupRow[]>([]);
  const [name, setName] = useState("");
  const [loading, setLoading] = useState(false);

  const load = () => api<GroupRow[]>("/api/groups").then(setGroups);
  useEffect(() => { load(); }, []);

  const create = async () => {
    if (!name.trim()) return;
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
    <div className="space-y-6">
      <div className="flex justify-between items-center">
        <h1 className="text-2xl font-headline font-bold">Groups</h1>
      </div>
      <Card className="p-4 flex gap-2">
        <Input id="gname" label="New group" value={name} onChange={(e) => setName(e.target.value)} />
        <Button onClick={create} disabled={loading} className="self-end">Create</Button>
      </Card>
      <div className="grid gap-3">
        {groups.map((g) => (
          <Link key={g.id} to={`/groups/${g.id}`}>
            <Card className="p-4 hover:shadow-ambient-lg transition-shadow">
              <p className="font-semibold">{g.name}</p>
              <p className="text-xs text-secondary capitalize">{g.type} · {g.member_count ?? 0} members · {g.currency}</p>
            </Card>
          </Link>
        ))}
      </div>
    </div>
  );
}
