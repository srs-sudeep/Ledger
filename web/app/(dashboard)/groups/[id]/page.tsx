import { createClient } from "@/lib/supabase/server";
import { notFound } from "next/navigation";
import { GroupHeader } from "./group-header";
import { GroupExpenses } from "./group-expenses";
import { GroupMembers } from "./group-members";
import { SettleUpSection } from "./settle-up-section";
import { AddGroupExpenseButton } from "./add-group-expense";

export default async function GroupDetailPage({
  params,
}: {
  params: { id: string };
}) {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) return null;

  const [
    { data: group },
    { data: members },
    { data: expenses },
    { data: categories },
    { data: currentMembership },
  ] = await Promise.all([
    supabase.from("groups").select("*").eq("id", params.id).single(),
    supabase
      .from("group_members")
      .select("*, profiles(*)")
      .eq("group_id", params.id),
    supabase
      .from("expenses")
      .select("*, categories(*), profiles!expenses_payer_id_fkey(*), expense_splits(*)")
      .eq("group_id", params.id)
      .order("date", { ascending: false }),
    supabase.from("categories").select("*").order("name"),
    supabase
      .from("group_members")
      .select("role")
      .eq("group_id", params.id)
      .eq("user_id", user.id)
      .single(),
  ]);

  if (!group || !currentMembership) {
    notFound();
  }

  return (
    <div className="space-y-8">
      <GroupHeader
        group={group}
        memberCount={members?.length || 0}
        isAdmin={currentMembership.role === "admin"}
      />

      <div className="grid grid-cols-12 gap-8">
        <div className="col-span-12 lg:col-span-7 space-y-6">
          <div className="flex items-center justify-between">
            <h2 className="font-headline font-bold text-lg">Group Expenses</h2>
            <AddGroupExpenseButton
              groupId={params.id}
              groupCurrency={group.currency ?? "JPY"}
              members={members || []}
              categories={categories || []}
              userId={user.id}
            />
          </div>
          <GroupExpenses expenses={expenses || []} userId={user.id} />
        </div>

        <div className="col-span-12 lg:col-span-5 space-y-6">
          <GroupMembers
            members={members || []}
            groupId={params.id}
            isAdmin={currentMembership.role === "admin"}
          />
          <SettleUpSection
            groupId={params.id}
            groupCurrency={group.currency ?? "JPY"}
            members={members || []}
            userId={user.id}
          />
        </div>
      </div>
    </div>
  );
}
