import Link from "next/link";
import { Card, CardTitle } from "@/components/ui/card";
import { getInitials } from "@/lib/utils";
import type { Group } from "@/lib/types";

interface ActiveGroupsProps {
  groups: (Group | null)[];
}

const groupColors = [
  "bg-primary-container text-white",
  "bg-on-surface text-white",
  "bg-surface-container-high text-on-surface-variant",
  "bg-surface-tint text-white",
  "bg-tertiary-container text-white",
];

export function ActiveGroups({ groups }: ActiveGroupsProps) {
  const validGroups = groups.filter(Boolean) as Group[];

  return (
    <Card className="p-8">
      <CardTitle className="mb-6">Active Groups</CardTitle>
      <div className="space-y-4">
        {validGroups.length === 0 ? (
          <p className="text-secondary text-sm py-4 text-center">
            No groups yet.{" "}
            <Link
              href="/groups"
              className="text-surface-tint font-semibold hover:underline"
            >
              Create one
            </Link>
          </p>
        ) : (
          validGroups.map((group, i) => (
            <Link
              key={group.id}
              href={`/groups/${group.id}`}
              className="flex items-center justify-between p-4 rounded-xl bg-surface-container-low ghost-border hover:bg-surface-container transition-all"
            >
              <div className="flex items-center gap-4">
                <div
                  className={`w-10 h-10 rounded-full flex items-center justify-center font-bold text-sm ${
                    groupColors[i % groupColors.length]
                  }`}
                >
                  {getInitials(group.name)}
                </div>
                <div>
                  <p className="font-semibold text-sm">{group.name}</p>
                  <p className="text-xs text-secondary capitalize">
                    {group.type}
                  </p>
                </div>
              </div>
            </Link>
          ))
        )}
      </div>
    </Card>
  );
}
