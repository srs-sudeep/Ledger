"use client";

import { useState, useMemo } from "react";
import { Card, CardTitle } from "@/components/ui/card";
import { formatCents } from "@/lib/utils";
import { ArrowUpDown, Search } from "lucide-react";
import type { Expense } from "@/lib/types";

interface PersonalExpenseTableProps {
  expenses: Expense[];
}

type SortKey = "date" | "amount" | "title";
type SortDir = "asc" | "desc";

export function PersonalExpenseTable({ expenses }: PersonalExpenseTableProps) {
  const [search, setSearch] = useState("");
  const [sortKey, setSortKey] = useState<SortKey>("date");
  const [sortDir, setSortDir] = useState<SortDir>("desc");

  const toggleSort = (key: SortKey) => {
    if (sortKey === key) {
      setSortDir(sortDir === "asc" ? "desc" : "asc");
    } else {
      setSortKey(key);
      setSortDir("desc");
    }
  };

  const filtered = useMemo(() => {
    let result = [...expenses];

    if (search) {
      const q = search.toLowerCase();
      result = result.filter(
        (e) =>
          e.title.toLowerCase().includes(q) ||
          e.categories?.name?.toLowerCase().includes(q)
      );
    }

    result.sort((a, b) => {
      let cmp = 0;
      if (sortKey === "date") cmp = a.date.localeCompare(b.date);
      else if (sortKey === "amount") cmp = a.amount - b.amount;
      else cmp = a.title.localeCompare(b.title);
      return sortDir === "desc" ? -cmp : cmp;
    });

    return result;
  }, [expenses, search, sortKey, sortDir]);

  return (
    <Card className="overflow-hidden p-0">
      <div className="px-8 py-6 flex items-center justify-between gap-4">
        <CardTitle>All Transactions</CardTitle>
        <div className="relative w-64">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-outline" />
          <input
            className="pl-10 pr-4 py-2 bg-surface-container-low rounded-full text-sm w-full focus:ring-1 focus:ring-surface-tint/20 outline-none border-none font-body"
            placeholder="Filter transactions..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </div>
      </div>

      <table className="w-full text-left border-collapse">
        <thead>
          <tr className="bg-surface-container-low">
            <th
              className="px-8 py-3 text-[10px] font-bold uppercase text-on-surface-variant tracking-widest font-label cursor-pointer hover:text-on-surface"
              onClick={() => toggleSort("date")}
            >
              <span className="flex items-center gap-1">
                Date
                <ArrowUpDown size={12} />
              </span>
            </th>
            <th
              className="px-8 py-3 text-[10px] font-bold uppercase text-on-surface-variant tracking-widest font-label cursor-pointer hover:text-on-surface"
              onClick={() => toggleSort("title")}
            >
              <span className="flex items-center gap-1">
                Payee / Category
                <ArrowUpDown size={12} />
              </span>
            </th>
            <th
              className="px-8 py-3 text-[10px] font-bold uppercase text-on-surface-variant tracking-widest text-right font-label cursor-pointer hover:text-on-surface"
              onClick={() => toggleSort("amount")}
            >
              <span className="flex items-center gap-1 justify-end">
                Amount
                <ArrowUpDown size={12} />
              </span>
            </th>
          </tr>
        </thead>
        <tbody className="text-sm">
          {filtered.length === 0 ? (
            <tr>
              <td
                colSpan={3}
                className="px-8 py-12 text-center text-secondary"
              >
                {search
                  ? "No matching transactions found."
                  : "No personal expenses yet. Add one to get started!"}
              </td>
            </tr>
          ) : (
            filtered.map((expense, i) => (
              <tr
                key={expense.id}
                className={`hover:bg-surface-container-low/50 transition-colors ${
                  i % 2 === 1 ? "bg-surface-container-low/30" : ""
                }`}
              >
                <td className="px-8 py-4 text-secondary tabular-nums whitespace-nowrap">
                  {new Date(expense.date).toLocaleDateString("en-US", {
                    month: "short",
                    day: "numeric",
                    year: "numeric",
                  })}
                </td>
                <td className="px-8 py-4">
                  <div className="flex items-center gap-3">
                    <div
                      className="w-8 h-8 rounded-[0.5rem] bg-surface-container flex items-center justify-center"
                      style={{
                        color: expense.categories?.color || "#0053db",
                      }}
                    >
                      <span className="material-symbols-outlined text-[18px]">
                        {expense.categories?.icon || "receipt_long"}
                      </span>
                    </div>
                    <div>
                      <p className="font-semibold">{expense.title}</p>
                      <p className="text-xs text-secondary">
                        {expense.categories?.name || "Uncategorized"}
                      </p>
                    </div>
                  </div>
                </td>
                <td className="px-8 py-4 text-right font-bold tabular-nums">
                  -{formatCents(expense.amount)}
                </td>
              </tr>
            ))
          )}
        </tbody>
      </table>
    </Card>
  );
}
