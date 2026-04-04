"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Card, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Avatar } from "@/components/ui/avatar";
import { Dialog, DialogContent, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { UserPlus, Shield, User, Trash2 } from "lucide-react";
import { createClient } from "@/lib/supabase/client";
import type { GroupMember } from "@/lib/types";

interface GroupMembersProps {
  members: GroupMember[];
  isAdmin: boolean;
}

export function GroupMembers({ members, isAdmin }: GroupMembersProps) {
  const [showInvite, setShowInvite] = useState(false);
  const [inviteEmail, setInviteEmail] = useState("");
  const [loading, setLoading] = useState(false);
  const router = useRouter();
  const supabase = createClient();

  const handleInvite = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    // Look up user by email (requires profiles to have email or using auth admin)
    // For now we'd use a simulated flow - in production, use Supabase Edge Function for invites
    setLoading(false);
    setShowInvite(false);
    setInviteEmail("");
  };

  const handleRemoveMember = async (memberId: string) => {
    await supabase.from("group_members").delete().eq("id", memberId);
    router.refresh();
  };

  return (
    <>
      <Card className="p-6">
        <div className="flex items-center justify-between mb-4">
          <CardTitle>Members</CardTitle>
          {isAdmin && (
            <Button
              variant="ghost"
              size="sm"
              className="gap-1"
              onClick={() => setShowInvite(true)}
            >
              <UserPlus size={14} />
              Invite
            </Button>
          )}
        </div>

        <div className="space-y-3">
          {members.map((member) => (
            <div
              key={member.id}
              className="flex items-center justify-between py-2"
            >
              <div className="flex items-center gap-3">
                <Avatar
                  src={member.profiles?.avatar_url}
                  fallback={member.profiles?.full_name || "User"}
                />
                <div>
                  <p className="text-sm font-semibold">
                    {member.profiles?.full_name || "Unknown"}
                  </p>
                  <div className="flex items-center gap-1 text-xs text-secondary">
                    {member.role === "admin" ? (
                      <Shield size={10} />
                    ) : (
                      <User size={10} />
                    )}
                    <span className="capitalize">{member.role}</span>
                  </div>
                </div>
              </div>
              {isAdmin && member.role !== "admin" && (
                <button
                  onClick={() => handleRemoveMember(member.id)}
                  className="p-1.5 text-secondary hover:text-error rounded-full hover:bg-error-container/30 transition-colors"
                >
                  <Trash2 size={14} />
                </button>
              )}
            </div>
          ))}
        </div>
      </Card>

      <Dialog open={showInvite} onOpenChange={setShowInvite}>
        <DialogContent onClose={() => setShowInvite(false)}>
          <DialogHeader>
            <DialogTitle>Invite Member</DialogTitle>
          </DialogHeader>
          <form onSubmit={handleInvite} className="space-y-4">
            <Input
              id="inviteEmail"
              label="Email Address"
              type="email"
              placeholder="friend@example.com"
              value={inviteEmail}
              onChange={(e) => setInviteEmail(e.target.value)}
              required
            />
            <div className="flex gap-3">
              <Button
                type="button"
                variant="secondary"
                className="flex-1"
                onClick={() => setShowInvite(false)}
              >
                Cancel
              </Button>
              <Button type="submit" className="flex-1" disabled={loading}>
                {loading ? "Inviting..." : "Send Invite"}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>
    </>
  );
}
