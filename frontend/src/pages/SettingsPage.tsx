import { useRef, useState } from "react";
import { useAuth } from "@/contexts/AuthContext";
import { authApi, downloadWithAuth } from "@/api/client";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { CURRENCY_OPTIONS } from "@/lib/currencies";
import { Select } from "@/components/ui/select";
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card";
import { BrandLogo } from "@/components/BrandLogo";
import { SITE_NAME, SITE_UI_TAGLINE } from "@/lib/site";
import { SectionHeader } from "@/components/finance/SectionHeader";
import { Download, FileUp, Mail, Phone, Save } from "lucide-react";

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
    <div className="space-y-8">
      <SectionHeader
        eyebrow="Workspace"
        title="Settings"
        description="Manage your profile, default currency, and ledger data exports from one place."
      />

      <Card className="settings-hero-card overflow-hidden p-0">
        <div className="grid gap-0 lg:grid-cols-[1.1fr_0.9fr]">
          <div className="p-8 md:p-10">
            <div className="inline-flex items-center rounded-full bg-white/70 px-3 py-1 text-[11px] font-semibold uppercase tracking-[0.2em] text-secondary">
              Personal workspace
            </div>
            <div className="mt-5 flex items-start gap-4">
              <BrandLogo size={54} />
              <div className="min-w-0">
                <h2 className="text-3xl font-headline font-bold text-on-surface">{fullName || user?.full_name || SITE_NAME}</h2>
                <p className="mt-1 text-sm text-secondary">
                  Keep your identity, currency, and export tools in sync across web and mobile.
                </p>
              </div>
            </div>
            <div className="mt-6 grid gap-3 sm:grid-cols-2 xl:grid-cols-3">
              <div className="rounded-2xl bg-white/75 px-4 py-3 shadow-sm">
                <div className="mb-2 flex items-center gap-2 text-secondary">
                  <Mail className="h-4 w-4" />
                  <span className="text-[11px] font-semibold uppercase tracking-[0.18em]">Email</span>
                </div>
                <p className="truncate text-sm font-semibold text-on-surface">{user?.email}</p>
              </div>
              <div className="rounded-2xl bg-white/75 px-4 py-3 shadow-sm">
                <div className="mb-2 flex items-center gap-2 text-secondary">
                  <Phone className="h-4 w-4" />
                  <span className="text-[11px] font-semibold uppercase tracking-[0.18em]">Primary</span>
                </div>
                <p className="truncate text-sm font-semibold text-on-surface">{phonePrimary || "Not set"}</p>
              </div>
              <div className="rounded-2xl bg-white/75 px-4 py-3 shadow-sm sm:col-span-2 xl:col-span-1">
                <div className="mb-2 flex items-center gap-2 text-secondary">
                  <Phone className="h-4 w-4" />
                  <span className="text-[11px] font-semibold uppercase tracking-[0.18em]">Currency</span>
                </div>
                <p className="truncate text-sm font-semibold text-on-surface">
                  {CURRENCY_OPTIONS.find((option) => option.code === currency)?.label ?? currency}
                </p>
              </div>
            </div>
          </div>

          <div className="border-t border-outline/10 bg-white/70 p-8 lg:border-l lg:border-t-0">
            <p className="text-[11px] font-semibold uppercase tracking-[0.18em] text-secondary">Workspace identity</p>
            <p className="mt-2 text-lg font-headline font-bold text-on-surface">{SITE_NAME}</p>
            <p className="text-sm text-secondary">{SITE_UI_TAGLINE}</p>
            <p className="mt-4 text-sm leading-6 text-secondary">
              Exports keep account names, categories, and translated ledger metadata so your records stay readable outside the app.
            </p>
            <div className="mt-6 flex flex-wrap gap-2">
              <Button variant="outline" className="gap-2 rounded-2xl bg-white/80" onClick={() => downloadWithAuth("/api/export/transactions?format=csv", "transactions.csv")}>
                <Download className="h-4 w-4" />
                Ledger CSV
              </Button>
              <Button variant="outline" className="gap-2 rounded-2xl bg-white/80" onClick={() => downloadWithAuth("/api/export/transactions?format=pdf", "transactions.pdf")}>
                <Download className="h-4 w-4" />
                Ledger PDF
              </Button>
            </div>
          </div>
        </div>
      </Card>

      <div className="grid gap-6 xl:grid-cols-[minmax(0,1.1fr)_minmax(320px,0.9fr)]">
        <Card className="p-0">
          <CardHeader className="border-b border-outline/10 px-8 py-6">
            <CardTitle>Profile</CardTitle>
            <CardDescription>Update the default information used across the ledger.</CardDescription>
          </CardHeader>
          <CardContent className="space-y-5 px-8 py-6">
            <Input id="fn" label="Full name" value={fullName} onChange={(e) => setFullName(e.target.value)} />
            <div className="grid gap-5 md:grid-cols-2">
              <Input id="phone1" label="Primary phone" value={phonePrimary} onChange={(e) => setPhonePrimary(e.target.value)} />
              <Input id="phone2" label="Secondary phone" value={phoneSecondary} onChange={(e) => setPhoneSecondary(e.target.value)} />
            </div>
            <Select
              id="cur"
              label="Default currency"
              value={currency}
              onChange={(e) => setCurrency(e.target.value)}
              options={CURRENCY_OPTIONS.map((c) => ({ value: c.code, label: c.label }))}
            />
            <div className="flex flex-wrap items-center gap-3 pt-2">
              <Button onClick={save} className="gap-2 rounded-2xl">
                <Save className="h-4 w-4" />
                Save changes
              </Button>
              {saved && <p className="text-sm font-medium text-green-700">Saved</p>}
            </div>
          </CardContent>
        </Card>

        <Card className="p-0">
          <CardHeader className="border-b border-outline/10 px-8 py-6">
            <CardTitle>Export / import</CardTitle>
            <CardDescription>
              Download readable ledger exports with account/category names and transaction metadata, or import expenses.
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4 px-8 py-6">
            <div className="grid gap-3 sm:grid-cols-2">
              <Button variant="outline" className="justify-start rounded-2xl bg-white/80" onClick={() => downloadWithAuth("/api/export/transactions?format=csv", "transactions.csv")}>
                Export ledger CSV
              </Button>
              <Button variant="outline" className="justify-start rounded-2xl bg-white/80" onClick={() => downloadWithAuth("/api/export/transactions?format=excel", "transactions.xls")}>
                Export ledger Excel
              </Button>
              <Button variant="outline" className="justify-start rounded-2xl bg-white/80" onClick={() => downloadWithAuth("/api/export/transactions?format=pdf", "transactions.pdf")}>
                Export ledger PDF
              </Button>
              <Button variant="outline" className="justify-start rounded-2xl bg-white/80" onClick={() => downloadWithAuth("/api/export/accounts.csv", "accounts.csv")}>
                Export accounts
              </Button>
            </div>
            <div className="rounded-2xl border border-dashed border-outline/20 bg-surface-container-low p-4">
              <div className="flex flex-wrap items-center justify-between gap-3">
                <div>
                  <p className="font-semibold text-on-surface">Import expenses CSV</p>
                  <p className="text-sm text-secondary">Use the same import endpoint if you need to backfill rows.</p>
                </div>
                <Button variant="secondary" className="gap-2 rounded-2xl" onClick={() => fileRef.current?.click()}>
                  <FileUp className="h-4 w-4" />
                  Choose file
                </Button>
              </div>
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
              {importMsg && <p className="mt-3 text-sm text-secondary">{importMsg}</p>}
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
