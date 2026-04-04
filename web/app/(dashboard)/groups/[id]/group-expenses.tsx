import { Card } from "@/components/ui/card";
import { Avatar } from "@/components/ui/avatar";
import { formatCents } from "@/lib/utils";
import type { Expense } from "@/lib/types";

interface GroupExpensesProps {
  expenses: Expense[];
  userId: string;
}

export function GroupExpenses({ expenses, userId }: GroupExpensesProps) {
  if (expenses.length === 0) {
    return (
      <Card className="p-12 text-center">
        <p className="text-secondary">
          No expenses yet. Add the first group expense!
        </p>
      </Card>
    );
  }

  return (
    <div className="space-y-3">
      {expenses.map((expense) => {
        const isPayer = expense.payer_id === userId;

        return (
          <Card key={expense.id} className="p-5 flex items-center justify-between">
            <div className="flex items-center gap-4">
              <div
                className="w-10 h-10 rounded-2xl bg-surface-container flex items-center justify-center"
                style={{ color: expense.categories?.color || "#0053db" }}
              >
                <span className="material-symbols-outlined text-[20px]">
                  {expense.categories?.icon || "receipt_long"}
                </span>
              </div>
              <div>
                <p className="font-semibold text-sm">{expense.title}</p>
                <div className="flex items-center gap-2 mt-0.5">
                  <Avatar
                    src={expense.profiles?.avatar_url}
                    fallback={expense.profiles?.full_name || "?"}
                    size="sm"
                    className="w-4 h-4 text-[8px]"
                  />
                  <span className="text-xs text-secondary">
                    paid by{" "}
                    <span className="font-semibold">
                      {isPayer ? "You" : expense.profiles?.full_name || "Someone"}
                    </span>
                  </span>
                </div>
              </div>
            </div>

            <div className="text-right">
              <p className="font-headline font-bold tabular-nums">
                {formatCents(expense.amount)}
              </p>
              <p className="text-[10px] text-secondary mt-0.5">
                {new Date(expense.date).toLocaleDateString("en-US", {
                  month: "short",
                  day: "numeric",
                })}
              </p>
            </div>
          </Card>
        );
      })}
    </div>
  );
}
