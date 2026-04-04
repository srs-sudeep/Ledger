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
  groupId: string;
  isAdmin: boolean;
}

export function GroupMembers({ members, groupId, isAdmin }: GroupMembersProps) {
  const [showInvite, setShowInvite] = useState(false);
  const [inviteEmail, setInviteEmail] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState("");
  const [success, setSuccess] = useState("");
  const router = useRouter();
  const supabase = createClient();

  const handleInvite = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);
    setError("");
    setSuccess("");

    const { data: profile, error: lookupError } = await supabase
      .from("profiles")
      .select("id, full_name, email")
      .eq("email", inviteEmail.trim().toLowerCase())
      .single();

    if (lookupError || !profile) {
      setError("No registered user found with that email. They must sign up first.");
      setLoading(false);
      return;
    }

    const alreadyMember = members.some((m) => m.user_id === profile.id);
    if (alreadyMember) {
      setError("This user is already a member of this group.");
      setLoading(false);
      return;
    }

    const { error: insertError } = await supabase.from("group_members").insert({
      group_id: groupId,
      user_id: profile.id,
      role: "member",
    });

    if (insertError) {
      setError("Failed to add member. You may not have permission.");
      setLoading(false);
      return;
    }

    setSuccess(`${profile.full_name || inviteEmail} has been added to the group!`);
    setInviteEmail("");
    setLoading(false);
    router.refresh();
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

      <Dialog open={showInvite} onOpenChange={(open) => {
        setShowInvite(open);
        if (!open) { setError(""); setSuccess(""); }
      }}>
        <DialogContent onClose={() => { setShowInvite(false); setError(""); setSuccess(""); }}>
          <DialogHeader>
            <DialogTitle>Invite Member</DialogTitle>
          </DialogHeader>
          <form onSubmit={handleInvite} className="space-y-4">
            <p className="text-xs text-secondary">
              Enter the email of a registered user to add them to this group.
            </p>
            <Input
              id="inviteEmail"
              label="Email Address"
              type="email"
              placeholder="friend@example.com"
              value={inviteEmail}
              onChange={(e) => setInviteEmail(e.target.value)}
              required
            />
            {error && (
              <p className="text-xs text-error bg-error-container/20 rounded-lg px-3 py-2">
                {error}
              </p>
            )}
            {success && (
              <p className="text-xs text-green-700 bg-green-50 rounded-lg px-3 py-2">
                {success}
              </p>
            )}
            <div className="flex gap-3">
              <Button
                type="button"
                variant="secondary"
                className="flex-1"
                onClick={() => { setShowInvite(false); setError(""); setSuccess(""); }}
              >
                Cancel
              </Button>
              <Button type="submit" className="flex-1" disabled={loading}>
                {loading ? "Adding..." : "Add Member"}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>
    </>
  );
}
