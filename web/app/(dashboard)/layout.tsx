import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import { Sidebar } from "@/components/layout/sidebar";
import { Header } from "@/components/layout/header";
import { CurrencyProvider } from "@/components/currency/currency-provider";

export default async function DashboardLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) {
    redirect("/login");
  }

  const { data: profile } = await supabase
    .from("profiles")
    .select("default_currency")
    .eq("id", user.id)
    .single();

  const defaultCurrency = profile?.default_currency ?? "USD";

  return (
    <CurrencyProvider currency={defaultCurrency}>
      <div className="min-h-screen bg-surface">
        <Sidebar />
        <main className="ml-64 min-h-screen">
          <Header />
          <div className="p-8 max-w-[1400px] mx-auto">{children}</div>
        </main>
      </div>
    </CurrencyProvider>
  );
}
