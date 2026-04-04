import { Card, CardTitle } from "@/components/ui/card";
import { formatCents } from "@/lib/utils";

interface BudgetProgressProps {
  categoryTotals: Record<
    string,
    { total: number; color: string; icon: string }
  >;
}

const MONTHLY_BUDGET_DEFAULT = 50000; // $500 per category default

export function BudgetProgress({ categoryTotals }: BudgetProgressProps) {
  const sorted = Object.entries(categoryTotals).sort(
    ([, a], [, b]) => b.total - a.total
  );

  if (sorted.length === 0) {
    return null;
  }

  return (
    <Card className="p-8">
      <CardTitle className="mb-6">Monthly Budget Progress</CardTitle>
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {sorted.slice(0, 8).map(([name, { total, color, icon }]) => {
          const pct = Math.min((total / MONTHLY_BUDGET_DEFAULT) * 100, 100);
          const isOver = total > MONTHLY_BUDGET_DEFAULT;

          return (
            <div key={name} className="space-y-2">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <span
                    className="material-symbols-outlined text-[16px]"
                    style={{ color }}
                  >
                    {icon}
                  </span>
                  <span className="text-sm font-semibold">{name}</span>
                </div>
                <span className="text-xs font-bold tabular-nums text-secondary">
                  {formatCents(total)} / {formatCents(MONTHLY_BUDGET_DEFAULT)}
                </span>
              </div>
              <div className="h-2 bg-surface-container-low rounded-full overflow-hidden">
                <div
                  className="h-full rounded-full transition-all duration-500"
                  style={{
                    width: `${pct}%`,
                    backgroundColor: isOver ? "#ba1a1a" : color,
                  }}
                />
              </div>
            </div>
          );
        })}
      </div>
    </Card>
  );
}
