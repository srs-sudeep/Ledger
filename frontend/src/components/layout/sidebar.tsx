import { Link, useLocation, useNavigate } from "react-router-dom";
import { useTransition } from "react";
import {
  LayoutDashboard,
  Receipt,
  BarChart3,
  Users,
  Wallet,
  LogOut,
  Plus,
  Loader2,
  Settings,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/contexts/AuthContext";
import { SITE_NAME, SITE_UI_TAGLINE } from "@/lib/site";

const navItems = [
  { href: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { href: "/accounts", label: "Accounts", icon: Wallet },
  { href: "/personal", label: "Transactions", icon: Receipt },
  { href: "/groups", label: "Groups", icon: Users },
  { href: "/analytics", label: "Analytics", icon: BarChart3 },
  { href: "/settings", label: "Settings", icon: Settings },
];

export function Sidebar() {
  const pathname = useLocation().pathname;
  const navigate = useNavigate();
  const { logout } = useAuth();
  const [isPending, startTransition] = useTransition();

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
      <aside className="hidden md:flex h-screen w-64 fixed left-0 top-0 bg-surface-container-low flex-col py-8 px-4 z-50">
        <div className="mb-10 px-2">
          <h1 className="text-lg font-bold text-on-surface font-headline tracking-tight">
            {SITE_NAME}
          </h1>
          <p className="text-[10px] text-secondary font-medium tracking-wide uppercase">
            {SITE_UI_TAGLINE}
          </p>
        </div>
        <nav className="flex-1 space-y-1">
          {navItems.map((item) => {
            const isActive =
              pathname === item.href || pathname.startsWith(item.href + "/");
            return (
              <button
                key={item.href}
                type="button"
                onClick={() => handleNav(item.href)}
                className={cn(
                  "flex items-center gap-3 px-3 py-2.5 rounded-xl text-sm font-medium transition-all duration-150 w-full text-left",
                  isActive
                    ? "text-on-surface bg-surface-container-lowest shadow-sm font-semibold"
                    : "text-secondary hover:text-on-surface hover:bg-surface-container"
                )}
              >
                <item.icon size={20} />
                <span className="flex-1">{item.label}</span>
                {isPending && isActive && (
                  <Loader2 size={14} className="animate-spin text-primary" />
                )}
              </button>
            );
          })}
        </nav>
        <div className="mt-auto space-y-1 pt-4">
          <Link to="/personal">
            <Button className="w-full mb-4 gap-2">
              <Plus size={18} />
              Add Expense
            </Button>
          </Link>
          <button
            type="button"
            onClick={() => {
              logout();
              navigate("/login");
            }}
            className="flex items-center gap-3 px-3 py-2.5 rounded-xl text-secondary hover:text-on-surface hover:bg-surface-container transition-all duration-150 text-sm font-medium w-full"
          >
            <LogOut size={20} />
            <span>Sign Out</span>
          </button>
        </div>
      </aside>
    </>
  );
}
