"use client";

import { Bell, Settings, Search } from "lucide-react";
import { Avatar } from "@/components/ui/avatar";
import type { Profile } from "@/lib/types";

interface HeaderProps {
  profile: Profile | null;
}

export function Header({ profile }: HeaderProps) {
  return (
    <header className="w-full sticky top-0 z-40 bg-surface-container-low/80 backdrop-blur-xl flex justify-between items-center px-8 py-4">
      <div className="flex items-center gap-8">
        <span className="text-xl font-black text-on-surface tracking-tight font-headline">
          The Ledger
        </span>
        <div className="relative hidden md:block">
          <Search className="absolute left-3 top-1/2 -translate-y-1/2 h-4 w-4 text-outline" />
          <input
            className="pl-10 pr-4 py-2 bg-surface-container rounded-full text-sm w-64 focus:ring-1 focus:ring-surface-tint/20 outline-none border-none transition-all font-body"
            placeholder="Search transactions..."
            type="text"
          />
        </div>
      </div>
      <div className="flex items-center gap-3">
        <button className="p-2 text-secondary hover:bg-surface-container rounded-full transition-colors">
          <Bell size={20} />
        </button>
        <button className="p-2 text-secondary hover:bg-surface-container rounded-full transition-colors">
          <Settings size={20} />
        </button>
        <Avatar
          src={profile?.avatar_url}
          fallback={profile?.full_name || "User"}
          size="sm"
        />
      </div>
    </header>
  );
}
