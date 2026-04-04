"use client";

import Link from "next/link";
import {
  Landmark,
  CreditCard,
  Wallet,
  Banknote,
  CircleDollarSign,
  ArrowRight,
} from "lucide-react";
import { Card, CardTitle } from "@/components/ui/card";
import { formatCents } from "@/lib/utils";
import type { Account, AccountType } from "@/lib/types";
import { useCurrency } from "@/components/currency/currency-provider";

const typeIcons: Record<AccountType, typeof Landmark> = {
  bank: Landmark,
  credit_card: CreditCard,
  debit_card: CreditCard,
  wallet: Wallet,
  cash: Banknote,
  other: CircleDollarSign,
};

interface AccountsOverviewProps {
  accounts: Account[];
}

export function AccountsOverview({ accounts }: AccountsOverviewProps) {
  const defaultCurrency = useCurrency();

  if (accounts.length === 0) return null;

  const total = accounts.reduce((sum, a) => sum + a.balance, 0);

  return (
    <Card className="p-8">
      <div className="flex items-center justify-between mb-4">
        <CardTitle>Accounts</CardTitle>
        <Link
          href="/accounts"
          className="text-xs font-medium text-primary flex items-center gap-1 hover:underline"
        >
          View All <ArrowRight size={12} />
        </Link>
      </div>

      <p className="text-xs text-secondary mb-4">
        Total:{" "}
        <span className="font-semibold text-on-surface tabular-nums">
          {formatCents(total, defaultCurrency)}
        </span>
      </p>

      <div className="space-y-3">
        {accounts.map((account) => {
          const Icon = typeIcons[account.type] || CircleDollarSign;
          return (
            <div
              key={account.id}
              className="flex items-center justify-between py-1"
            >
              <div className="flex items-center gap-3">
                <div
                  className="w-8 h-8 rounded-lg flex items-center justify-center"
                  style={{
                    backgroundColor: (account.color || "#6366f1") + "18",
                  }}
                >
                  <Icon
                    size={16}
                    style={{ color: account.color || "#6366f1" }}
                  />
                </div>
                <span className="text-sm font-medium text-on-surface">
                  {account.name}
                </span>
              </div>
              <span className="text-sm font-semibold tabular-nums text-on-surface">
                {formatCents(account.balance, account.currency)}
              </span>
            </div>
          );
        })}
      </div>
    </Card>
  );
}
