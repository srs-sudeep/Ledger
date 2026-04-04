import Link from "next/link";
import { Card, CardTitle } from "@/components/ui/card";
import { formatCents } from "@/lib/utils";
import type { Expense } from "@/lib/types";

interface RecentTransactionsProps {
  expenses: Expense[];
  userId: string;
}

export function RecentTransactions({
  expenses,
  userId,
}: RecentTransactionsProps) {
  return (
    <Card className="overflow-hidden p-0">
      <div className="px-8 py-6 flex items-center justify-between">
        <CardTitle>Recent Transactions</CardTitle>
        <Link
          href="/personal"
          className="text-xs font-bold text-surface-tint hover:underline"
        >
          View All
        </Link>
      </div>

      <table className="w-full text-left border-collapse">
        <thead>
          <tr className="bg-surface-container-low">
            <th className="px-8 py-3 text-[10px] font-bold uppercase text-on-surface-variant tracking-widest font-label">
              Date
            </th>
            <th className="px-8 py-3 text-[10px] font-bold uppercase text-on-surface-variant tracking-widest font-label">
              Payee / Category
            </th>
            <th className="px-8 py-3 text-[10px] font-bold uppercase text-on-surface-variant tracking-widest text-right font-label">
              Amount
            </th>
          </tr>
        </thead>
        <tbody className="text-sm">
          {expenses.length === 0 ? (
            <tr>
              <td
                colSpan={3}
                className="px-8 py-8 text-center text-secondary"
              >
                No transactions yet. Add your first expense!
              </td>
            </tr>
          ) : (
            expenses.map((expense, i) => (
              <tr
                key={expense.id}
                className={`hover:bg-surface-container-low/50 transition-colors ${
                  i % 2 === 1 ? "bg-surface-container-low/30" : ""
                }`}
              >
                <td className="px-8 py-4 text-secondary tabular-nums">
                  {new Date(expense.date).toLocaleDateString("en-US", {
                    month: "short",
                    day: "numeric",
                    year: "numeric",
                  })}
                </td>
                <td className="px-8 py-4">
                  <div className="flex items-center gap-3">
                    <div className="w-8 h-8 rounded-[0.5rem] bg-surface-container flex items-center justify-center text-surface-tint">
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
                  <span
                    className={
                      expense.payer_id === userId
                        ? "text-on-surface"
                        : "text-on-tertiary-fixed-variant"
                    }
                  >
                    {expense.payer_id === userId ? "-" : "+"}
                    {formatCents(expense.amount)}
                  </span>
                </td>
              </tr>
            ))
          )}
        </tbody>
      </table>
    </Card>
  );
}
