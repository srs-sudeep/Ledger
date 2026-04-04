"use client";

import { useRouter } from "next/navigation";
import { LogOut } from "lucide-react";
import { Button } from "@/components/ui/button";
import { createClient } from "@/lib/supabase/client";

export function Header() {
  const router = useRouter();
  const supabase = createClient();

  const handleSignOut = async () => {
    await supabase.auth.signOut();
    router.push("/login");
    router.refresh();
  };

  return (
    <header className="sticky top-0 z-40 flex w-full items-center justify-between border-b border-outline/10 bg-surface-container-low/80 px-8 py-4 backdrop-blur-xl">
      <span className="font-headline text-xl font-black tracking-tight text-on-surface">
        The Ledger
      </span>
      <Button
        type="button"
        variant="outline"
        size="sm"
        className="gap-2"
        onClick={handleSignOut}
      >
        <LogOut className="h-4 w-4" aria-hidden />
        Sign out
      </Button>
    </header>
  );
}
