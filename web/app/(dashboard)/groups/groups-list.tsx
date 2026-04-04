import Link from "next/link";
import { Card } from "@/components/ui/card";
import { Badge } from "@/components/ui/badge";
import { getInitials } from "@/lib/utils";
import { Users, MapPin, Home, Layers } from "lucide-react";
import type { Group, GroupRole } from "@/lib/types";

interface GroupWithRole extends Group {
  role: GroupRole;
  memberCount: number;
}

interface GroupsListProps {
  groups: GroupWithRole[];
}

const typeIcons = {
  trip: MapPin,
  home: Home,
  custom: Layers,
};

const groupColors = [
  "bg-primary-container text-white",
  "bg-on-surface text-white",
  "bg-surface-tint text-white",
  "bg-surface-container-high text-on-surface-variant",
  "bg-tertiary-container text-on-tertiary",
];

export function GroupsList({ groups }: GroupsListProps) {
  if (groups.length === 0) {
    return (
      <Card className="p-12 text-center">
        <Users className="mx-auto mb-4 text-secondary" size={48} />
        <h3 className="font-headline font-bold text-lg mb-2">
          No groups yet
        </h3>
        <p className="text-secondary text-sm">
          Create a group to start splitting expenses. You can join many groups.
        </p>
      </Card>
    );
  }

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      {groups.map((group, i) => {
        const TypeIcon = typeIcons[group.type] || Layers;

        return (
          <Link key={group.id} href={`/groups/${group.id}`}>
            <Card className="p-6 cursor-pointer hover:shadow-ambient-lg transition-all group">
              <div className="flex items-start justify-between mb-4">
                <div
                  className={`w-12 h-12 rounded-2xl flex items-center justify-center font-bold ${
                    groupColors[i % groupColors.length]
                  }`}
                >
                  {getInitials(group.name)}
                </div>
                <Badge variant="muted" className="capitalize">
                  {group.role}
                </Badge>
              </div>

              <h3 className="font-headline font-bold text-lg mb-1 group-hover:text-surface-tint transition-colors">
                {group.name}
              </h3>

              <div className="flex flex-wrap items-center gap-x-3 gap-y-1 text-xs text-secondary">
                <span className="inline-flex items-center gap-1">
                  <TypeIcon size={14} />
                  <span className="capitalize">{group.type}</span>
                </span>
                <span>
                  {group.memberCount}{" "}
                  {group.memberCount === 1 ? "member" : "members"}
                </span>
                <span className="font-mono">{group.currency}</span>
              </div>
            </Card>
          </Link>
        );
      })}
    </div>
  );
}
