"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import { Plus } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";
import { createClient } from "@/lib/supabase/client";

interface CreateGroupButtonProps {
  userId: string;
}

export function CreateGroupButton({ userId }: CreateGroupButtonProps) {
  const [open, setOpen] = useState(false);
  const [name, setName] = useState("");
  const [type, setType] = useState("custom");
  const [loading, setLoading] = useState(false);
  const router = useRouter();
  const supabase = createClient();

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setLoading(true);

    const { data: group, error } = await supabase
      .from("groups")
      .insert({ name, type, created_by: userId })
      .select()
      .single();

    if (!error && group) {
      await supabase.from("group_members").insert({
        group_id: group.id,
        user_id: userId,
        role: "admin",
      });

      setOpen(false);
      setName("");
      setType("custom");
      router.refresh();
      router.push(`/groups/${group.id}`);
    }

    setLoading(false);
  };

  return (
    <>
      <Button onClick={() => setOpen(true)} className="gap-2">
        <Plus size={18} />
        Create Group
      </Button>

      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent onClose={() => setOpen(false)}>
          <DialogHeader>
            <DialogTitle>Create New Group</DialogTitle>
          </DialogHeader>

          <form onSubmit={handleSubmit} className="space-y-4">
            <Input
              id="name"
              label="Group Name"
              placeholder="e.g. Weekend Trip, Apartment Rent"
              value={name}
              onChange={(e) => setName(e.target.value)}
              required
            />

            <Select
              id="type"
              label="Group Type"
              value={type}
              onChange={(e) => setType(e.target.value)}
              options={[
                { value: "custom", label: "Custom" },
                { value: "trip", label: "Trip" },
                { value: "home", label: "Home / Apartment" },
              ]}
            />

            <div className="flex gap-3 pt-2">
              <Button
                type="button"
                variant="secondary"
                className="flex-1"
                onClick={() => setOpen(false)}
              >
                Cancel
              </Button>
              <Button type="submit" className="flex-1" disabled={loading}>
                {loading ? "Creating..." : "Create Group"}
              </Button>
            </div>
          </form>
        </DialogContent>
      </Dialog>
    </>
  );
}
