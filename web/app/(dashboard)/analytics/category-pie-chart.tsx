"use client";

import { Card, CardTitle } from "@/components/ui/card";
import {
  PieChart,
  Pie,
  Cell,
  ResponsiveContainer,
  Tooltip,
} from "recharts";
import { formatCents } from "@/lib/utils";

interface CategoryPieChartProps {
  data: { name: string; value: number; color: string }[];
}

export function CategoryPieChart({ data }: CategoryPieChartProps) {
  const total = data.reduce((s, d) => s + d.value, 0);

  return (
    <Card className="p-8">
      <CardTitle className="mb-6">Spending by Category</CardTitle>

      {data.length === 0 ? (
        <p className="text-secondary text-sm text-center py-12">
          No spending data available for this period.
        </p>
      ) : (
        <>
          <ResponsiveContainer width="100%" height={240}>
            <PieChart>
              <Pie
                data={data}
                cx="50%"
                cy="50%"
                innerRadius={60}
                outerRadius={100}
                paddingAngle={3}
                dataKey="value"
                strokeWidth={0}
              >
                {data.map((entry) => (
                  <Cell key={entry.name} fill={entry.color} />
                ))}
              </Pie>
              <Tooltip
                formatter={(value) => formatCents(Number(value))}
                contentStyle={{
                  background: "#1e293b",
                  border: "none",
                  borderRadius: "8px",
                  color: "#fff",
                  fontSize: "12px",
                  fontWeight: 600,
                }}
              />
            </PieChart>
          </ResponsiveContainer>

          <div className="space-y-2 mt-4">
            {data.map((item) => (
              <div
                key={item.name}
                className="flex items-center justify-between text-sm"
              >
                <div className="flex items-center gap-2">
                  <span
                    className="w-3 h-3 rounded-full"
                    style={{ backgroundColor: item.color }}
                  />
                  <span className="font-medium">{item.name}</span>
                </div>
                <div className="flex items-center gap-3">
                  <span className="text-secondary tabular-nums">
                    {((item.value / total) * 100).toFixed(0)}%
                  </span>
                  <span className="font-bold tabular-nums">
                    {formatCents(item.value)}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </>
      )}
    </Card>
  );
}
