import { Badge } from "@/components/ui/badge";
import { MapPin, Home, Layers, Users } from "lucide-react";
import type { Group } from "@/lib/types";

interface GroupHeaderProps {
  group: Group;
  memberCount: number;
  isAdmin: boolean;
}

const typeIcons = {
  trip: MapPin,
  home: Home,
  custom: Layers,
};

export function GroupHeader({ group, memberCount, isAdmin }: GroupHeaderProps) {
  const TypeIcon = typeIcons[group.type] || Layers;

  return (
    <div className="flex items-center justify-between">
      <div className="flex items-center gap-4">
        <div className="w-14 h-14 rounded-2xl cta-gradient text-white flex items-center justify-center">
          <TypeIcon size={24} />
        </div>
        <div>
          <h1 className="text-2xl font-headline font-extrabold tracking-tight">
            {group.name}
          </h1>
          <div className="flex items-center gap-3 mt-1">
            <Badge variant="muted" className="capitalize gap-1">
              <TypeIcon size={12} />
              {group.type}
            </Badge>
            <span className="text-xs text-secondary flex items-center gap-1">
              <Users size={12} />
              {memberCount} members
            </span>
            {isAdmin && <Badge variant="info">Admin</Badge>}
          </div>
        </div>
      </div>
    </div>
  );
}
