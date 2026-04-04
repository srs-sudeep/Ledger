"use client";

import { Card, CardTitle } from "@/components/ui/card";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  Cell,
} from "recharts";
import { formatCents } from "@/lib/utils";
import { useCurrency } from "@/components/currency/currency-provider";

interface SpendingChartProps {
  data: { day: string; amount: number }[];
}

export function SpendingChart({ data }: SpendingChartProps) {
  const currency = useCurrency();
  const maxAmount = Math.max(...data.map((d) => d.amount), 1);

  return (
    <Card className="p-8">
      <div className="flex items-center justify-between mb-8">
        <CardTitle>Weekly Personal Spending</CardTitle>
        <div className="flex items-center gap-2">
          <span className="w-3 h-3 rounded-full bg-primary-container" />
          <span className="text-[10px] font-bold uppercase text-secondary tracking-wide">
            Past 7 Days
          </span>
        </div>
      </div>

      <ResponsiveContainer width="100%" height={200}>
        <BarChart data={data} barCategoryGap="20%">
          <XAxis
            dataKey="day"
            tick={{ fontSize: 11, fontWeight: 700, fill: "#9ca3af" }}
            axisLine={false}
            tickLine={false}
          />
          <YAxis hide />
          <Tooltip
            formatter={(value) => [
              formatCents(Number(value), currency),
              "Spent",
            ]}
            contentStyle={{
              background: "#1e293b",
              border: "none",
              borderRadius: "8px",
              color: "#fff",
              fontSize: "12px",
              fontWeight: 600,
            }}
            cursor={{ fill: "rgba(0,0,0,0.03)" }}
          />
          <Bar dataKey="amount" radius={[6, 6, 0, 0]}>
            {data.map((entry, index) => (
              <Cell
                key={`cell-${index}`}
                fill={
                  entry.amount === maxAmount ? "#00174b" : "#e2e8f0"
                }
              />
            ))}
          </Bar>
        </BarChart>
      </ResponsiveContainer>
    </Card>
  );
}
