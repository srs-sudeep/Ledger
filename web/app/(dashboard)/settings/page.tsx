import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import { CurrencySettingsForm } from "./currency-settings-form";

export default async function SettingsPage() {
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

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-2xl font-headline font-extrabold tracking-tight">
          Settings
        </h1>
        <p className="text-secondary text-sm mt-1">
          Preferences for your workspace
        </p>
      </div>

      <CurrencySettingsForm
        initialCurrency={profile?.default_currency ?? "USD"}
      />
    </div>
  );
}
