import { createClient } from "@/lib/supabase/server";
import { GroupsList } from "./groups-list";
import { CreateGroupButton } from "./create-group-button";
import type { Group, GroupRole } from "@/lib/types";

type GroupWithEmbed = Group & {
  group_members?: { count: number }[];
};

export default async function GroupsPage() {
  const supabase = createClient();
  const {
    data: { user },
  } = await supabase.auth.getUser();

  if (!user) return null;

  const { data: memberships } = await supabase
    .from("group_members")
    .select(
      "group_id, role, groups(id, name, type, currency, created_at, created_by, group_members(count))"
    )
    .eq("user_id", user.id);

  const groups = (memberships || [])
    .map((m) => {
      const raw = m.groups as unknown as GroupWithEmbed | null;
      if (!raw) return null;
      const memberCount = raw.group_members?.[0]?.count ?? 0;
      const { group_members: _, ...g } = raw;
      return {
        ...g,
        role: m.role as GroupRole,
        memberCount,
      };
    })
    .filter(Boolean) as (Group & { role: GroupRole; memberCount: number })[];

  return (
    <div className="space-y-8">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-headline font-extrabold tracking-tight">
            Groups
          </h1>
          <p className="text-secondary text-sm mt-1">
            Your groups are listed here—open one for members, invites, and expenses.
            The same account can belong to many groups.
          </p>
        </div>
        <CreateGroupButton userId={user.id} />
      </div>

      <GroupsList groups={groups} />
    </div>
  );
}
