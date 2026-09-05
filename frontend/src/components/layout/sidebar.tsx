import { Link, useLocation, useNavigate } from "react-router-dom";
import { useTransition } from "react";
import {
  LayoutDashboard,
  Receipt,
  BarChart3,
  Users,
  Wallet,
  LogOut,
  ReceiptText,
  Loader2,
  Settings,
  PiggyBank,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/contexts/AuthContext";
import { BrandLogo } from "@/components/BrandLogo";
import { SITE_UI_TAGLINE } from "@/lib/site";
import { getInitials } from "@/lib/utils";

const navItems = [
  { href: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { href: "/accounts", label: "Accounts", icon: Wallet },
  { href: "/transactions", label: "Transactions", icon: Receipt },
  { href: "/groups", label: "Groups", icon: Users },
  { href: "/budgets", label: "Budgets", icon: PiggyBank },
  { href: "/analytics", label: "Analytics", icon: BarChart3 },
  { href: "/settings", label: "Settings", icon: Settings },
];

export function Sidebar() {
  const pathname = useLocation().pathname;
  const navigate = useNavigate();
  const { logout, user } = useAuth();
  const [isPending, startTransition] = useTransition();
  const displayName = user?.full_name?.trim() || user?.email || "Ledger user";

  const handleNav = (href: string) => {
    startTransition(() => navigate(href));
  };

  return (
    <>
      {isPending && (
        <div className="fixed top-0 left-0 right-0 z-[100] h-0.5">
          <div className="h-full bg-primary animate-progress-bar rounded-full" />
        </div>
      )}
      <aside className="sidebar-shell hidden md:flex h-screen w-72 fixed left-0 top-0 flex-col px-4 py-5 z-50">
        <div className="rounded-[28px] border border-white/70 bg-white/88 p-4 shadow-ambient">
          <BrandLogo size={38} showWordmark wordmarkClassName="text-xl" />
          <p className="mt-1 pl-[50px] text-[10px] font-semibold tracking-[0.2em] text-secondary uppercase">
            {SITE_UI_TAGLINE}
          </p>
        </div>
        <div className="mt-5 rounded-[28px] border border-white/70 bg-white/80 p-3 shadow-ambient">
          <div className="flex items-center gap-3 rounded-2xl bg-surface-container-low px-3 py-3">
            <div className="flex h-11 w-11 items-center justify-center rounded-2xl bg-[#e9f0ff] text-sm font-bold text-primary">
              {getInitials(displayName)}
            </div>
            <div className="min-w-0">
              <p className="truncate text-sm font-semibold text-on-surface">{displayName}</p>
              <p className="truncate text-xs text-secondary">{user?.email}</p>
            </div>
          </div>
        </div>
        <nav className="mt-5 flex-1 space-y-1 rounded-[28px] border border-white/70 bg-white/80 p-3 shadow-ambient">
          {navItems.map((item) => {
            const isActive =
              pathname === item.href || pathname.startsWith(item.href + "/");
            return (
              <button
                key={item.href}
                type="button"
                onClick={() => handleNav(item.href)}
                className={cn(
                  "sidebar-nav-button flex items-center gap-3 px-3.5 py-3 rounded-2xl text-sm font-medium transition-all duration-150 w-full text-left",
                  isActive
                    ? "is-active text-on-surface font-semibold"
                    : "text-secondary hover:text-on-surface"
                )}
              >
                <span
                  className={cn(
                    "flex h-10 w-10 items-center justify-center rounded-2xl transition-colors",
                    isActive ? "bg-[#e9f0ff] text-primary" : "bg-surface-container-low text-secondary"
                  )}
                >
                  <item.icon size={18} />
                </span>
                <span className="flex-1">{item.label}</span>
                {isPending && isActive && (
                  <Loader2 size={14} className="animate-spin text-primary" />
                )}
              </button>
            );
          })}
        </nav>
        <div className="mt-5 space-y-3 rounded-[28px] border border-white/70 bg-white/80 p-3 shadow-ambient">
          <Link to="/transactions">
            <Button className="w-full gap-2 rounded-2xl">
              <ReceiptText size={18} />
              Open Ledger
            </Button>
          </Link>
          <button
            type="button"
            onClick={() => {
              logout();
              navigate("/login");
            }}
            className="flex items-center gap-3 px-3.5 py-3 rounded-2xl text-secondary hover:text-on-surface hover:bg-surface-container-low transition-all duration-150 text-sm font-medium w-full"
          >
            <span className="flex h-10 w-10 items-center justify-center rounded-2xl bg-surface-container-low text-secondary">
              <LogOut size={18} />
            </span>
            <span>Sign Out</span>
          </button>
        </div>
      </aside>
    </>
  );
}
