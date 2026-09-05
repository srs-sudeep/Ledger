import { useRef, useState } from "react";
import { useAuth } from "@/contexts/AuthContext";
import { authApi, downloadWithAuth } from "@/api/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { CURRENCY_OPTIONS } from "@/lib/currencies";
import { Select } from "@/components/ui/select";
import { Card, CardTitle } from "@/components/ui/card";
import { BrandLogo } from "@/components/BrandLogo";
import { SITE_NAME, SITE_UI_TAGLINE } from "@/lib/site";

export function SettingsPage() {
  const { user, refreshUser } = useAuth();
  const [fullName, setFullName] = useState(user?.full_name ?? "");
  const [phonePrimary, setPhonePrimary] = useState(user?.phone_primary ?? "");
  const [phoneSecondary, setPhoneSecondary] = useState(user?.phone_secondary ?? "");
  const [currency, setCurrency] = useState(user?.default_currency ?? "JPY");
  const [saved, setSaved] = useState(false);
  const [importMsg, setImportMsg] = useState("");
  const fileRef = useRef<HTMLInputElement>(null);

  const save = async () => {
    await authApi.updateMe({
      full_name: fullName,
      phone_primary: phonePrimary,
      phone_secondary: phoneSecondary,
      default_currency: currency,
    });
    await refreshUser();
    setSaved(true);
    setTimeout(() => setSaved(false), 2000);
  };

  const importCsv = async (file: File) => {
    const token = localStorage.getItem("ledger_token");
    const form = new FormData();
    form.append("file", file);
    const res = await fetch("/api/export/expenses/import", {
      method: "POST",
      headers: token ? { Authorization: `Bearer ${token}` } : {},
      body: form,
    });
    const data = await res.json();
    if (!res.ok) {
      setImportMsg(data.detail || "Import failed");
      return;
    }
    setImportMsg(`Imported ${data.created} expenses` + (data.errors?.length ? ` (${data.errors.length} row errors)` : ""));
  };

  return (
    <div className="space-y-8 max-w-lg">
      <div className="space-y-6">
        <h1 className="text-2xl font-headline font-bold">Settings</h1>
        <Input id="fn" label="Full name" value={fullName} onChange={(e) => setFullName(e.target.value)} />
        <Input id="phone1" label="Primary phone" value={phonePrimary} onChange={(e) => setPhonePrimary(e.target.value)} />
        <Input id="phone2" label="Secondary phone" value={phoneSecondary} onChange={(e) => setPhoneSecondary(e.target.value)} />
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

      <Card className="p-6 space-y-3">
        <CardTitle>Export / import</CardTitle>
        <p className="text-sm text-secondary">
          Download readable ledger exports with account/category names and transaction metadata, or import expenses.
        </p>
        <div className="flex flex-wrap gap-2">
          <Button variant="outline" onClick={() => downloadWithAuth("/api/export/transactions?format=csv", "transactions.csv")}>
            Export ledger CSV
          </Button>
          <Button variant="outline" onClick={() => downloadWithAuth("/api/export/transactions?format=excel", "transactions.xls")}>
            Export ledger Excel
          </Button>
          <Button variant="outline" onClick={() => downloadWithAuth("/api/export/transactions?format=pdf", "transactions.pdf")}>
            Export ledger PDF
          </Button>
          <Button variant="outline" onClick={() => downloadWithAuth("/api/export/accounts.csv", "accounts.csv")}>
            Export accounts
          </Button>
          <Button variant="secondary" onClick={() => fileRef.current?.click()}>
            Import expenses CSV
          </Button>
          <input
            ref={fileRef}
            type="file"
            accept=".csv,text/csv"
            className="hidden"
            onChange={(e) => {
              const f = e.target.files?.[0];
              if (f) importCsv(f);
              e.target.value = "";
            }}
          />
        </div>
        {importMsg && <p className="text-sm text-secondary">{importMsg}</p>}
      </Card>

      <div className="flex items-center gap-3 pt-2">
        <BrandLogo size={40} />
        <div>
          <p className="font-headline font-bold text-on-surface">{SITE_NAME}</p>
          <p className="text-xs text-secondary uppercase tracking-wide">{SITE_UI_TAGLINE}</p>
        </div>
      </div>
    </div>
  );
}
