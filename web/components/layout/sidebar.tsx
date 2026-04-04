"use client";

import Link from "next/link";
import { usePathname, useRouter } from "next/navigation";
import {
  LayoutDashboard,
  Receipt,
  BarChart3,
  Users,
  HelpCircle,
  LogOut,
  Plus,
} from "lucide-react";
import { cn } from "@/lib/utils";
import { Button } from "@/components/ui/button";
import { createClient } from "@/lib/supabase/client";

const navItems = [
  { href: "/dashboard", label: "Dashboard", icon: LayoutDashboard },
  { href: "/personal", label: "Transactions", icon: Receipt },
  { href: "/groups", label: "Groups", icon: Users },
  { href: "/analytics", label: "Analytics", icon: BarChart3 },
];

export function Sidebar() {
  const pathname = usePathname();
  const router = useRouter();
  const supabase = createClient();

  const handleSignOut = async () => {
    await supabase.auth.signOut();
    router.push("/login");
  };

  return (
    <aside className="h-screen w-64 fixed left-0 top-0 bg-surface-container-low flex flex-col py-8 px-4 z-50">
      <div className="mb-10 px-2">
        <h1 className="text-lg font-bold text-on-surface font-headline tracking-tight">
          The Ledger
        </h1>
        <p className="text-[10px] text-secondary font-medium tracking-wide uppercase">
          Financial Platform
        </p>
      </div>

      <nav className="flex-1 space-y-1">
        {navItems.map((item) => {
          const isActive = pathname === item.href || pathname.startsWith(item.href + "/");
          return (
            <Link
              key={item.href}
              href={item.href}
              className={cn(
                "flex items-center gap-3 px-3 py-2.5 rounded-[0.75rem] text-sm font-medium transition-all duration-200",
                isActive
                  ? "text-on-surface bg-surface-container-lowest shadow-sm translate-x-1 font-semibold"
                  : "text-secondary hover:text-on-surface hover:bg-surface-container"
              )}
            >
              <item.icon size={20} />
              <span>{item.label}</span>
            </Link>
          );
        })}
      </nav>

      <div className="mt-auto space-y-1 pt-4">
        <Link href="/personal">
          <Button className="w-full mb-4 gap-2">
            <Plus size={18} />
            Add Expense
          </Button>
        </Link>
        <button
          className="flex items-center gap-3 px-3 py-2.5 rounded-[0.75rem] text-secondary hover:text-on-surface transition-all text-sm font-medium w-full"
        >
          <HelpCircle size={20} />
          <span>Help</span>
        </button>
        <button
          onClick={handleSignOut}
          className="flex items-center gap-3 px-3 py-2.5 rounded-[0.75rem] text-secondary hover:text-on-surface transition-all text-sm font-medium w-full"
        >
          <LogOut size={20} />
          <span>Sign Out</span>
        </button>
      </div>
    </aside>
  );
}
