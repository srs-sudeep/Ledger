import { useNavigate } from "react-router-dom";
import { LogOut } from "lucide-react";
import { BrandLogo } from "@/components/BrandLogo";
import { Button } from "@/components/ui/button";
import { useAuth } from "@/contexts/AuthContext";

export function Header() {
  const navigate = useNavigate();
  const { logout } = useAuth();

  return (
    <header className="sticky top-0 z-40 flex w-full items-center justify-between border-b border-outline/10 bg-surface/85 px-4 py-3 backdrop-blur-xl md:px-8">
      <BrandLogo
        size={32}
        showWordmark
        wordmarkClassName="text-xl font-black"
        className="md:hidden"
      />
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
