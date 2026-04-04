"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Card } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Select } from "@/components/ui/select";
import { createClient } from "@/lib/supabase/client";
import { CURRENCY_OPTIONS } from "@/lib/currencies";

export function CurrencySettingsForm({
  initialCurrency,
}: {
  initialCurrency: string;
}) {
  const [currency, setCurrency] = useState(initialCurrency);
  const [loading, setLoading] = useState(false);
  const [saved, setSaved] = useState(false);
  const router = useRouter();
  const supabase = createClient();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setSaved(false);

    const {
      data: { user },
    } = await supabase.auth.getUser();
    if (!user) {
      setLoading(false);
      return;
    }

    const { error } = await supabase
      .from("profiles")
      .update({ default_currency: currency, updated_at: new Date().toISOString() })
      .eq("id", user.id);

    if (!error) {
      setSaved(true);
      router.refresh();
    }
    setLoading(false);
  };

  const options = CURRENCY_OPTIONS.map((c) => ({
    value: c.code,
    label: c.label,
  }));

  return (
    <Card className="max-w-lg p-8">
      <h2 className="font-headline text-lg font-bold text-on-surface mb-1">
        Default currency
      </h2>
      <p className="text-sm text-secondary mb-6">
        Used for new expenses, accounts, and group ledgers unless you pick another
        code on a specific account or group.
      </p>

      <form onSubmit={handleSubmit} className="space-y-6">
        <Select
          id="default_currency"
          label="Currency"
          options={options}
          value={currency}
          onChange={(e) => setCurrency(e.target.value)}
        />

        <div className="flex items-center gap-4">
          <Button type="submit" disabled={loading}>
            {loading ? "Saving…" : "Save"}
          </Button>
          {saved && (
            <span className="text-sm text-secondary">Saved.</span>
          )}
        </div>
      </form>
    </Card>
  );
}
