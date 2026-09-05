import { Card, CardTitle } from "@/components/ui/card";
import { formatCents } from "@/lib/utils";
import type { LedgerTransaction } from "@/lib/types";

function DetailRow({ label, value }: { label: string; value?: string | null }) {
  if (!value) return null;
  return (
    <div className="flex flex-col gap-1 rounded-xl bg-surface-container-low px-3 py-2">
      <p className="text-[11px] uppercase tracking-[0.16em] text-secondary">{label}</p>
      <p className="text-sm text-on-surface">{value}</p>
    </div>
  );
}

function cleanNotes(value: string | null) {
  return value?.replace(/\s*\|\s*import:[^|]+$/i, "").trim() ?? null;
}

export function TransactionDetailPanel({
  transaction,
  showTitle = true,
  className = "",
}: {
  transaction: LedgerTransaction | null;
  showTitle?: boolean;
  className?: string;
}) {
  return (
    <Card className={`p-5 ${className}`}>
      {showTitle && <CardTitle className="mb-4">Transaction details</CardTitle>}
      {!transaction && (
        <div className="rounded-2xl bg-surface-container-low p-5 text-sm text-secondary">
          Select any transaction to inspect the full description, account path, translated label,
          and original source text.
        </div>
      )}
      {transaction && (
        <div className="space-y-4">
          <div className="rounded-2xl bg-surface-container-low p-4">
            <p className="text-[11px] uppercase tracking-[0.18em] text-secondary">
              {transaction.tx_type}
            </p>
            <p className="mt-2 text-xl font-bold">{transaction.title}</p>
            <p
              className={`mt-3 text-2xl font-bold tabular-nums ${
                transaction.signed_amount > 0
                  ? "text-emerald-700"
                  : transaction.signed_amount < 0
                    ? "text-rose-700"
                    : "text-on-surface"
              }`}
            >
              {transaction.signed_amount > 0 ? "+" : transaction.signed_amount < 0 ? "-" : ""}
              {formatCents(Math.abs(transaction.signed_amount), transaction.currency)}
            </p>
          </div>

          <div className="grid gap-2">
            <DetailRow label="Date" value={transaction.date} />
            <DetailRow label="Account" value={transaction.account_name} />
            <DetailRow label="Counterparty" value={transaction.counterparty_account_name} />
            <DetailRow label="Category" value={transaction.category_name} />
            <DetailRow label="Display label" value={transaction.merchant_display} />
            <DetailRow label="Original label" value={transaction.merchant_original} />
            <DetailRow label="Notes" value={cleanNotes(transaction.notes)} />
          </div>
        </div>
      )}
    </Card>
  );
}
