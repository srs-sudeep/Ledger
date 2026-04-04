"use client";

import { useState, useMemo } from "react";
import { Tabs, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { CategoryPieChart } from "./category-pie-chart";
import { MonthlyBurnRate } from "./monthly-burn-rate";
import { PersonalVsGroupChart } from "./personal-vs-group";
import { formatCents } from "@/lib/utils";
import { useCurrency } from "@/components/currency/currency-provider";

interface ExpenseData {
  amount: number;
  date: string;
  category_id: string | null;
  categories: { name: string; icon: string; color: string } | { name: string; icon: string; color: string }[] | null;
}

interface AnalyticsDashboardProps {
  personalExpenses: ExpenseData[];
  groupExpenses: ExpenseData[];
}

type TimeRange = "3m" | "6m" | "12m";

export function AnalyticsDashboard({
  personalExpenses,
  groupExpenses,
}: AnalyticsDashboardProps) {
  const currency = useCurrency();
  const [range, setRange] = useState<TimeRange>("6m");

  const cutoff = useMemo(() => {
    const d = new Date();
    const months = range === "3m" ? 3 : range === "6m" ? 6 : 12;
    d.setMonth(d.getMonth() - months);
    return d.toISOString().split("T")[0];
  }, [range]);

  const filteredPersonal = useMemo(
    () => personalExpenses.filter((e) => e.date >= cutoff),
    [personalExpenses, cutoff]
  );

  const filteredGroup = useMemo(
    () => groupExpenses.filter((e) => e.date >= cutoff),
    [groupExpenses, cutoff]
  );

  // Category breakdown data
  const categoryData = useMemo(() => {
    const map: Record<string, { name: string; value: number; color: string }> =
      {};
    filteredPersonal.forEach((e) => {
      const cat = Array.isArray(e.categories) ? e.categories[0] : e.categories;
      const name = cat?.name || "Other";
      const color = cat?.color || "#9E9E9E";
      if (!map[name]) map[name] = { name, value: 0, color };
      map[name].value += e.amount;
    });
    return Object.values(map)
      .sort((a, b) => b.value - a.value)
      .slice(0, 8);
  }, [filteredPersonal]);

  // Monthly burn rate data
  const monthlyData = useMemo(() => {
    const map: Record<string, number> = {};
    filteredPersonal.forEach((e) => {
      const month = e.date.slice(0, 7); // YYYY-MM
      map[month] = (map[month] || 0) + e.amount;
    });
    return Object.entries(map)
      .sort(([a], [b]) => a.localeCompare(b))
      .map(([month, total]) => ({
        month: new Date(month + "-01").toLocaleDateString("en-US", {
          month: "short",
          year: "2-digit",
        }),
        amount: total,
      }));
  }, [filteredPersonal]);

  // Personal vs Group comparison
  const comparisonData = useMemo(() => {
    const personalByMonth: Record<string, number> = {};
    const groupByMonth: Record<string, number> = {};

    filteredPersonal.forEach((e) => {
      const month = e.date.slice(0, 7);
      personalByMonth[month] = (personalByMonth[month] || 0) + e.amount;
    });

    filteredGroup.forEach((e) => {
      const month = e.date.slice(0, 7);
      groupByMonth[month] = (groupByMonth[month] || 0) + e.amount;
    });

    const allMonths = Array.from(
      new Set([
        ...Object.keys(personalByMonth),
        ...Object.keys(groupByMonth),
      ])
    ).sort();

    return allMonths.map((month) => ({
      month: new Date(month + "-01").toLocaleDateString("en-US", {
        month: "short",
        year: "2-digit",
      }),
      personal: personalByMonth[month] || 0,
      group: groupByMonth[month] || 0,
    }));
  }, [filteredPersonal, filteredGroup]);

  const totalPersonal = filteredPersonal.reduce((s, e) => s + e.amount, 0);
  const totalGroup = filteredGroup.reduce((s, e) => s + e.amount, 0);

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div className="flex items-center gap-6">
          <div>
            <p className="text-[10px] font-bold uppercase text-secondary tracking-widest">
              Personal Total
            </p>
            <p className="font-headline font-extrabold text-xl tabular-nums">
              {formatCents(totalPersonal, currency)}
            </p>
          </div>
          <div>
            <p className="text-[10px] font-bold uppercase text-secondary tracking-widest">
              Group Total
            </p>
            <p className="font-headline font-extrabold text-xl tabular-nums">
              {formatCents(totalGroup, currency)}
            </p>
          </div>
        </div>

        <Tabs value={range} onValueChange={(v) => setRange(v as TimeRange)}>
          <TabsList>
            <TabsTrigger value="3m">3M</TabsTrigger>
            <TabsTrigger value="6m">6M</TabsTrigger>
            <TabsTrigger value="12m">12M</TabsTrigger>
          </TabsList>
        </Tabs>
      </div>

      <div className="grid grid-cols-12 gap-8">
        <div className="col-span-12 lg:col-span-5">
          <CategoryPieChart data={categoryData} />
        </div>
        <div className="col-span-12 lg:col-span-7">
          <MonthlyBurnRate data={monthlyData} />
        </div>
      </div>

      <PersonalVsGroupChart data={comparisonData} />
    </div>
  );
}
