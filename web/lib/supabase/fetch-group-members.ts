import type { SupabaseClient } from "@supabase/supabase-js";
import type { GroupMember, Profile } from "@/lib/types";

/**
 * Load group members and their profiles.
 *
 * We cannot rely on `.select("*, profiles(*)")` on `group_members`: the FK is
 * `user_id -> auth.users`, not `profiles`, so PostgREST does not expose a
 * relationship to `public.profiles` and the embed returns no usable rows.
 */
export async function fetchGroupMembersWithProfiles(
  supabase: SupabaseClient,
  groupId: string
): Promise<GroupMember[]> {
  const { data: rows, error } = await supabase
    .from("group_members")
    .select("id, group_id, user_id, role, joined_at")
    .eq("group_id", groupId)
    .order("joined_at", { ascending: true });

  if (error) {
    console.error("[group_members]", error.message);
    return [];
  }
  if (!rows?.length) return [];

  const { data: profiles, error: profileError } = await supabase
    .from("profiles")
    .select("*")
    .in(
      "id",
      rows.map((r) => r.user_id)
    );

  if (profileError) {
    console.error("[profiles for group members]", profileError.message);
  }

  const byId = new Map<string, Profile>(
    (profiles ?? []).map((p) => [p.id, p as Profile])
  );

  return rows.map((row) => ({
    ...row,
    role: row.role as GroupMember["role"],
    profiles: byId.get(row.user_id),
  }));
}
