import type { LucideIcon } from "lucide-react";
import { Card } from "@/components/ui/card";
import { cn, formatCents } from "@/lib/utils";

type Tone = "primary" | "positive" | "negative" | "neutral" | "activity";

const toneClasses: Record<Tone, string> = {
  primary: "summary-card-primary border-none shadow-ambient-lg",
  positive: "summary-card-positive",
  negative: "summary-card-negative",
  neutral: "summary-card-neutral",
  activity: "summary-card-activity",
};

export function SummaryCard({
  title,
  value,
  subtitle,
  helper,
  tone = "neutral",
  currency = "JPY",
  icon: Icon,
  emphasized = false,
}: {
  title: string;
  value: number;
  subtitle?: string;
  helper?: string;
  tone?: Tone;
  currency?: string;
  icon?: LucideIcon;
  emphasized?: boolean;
}) {
  const isPrimary = tone === "primary";
  return (
    <Card
      className={cn(
        "overflow-hidden p-5",
        toneClasses[tone],
        emphasized && "md:col-span-2 lg:col-span-2 xl:col-span-2"
      )}
    >
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0">
          <p
            className={cn(
              "text-[11px] uppercase tracking-[0.18em]",
              isPrimary ? "text-white/75" : "text-secondary"
            )}
          >
            {title}
          </p>
          <p
            className={cn(
              "mt-3 text-2xl font-bold tabular-nums break-words",
              emphasized && "text-3xl",
              isPrimary ? "text-white" : "text-on-surface"
            )}
          >
            {formatCents(value, currency)}
          </p>
        </div>
        {Icon && (
          <div
            className={cn(
              "rounded-2xl p-3",
              isPrimary ? "bg-white/10 text-white" : "bg-white/70 text-on-surface"
            )}
          >
            <Icon size={18} />
          </div>
        )}
      </div>
      {(subtitle || helper) && (
        <div className="mt-4 space-y-1">
          {subtitle && (
            <p className={cn("text-sm font-medium break-words", isPrimary ? "text-white/90" : "text-on-surface")}>
              {subtitle}
            </p>
          )}
          {helper && (
            <p className={cn("text-xs break-words", isPrimary ? "text-white/75" : "text-secondary")}>{helper}</p>
          )}
        </div>
      )}
    </Card>
  );
}
