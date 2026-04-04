import { createClient } from "@/lib/supabase/server";
import { AnalyticsDashboard } from "./analytics-dashboard";

export default async function AnalyticsPage() {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) return null;

  // Fetch all personal expenses for the last 12 months
  const twelveMonthsAgo = new Date();
  twelveMonthsAgo.setMonth(twelveMonthsAgo.getMonth() - 12);
  const startDate = twelveMonthsAgo.toISOString().split("T")[0];

  const [{ data: personalExpenses }, { data: groupExpenses }] =
    await Promise.all([
      supabase
        .from("expenses")
        .select("amount, date, category_id, categories(name, icon, color)")
        .eq("payer_id", user.id)
        .is("group_id", null)
        .gte("date", startDate)
        .order("date", { ascending: true }),
      supabase
        .from("expenses")
        .select("amount, date, category_id, categories(name, icon, color)")
        .eq("payer_id", user.id)
        .not("group_id", "is", null)
        .gte("date", startDate)
        .order("date", { ascending: true }),
    ]);

  return (
    <div className="space-y-8">
      <div>
        <h1 className="text-2xl font-headline font-extrabold tracking-tight">
          Analytics
        </h1>
        <p className="text-secondary text-sm mt-1">
          Insights into your spending patterns
        </p>
      </div>

      <AnalyticsDashboard
        personalExpenses={personalExpenses || []}
        groupExpenses={groupExpenses || []}
      />
    </div>
  );
}
