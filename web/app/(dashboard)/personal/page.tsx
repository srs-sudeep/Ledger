import { createClient } from "@/lib/supabase/server";
import { PersonalExpenseTable } from "./expense-table";
import { BudgetProgress } from "./budget-progress";
import { AddExpenseButton } from "./add-expense-button";

export default async function PersonalPage() {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) return null;

  const now = new Date();
  const startOfMonth = new Date(now.getFullYear(), now.getMonth(), 1)
    .toISOString()
    .split("T")[0];

  const [{ data: expenses }, { data: categories }, { data: monthlyByCategory }] =
    await Promise.all([
      supabase
        .from("expenses")
        .select("*, categories(*)")
        .eq("payer_id", user.id)
        .is("group_id", null)
        .order("date", { ascending: false })
        .limit(50),
      supabase.from("categories").select("*").order("name"),
      supabase
        .from("expenses")
        .select("amount, category_id, categories(name, icon, color)")
        .eq("payer_id", user.id)
        .is("group_id", null)
        .gte("date", startOfMonth),
    ]);

  const categoryTotals = (monthlyByCategory || []).reduce(
    (acc, e) => {
      const cat = Array.isArray(e.categories) ? e.categories[0] : e.categories;
      const catName = cat?.name || "Other";
      const catColor = cat?.color || "#9E9E9E";
      const catIcon = cat?.icon || "category";
      if (!acc[catName]) {
        acc[catName] = { total: 0, color: catColor, icon: catIcon };
      }
      acc[catName].total += e.amount;
      return acc;
    },
    {} as Record<string, { total: number; color: string; icon: string }>
  );

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-headline font-extrabold tracking-tight">
            Personal Expenses
          </h1>
          <p className="text-secondary text-sm mt-1">
            Track and manage your individual spending
          </p>
        </div>
        <AddExpenseButton categories={categories || []} userId={user.id} />
      </div>

      <BudgetProgress categoryTotals={categoryTotals} />

      <PersonalExpenseTable expenses={expenses || []} />
    </div>
  );
}
