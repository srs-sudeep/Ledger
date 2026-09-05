import { ArrowDownLeft, ArrowLeftRight, ArrowUpRight } from "lucide-react";
import { cn, formatCents } from "@/lib/utils";
import type { LedgerTransaction } from "@/lib/types";

function toneForType(row: LedgerTransaction) {
  if (row.tx_type === "income") return "bg-emerald-100 text-emerald-700";
  if (row.tx_type === "expense") return "bg-rose-100 text-rose-700";
  return "bg-blue-100 text-blue-700";
}

function iconForDirection(row: LedgerTransaction) {
  if (row.direction === "inflow") return ArrowDownLeft;
  if (row.direction === "outflow") return ArrowUpRight;
  return ArrowLeftRight;
}

function signedClass(value: number) {
  if (value > 0) return "text-emerald-700";
  if (value < 0) return "text-rose-700";
  return "text-secondary";
}

function formatSigned(row: LedgerTransaction) {
  const sign = row.signed_amount > 0 ? "+" : row.signed_amount < 0 ? "-" : "";
  return `${sign}${formatCents(Math.abs(row.signed_amount), row.currency)}`;
}

function cleanNotes(value: string | null) {
  return value?.replace(/\s*\|\s*import:[^|]+$/i, "").trim() ?? null;
}

export function TransactionListItem({
  row,
  selected,
  onClick,
}: {
  row: LedgerTransaction;
  selected?: boolean;
  onClick?: () => void;
}) {
  const Icon = iconForDirection(row);

  return (
    <button
      type="button"
      onClick={onClick}
      className={cn(
        "w-full rounded-2xl border px-4 py-4 text-left transition-all duration-150",
        selected
          ? "border-surface-tint bg-surface-container-low shadow-ambient"
          : "border-outline/10 bg-white hover:border-surface-tint/30 hover:bg-surface-container-lowest"
      )}
    >
      <div className="flex items-start justify-between gap-3">
        <div className="min-w-0 flex gap-3">
          <div className="rounded-2xl bg-surface-container p-2.5 text-on-surface">
            <Icon size={18} />
          </div>
          <div className="min-w-0">
            <div className="flex items-center gap-2 flex-wrap">
              <p className="font-semibold truncate">{row.title}</p>
              <span className={cn("chip", toneForType(row))}>{row.tx_type}</span>
              {row.category_name && (
                <span className="chip bg-surface-container text-secondary">{row.category_name}</span>
              )}
            </div>
            <p className="mt-1 text-sm text-secondary">
              {row.date}
              {row.account_name ? ` · ${row.account_name}` : ""}
              {row.counterparty_account_name ? ` -> ${row.counterparty_account_name}` : ""}
            </p>
            {row.merchant_original &&
              row.merchant_display &&
              row.merchant_original !== row.merchant_display && (
                <p className="mt-1 text-xs text-secondary truncate">{row.merchant_original}</p>
              )}
            {cleanNotes(row.notes) && (
              <p className="mt-2 text-sm text-on-surface/80 line-clamp-2">{cleanNotes(row.notes)}</p>
            )}
          </div>
        </div>
        <div className="shrink-0 text-right">
          <p className={cn("font-bold tabular-nums", signedClass(row.signed_amount))}>
            {formatSigned(row)}
          </p>
          <p className="mt-1 text-xs text-secondary">Click for details</p>
        </div>
      </div>
    </button>
  );
}
