import { useEffect, useState } from "react";
import {
  Bar,
  BarChart,
  CartesianGrid,
  Cell,
  Legend,
  Pie,
  PieChart,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { api } from "@/api/client";
import { formatAxisCents, formatCents } from "@/lib/utils";
import { Card, CardTitle } from "@/components/ui/card";

interface AnalyticsOut {
  personal_total: number;
  group_total: number;
  by_category: {
    category_id: string | null;
    category_name: string;
    color: string | null;
    total: number;
  }[];
  by_month: { month: string; personal: number; group: number }[];
}

const FALLBACK_COLORS = ["#4CAF50", "#FF9800", "#2196F3", "#9C27B0", "#E91E63", "#607D8B"];

export function AnalyticsPage() {
  const [data, setData] = useState<AnalyticsOut | null>(null);

  useEffect(() => {
    api<AnalyticsOut>("/api/analytics/summary?months=6").then(setData).catch(() => setData(null));
  }, []);

  if (!data) {
    return <p className="text-secondary">Loading analytics…</p>;
  }

  return (
    <div className="space-y-6">
      <h1 className="text-2xl font-headline font-bold">Analytics</h1>
      <div className="grid md:grid-cols-2 gap-4">
        <Card className="p-6">
          <p className="text-secondary text-sm">Personal (6 mo)</p>
          <p className="text-2xl font-bold tabular-nums">{formatCents(data.personal_total)}</p>
        </Card>
        <Card className="p-6">
          <p className="text-secondary text-sm">Group (6 mo)</p>
          <p className="text-2xl font-bold tabular-nums">{formatCents(data.group_total)}</p>
        </Card>
      </div>

      <div className="grid lg:grid-cols-2 gap-6">
        <Card className="p-6">
          <CardTitle className="mb-4">By category</CardTitle>
          {data.by_category.length === 0 ? (
            <p className="text-secondary text-sm">No personal spend yet</p>
          ) : (
            <div className="h-64">
              <ResponsiveContainer width="100%" height="100%">
                <PieChart>
                  <Pie
                    data={data.by_category}
                    dataKey="total"
                    nameKey="category_name"
                    outerRadius={90}
                    label={({ category_name }) => category_name}
                  >
                    {data.by_category.map((c, i) => (
                      <Cell key={i} fill={c.color || FALLBACK_COLORS[i % FALLBACK_COLORS.length]} />
                    ))}
                  </Pie>
                  <Tooltip formatter={(v: number) => formatCents(v)} />
                </PieChart>
              </ResponsiveContainer>
            </div>
          )}
        </Card>
        <Card className="p-6">
          <CardTitle className="mb-4">Monthly burn</CardTitle>
          <div className="h-64">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={data.by_month}>
                <CartesianGrid strokeDasharray="3 3" opacity={0.3} />
                <XAxis dataKey="month" tick={{ fontSize: 11 }} />
                <YAxis tickFormatter={(v) => formatAxisCents(v)} width={64} tick={{ fontSize: 11 }} />
                <Tooltip formatter={(v: number) => formatCents(v)} />
                <Legend />
                <Bar dataKey="personal" name="Personal" fill="#0053db" radius={4} />
                <Bar dataKey="group" name="Group" fill="#9C27B0" radius={4} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </Card>
      </div>
    </div>
  );
}
