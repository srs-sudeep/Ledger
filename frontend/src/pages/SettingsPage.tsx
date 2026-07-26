import { useRef, useState } from "react";
import { useAuth } from "@/contexts/AuthContext";
import { authApi } from "@/api/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { CURRENCY_OPTIONS } from "@/lib/currencies";
import { Select } from "@/components/ui/select";
import { Card, CardTitle } from "@/components/ui/card";

function downloadWithAuth(path: string, filename: string) {
  const token = localStorage.getItem("ledger_token");
  return fetch(path, {
    headers: token ? { Authorization: `Bearer ${token}` } : {},
  })
    .then(async (res) => {
      if (!res.ok) throw new Error("Download failed");
      const blob = await res.blob();
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = filename;
      a.click();
      URL.revokeObjectURL(url);
    });
}

export function SettingsPage() {
  const { user, refreshUser } = useAuth();
  const [fullName, setFullName] = useState(user?.full_name ?? "");
  const [currency, setCurrency] = useState(user?.default_currency ?? "JPY");
  const [saved, setSaved] = useState(false);
  const [importMsg, setImportMsg] = useState("");
  const fileRef = useRef<HTMLInputElement>(null);

  const save = async () => {
    await authApi.updateMe({ full_name: fullName, default_currency: currency });
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
          Download CSV backups or import expenses (columns: title, amount in minor units, date, currency, notes).
        </p>
        <div className="flex flex-wrap gap-2">
          <Button variant="outline" onClick={() => downloadWithAuth("/api/export/expenses.csv", "expenses.csv")}>
            Export expenses
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
    </div>
  );
}
