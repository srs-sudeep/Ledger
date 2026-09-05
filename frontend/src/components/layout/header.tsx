import { useLocation, useNavigate } from "react-router-dom";
import { Bell, ChevronRight, LogOut } from "lucide-react";
import { BrandLogo } from "@/components/BrandLogo";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/contexts/AuthContext";
import { getInitials } from "@/lib/utils";

const pageMeta: { match: RegExp; title: string; subtitle: string }[] = [
  { match: /^\/dashboard/, title: "Dashboard", subtitle: "Track balances, spend, and recent activity." },
  { match: /^\/accounts/, title: "Accounts", subtitle: "Review balances, income, and transfers across your wallets." },
  { match: /^\/transactions/, title: "Transactions", subtitle: "Search and sort your full ledger in one place." },
  { match: /^\/groups/, title: "Groups", subtitle: "Split shared costs and settle up cleanly." },
  { match: /^\/budgets/, title: "Budgets", subtitle: "Stay ahead of recurring costs and category targets." },
  { match: /^\/analytics/, title: "Analytics", subtitle: "See what is driving your spending and cash flow." },
  { match: /^\/settings/, title: "Settings", subtitle: "Manage your profile, exports, and import tools." },
];

export function Header() {
  const pathname = useLocation().pathname;
  const navigate = useNavigate();
  const { logout, user } = useAuth();
  const meta = pageMeta.find((item) => item.match.test(pathname)) ?? {
    title: "Ledger",
    subtitle: "Manage your personal finance workspace.",
  };
  const name = user?.full_name?.trim() || user?.email || "Ledger user";

  return (
    <header className="page-topbar sticky top-0 z-40 border-b border-outline/10 px-4 py-4 backdrop-blur-xl md:px-8">
      <div className="mx-auto flex max-w-[1520px] items-center justify-between gap-4">
        <div className="min-w-0">
          <BrandLogo
            size={32}
            showWordmark
            wordmarkClassName="text-xl font-black"
            className="md:hidden"
          />
          <div className="hidden md:block">
            <div className="mb-1 flex items-center gap-2 text-[11px] font-semibold uppercase tracking-[0.18em] text-secondary">
              <span>Workspace</span>
              <ChevronRight className="h-3.5 w-3.5" />
              <span>{meta.title}</span>
            </div>
            <div>
              <h1 className="text-2xl font-headline font-bold text-on-surface">{meta.title}</h1>
              <p className="text-sm text-secondary">{meta.subtitle}</p>
            </div>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <button
            type="button"
            className="hidden h-11 w-11 items-center justify-center rounded-2xl border border-outline/10 bg-white/70 text-secondary shadow-sm transition hover:text-on-surface md:inline-flex"
            aria-label="Notifications"
          >
            <Bell className="h-4.5 w-4.5" />
          </button>
          <div className="hidden items-center gap-3 rounded-2xl border border-outline/10 bg-white/80 px-3 py-2 shadow-sm md:flex">
            <div className="flex h-10 w-10 items-center justify-center rounded-2xl bg-[#e9f0ff] text-sm font-bold text-primary">
              {getInitials(name)}
            </div>
            <div className="min-w-0">
              <p className="truncate text-sm font-semibold text-on-surface">{name}</p>
              <p className="truncate text-xs text-secondary">{user?.email}</p>
            </div>
          </div>
          <Button
            type="button"
            variant="outline"
            size="sm"
            className="gap-2 rounded-2xl bg-white/80"
            onClick={() => {
              logout();
              navigate("/login");
            }}
          >
            <LogOut className="h-4 w-4" />
            <span className="hidden sm:inline">Sign out</span>
          </Button>
        </div>
      </div>
    </header>
  );
}
