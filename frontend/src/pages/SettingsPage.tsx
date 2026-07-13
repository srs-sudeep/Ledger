import { useState } from "react";
import { useAuth } from "@/contexts/AuthContext";
import { authApi } from "@/api/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { CURRENCY_OPTIONS } from "@/lib/currencies";
import { Select } from "@/components/ui/select";

export function SettingsPage() {
  const { user, refreshUser } = useAuth();
  const [fullName, setFullName] = useState(user?.full_name ?? "");
  const [currency, setCurrency] = useState(user?.default_currency ?? "JPY");
  const [saved, setSaved] = useState(false);

  const save = async () => {
    await authApi.updateMe({ full_name: fullName, default_currency: currency });
    await refreshUser();
    setSaved(true);
    setTimeout(() => setSaved(false), 2000);
  };

  return (
    <div className="space-y-6 max-w-lg">
      <h1 className="text-2xl font-headline font-bold">Settings</h1>
      <Input id="fn" label="Full name" value={fullName} onChange={(e) => setFullName(e.target.value)} />
      <Select
        id="cur"
        label="Default currency"
        value={currency}
        onChange={(e) => setCurrency(e.target.value)}
        options={CURRENCY_OPTIONS.map((c) => ({ value: c.code, label: c.label }))}
      />
      <Button onClick={save}>Save</Button>
      {saved && <p className="text-sm text-green-700">Saved</p>}
      <p className="text-sm text-secondary">{user?.email}</p>
    </div>
  );
}
