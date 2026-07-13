import { useNavigate } from "react-router-dom";
import { SITE_NAME } from "@/lib/site";
import { LogOut } from "lucide-react";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/contexts/AuthContext";

export function Header() {
  const navigate = useNavigate();
  const { logout } = useAuth();

  return (
    <header className="sticky top-0 z-40 flex w-full items-center justify-between border-b border-outline/10 bg-surface-container-low/80 px-4 py-4 backdrop-blur-xl md:px-8">
      <span className="font-headline text-xl font-black tracking-tight text-on-surface md:hidden">
        {SITE_NAME}
      </span>
      <div className="hidden md:block" />
      <Button
        type="button"
        variant="outline"
        size="sm"
        className="gap-2"
        onClick={() => {
          logout();
          navigate("/login");
        }}
      >
        <LogOut className="h-4 w-4" />
        Sign out
      </Button>
    </header>
  );
}
