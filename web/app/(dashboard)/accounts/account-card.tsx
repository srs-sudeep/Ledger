"use client";

import {
  Landmark,
  CreditCard,
  Wallet,
  Banknote,
  CircleDollarSign,
  MoreHorizontal,
  Trash2,
  Star,
} from "lucide-react";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { createClient } from "@/lib/supabase/client";
import { formatCents } from "@/lib/utils";
import type { Account, AccountType } from "@/lib/types";

const typeConfig: Record<
  AccountType,
  { label: string; icon: typeof Landmark; gradient: string }
> = {
  bank: {
    label: "Bank Account",
    icon: Landmark,
    gradient: "from-blue-500/10 to-blue-600/5",
  },
  credit_card: {
    label: "Credit Card",
    icon: CreditCard,
    gradient: "from-purple-500/10 to-purple-600/5",
  },
  debit_card: {
    label: "Debit Card",
    icon: CreditCard,
    gradient: "from-emerald-500/10 to-emerald-600/5",
  },
  wallet: {
    label: "Wallet",
    icon: Wallet,
    gradient: "from-amber-500/10 to-amber-600/5",
  },
  cash: {
    label: "Cash",
    icon: Banknote,
    gradient: "from-green-500/10 to-green-600/5",
  },
  other: {
    label: "Other",
    icon: CircleDollarSign,
    gradient: "from-gray-500/10 to-gray-600/5",
  },
};

interface AccountCardProps {
  account: Account;
}

export function AccountCard({ account }: AccountCardProps) {
  const [showMenu, setShowMenu] = useState(false);
  const router = useRouter();
  const supabase = createClient();
  const config = typeConfig[account.type] || typeConfig.other;
  const Icon = config.icon;

  const handleDelete = async () => {
    await supabase.from("accounts").delete().eq("id", account.id);
    router.refresh();
  };

  const handleSetDefault = async () => {
    await supabase
      .from("accounts")
      .update({ is_default: false })
      .eq("user_id", account.user_id);
    await supabase
      .from("accounts")
      .update({ is_default: true })
      .eq("id", account.id);
    setShowMenu(false);
    router.refresh();
  };

  return (
    <div
      className={`relative bg-gradient-to-br ${config.gradient} bg-surface-container-lowest rounded-xl shadow-ambient p-8 transition-all duration-200 hover:shadow-ambient-lg`}
    >
      <div className="flex items-start justify-between">
        <div className="flex items-center gap-3">
          <div
            className="w-10 h-10 rounded-lg flex items-center justify-center"
            style={{ backgroundColor: account.color || "#6366f1" + "18" }}
          >
            <Icon
              size={20}
              style={{ color: account.color || "#6366f1" }}
            />
          </div>
          <div>
            <p className="text-sm font-semibold text-on-surface">
              {account.name}
            </p>
            <p className="text-xs text-secondary">{config.label}</p>
          </div>
        </div>

        <div className="relative">
          <button
            onClick={() => setShowMenu(!showMenu)}
            className="p-1.5 rounded-lg text-secondary hover:text-on-surface hover:bg-surface-container transition-colors"
          >
            <MoreHorizontal size={16} />
          </button>
          {showMenu && (
            <div className="absolute right-0 top-8 bg-surface-container-lowest rounded-xl shadow-ambient-lg p-2 min-w-[140px] z-10">
              <button
                onClick={handleSetDefault}
                className="flex items-center gap-2 w-full px-3 py-2 text-sm text-on-surface hover:bg-surface-container rounded-lg transition-colors"
              >
                <Star size={14} />
                Set Default
              </button>
              <button
                onClick={handleDelete}
                className="flex items-center gap-2 w-full px-3 py-2 text-sm text-error hover:bg-error-container/30 rounded-lg transition-colors"
              >
                <Trash2 size={14} />
                Delete
              </button>
            </div>
          )}
        </div>
      </div>

      <div className="mt-6">
        <p className="text-xs text-secondary font-medium uppercase tracking-wide">
          Balance
        </p>
        <p className="text-2xl font-bold font-headline text-on-surface tabular-nums mt-1">
          {formatCents(account.balance, account.currency)}
        </p>
      </div>

      {account.is_default && (
        <div className="absolute top-3 right-14">
          <span className="text-[10px] font-semibold uppercase tracking-wider text-primary bg-primary/10 px-2 py-0.5 rounded-full">
            Default
          </span>
        </div>
      )}
    </div>
  );
}
