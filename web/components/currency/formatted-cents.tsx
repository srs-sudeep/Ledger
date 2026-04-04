"use client";

import { formatCents } from "@/lib/utils";
import { useCurrency } from "./currency-provider";

export function FormattedCents({
  amount,
  currency,
  className,
}: {
  amount: number;
  /** When omitted, uses the signed-in user default from settings */
  currency?: string;
  className?: string;
}) {
  const defaultCurrency = useCurrency();
  return (
    <span className={className}>
      {formatCents(amount, currency ?? defaultCurrency)}
    </span>
  );
}
