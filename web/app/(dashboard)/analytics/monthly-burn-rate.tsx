"use client";

import { Card, CardTitle } from "@/components/ui/card";
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  CartesianGrid,
} from "recharts";
import { formatCents } from "@/lib/utils";

interface MonthlyBurnRateProps {
  data: { month: string; amount: number }[];
}

export function MonthlyBurnRate({ data }: MonthlyBurnRateProps) {
  return (
    <Card className="p-8">
      <CardTitle className="mb-6">Monthly Burn Rate</CardTitle>

      {data.length === 0 ? (
        <p className="text-secondary text-sm text-center py-12">
          No spending data available for this period.
        </p>
      ) : (
        <ResponsiveContainer width="100%" height={300}>
          <LineChart data={data}>
            <CartesianGrid
              strokeDasharray="3 3"
              stroke="rgba(198, 198, 205, 0.15)"
              vertical={false}
            />
            <XAxis
              dataKey="month"
              tick={{ fontSize: 11, fontWeight: 600, fill: "#9ca3af" }}
              axisLine={false}
              tickLine={false}
            />
            <YAxis
              tick={{ fontSize: 11, fill: "#9ca3af" }}
              axisLine={false}
              tickLine={false}
              tickFormatter={(v) => `$${(v / 100).toFixed(0)}`}
              width={60}
            />
            <Tooltip
              formatter={(value) => [formatCents(Number(value)), "Spent"]}
              contentStyle={{
                background: "#1e293b",
                border: "none",
                borderRadius: "8px",
                color: "#fff",
                fontSize: "12px",
                fontWeight: 600,
              }}
            />
            <Line
              type="monotone"
              dataKey="amount"
              stroke="#0053db"
              strokeWidth={2.5}
              dot={{ fill: "#0053db", r: 4, strokeWidth: 0 }}
              activeDot={{ r: 6, fill: "#0053db" }}
            />
          </LineChart>
        </ResponsiveContainer>
      )}
    </Card>
  );
}
