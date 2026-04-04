import { formatCents } from "@/lib/utils";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { TrendingUp, Users, AlertTriangle, Calendar } from "lucide-react";

interface SummaryCardsProps {
  netWorth: number;
  owedToMe: number;
  iOwe: number;
  monthlySpend: number;
}

export function SummaryCards({
  netWorth,
  owedToMe,
  iOwe,
  monthlySpend,
}: SummaryCardsProps) {
  return (
    <section className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-6">
      <Card>
        <p className="text-[10px] font-semibold text-on-surface-variant uppercase tracking-widest mb-2 font-label">
          Total Net Worth
        </p>
        <div className="flex items-end justify-between">
          <h2 className="text-2xl font-extrabold font-headline tabular-nums">
            {formatCents(Math.abs(netWorth))}
          </h2>
          <Badge variant="success" className="gap-1">
            <TrendingUp size={12} />
            {netWorth >= 0 ? "+" : "-"}
          </Badge>
        </div>
      </Card>

      <Card>
        <p className="text-[10px] font-semibold text-on-surface-variant uppercase tracking-widest mb-2 font-label">
          Total Owed to Me
        </p>
        <div className="flex items-end justify-between">
          <h2 className="text-2xl font-extrabold font-headline tabular-nums text-on-tertiary-fixed-variant">
            {formatCents(owedToMe)}
          </h2>
          <Badge variant="success" className="gap-1">
            <Users size={12} />
            Groups
          </Badge>
        </div>
      </Card>

      <Card>
        <p className="text-[10px] font-semibold text-on-surface-variant uppercase tracking-widest mb-2 font-label">
          Total I Owe
        </p>
        <div className="flex items-end justify-between">
          <h2 className="text-2xl font-extrabold font-headline tabular-nums text-error">
            {formatCents(iOwe)}
          </h2>
          <Badge variant="error" className="gap-1">
            <AlertTriangle size={12} />
            Due Soon
          </Badge>
        </div>
      </Card>

      <Card>
        <p className="text-[10px] font-semibold text-on-surface-variant uppercase tracking-widest mb-2 font-label">
          Monthly Personal Spend
        </p>
        <div className="flex items-end justify-between">
          <h2 className="text-2xl font-extrabold font-headline tabular-nums">
            {formatCents(monthlySpend)}
          </h2>
          <Badge variant="muted" className="gap-1">
            <Calendar size={12} />
            This month
          </Badge>
        </div>
      </Card>
    </section>
  );
}
