"use client";

import { Card, CardTitle } from "@/components/ui/card";
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  Legend,
  CartesianGrid,
} from "recharts";
import { formatCents } from "@/lib/utils";

interface PersonalVsGroupChartProps {
  data: { month: string; personal: number; group: number }[];
}

export function PersonalVsGroupChart({ data }: PersonalVsGroupChartProps) {
  return (
    <Card className="p-8">
      <CardTitle className="mb-6">Personal vs Group Spending</CardTitle>

      {data.length === 0 ? (
        <p className="text-secondary text-sm text-center py-12">
          No spending data available for this period.
        </p>
      ) : (
        <ResponsiveContainer width="100%" height={300}>
          <BarChart data={data} barCategoryGap="20%">
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
              formatter={(value, name) => [
                formatCents(Number(value)),
                name === "personal" ? "Personal" : "Group",
              ]}
              contentStyle={{
                background: "#1e293b",
                border: "none",
                borderRadius: "8px",
                color: "#fff",
                fontSize: "12px",
                fontWeight: 600,
              }}
            />
            <Legend
              formatter={(value) =>
                value === "personal" ? "Personal" : "Group"
              }
              wrapperStyle={{ fontSize: "12px", fontWeight: 600 }}
            />
            <Bar
              dataKey="personal"
              fill="#00174b"
              radius={[4, 4, 0, 0]}
              name="personal"
            />
            <Bar
              dataKey="group"
              fill="#b4c5ff"
              radius={[4, 4, 0, 0]}
              name="group"
            />
          </BarChart>
        </ResponsiveContainer>
      )}
    </Card>
  );
}
