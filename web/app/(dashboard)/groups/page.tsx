import { createClient } from "@/lib/supabase/server";
import { GroupsList } from "./groups-list";
import { CreateGroupButton } from "./create-group-button";
import type { Group, GroupRole } from "@/lib/types";

export default async function GroupsPage() {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) return null;

  const { data: memberships } = await supabase
    .from("group_members")
    .select("group_id, role, groups(*)")
    .eq("user_id", user.id);

  const groups = (memberships || [])
    .map((m) => {
      const g = m.groups as unknown as Group | null;
      if (!g) return null;
      return { ...g, role: m.role as GroupRole };
    })
    .filter(Boolean) as (Group & { role: GroupRole })[];

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-headline font-extrabold tracking-tight">
            Groups
          </h1>
          <p className="text-secondary text-sm mt-1">
            Manage shared expenses with friends and family
          </p>
        </div>
        <CreateGroupButton userId={user.id} />
      </div>

      <GroupsList groups={groups} />
    </div>
  );
}
