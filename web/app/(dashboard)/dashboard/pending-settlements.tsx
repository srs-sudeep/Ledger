"use client";

import { Card, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Avatar } from "@/components/ui/avatar";
import { formatCents } from "@/lib/utils";
import type { Settlement } from "@/lib/types";

interface PendingSettlementsProps {
  settlements: Settlement[];
  userId: string;
}

export function PendingSettlements({
  settlements,
  userId,
}: PendingSettlementsProps) {
  return (
    <Card className="p-8">
      <CardTitle className="mb-6">Pending Settlements</CardTitle>
      <div className="space-y-5">
        {settlements.length === 0 ? (
          <p className="text-secondary text-sm py-4 text-center">
            All settled up!
          </p>
        ) : (
          settlements.map((s) => {
            const isOwed = s.to_user_id === userId;
            const otherProfile = isOwed
              ? s.from_profile
              : s.to_profile;

            return (
              <div
                key={s.id}
                className="flex items-center justify-between"
              >
                <div className="flex items-center gap-3">
                  <Avatar
                    src={otherProfile?.avatar_url}
                    fallback={otherProfile?.full_name || "User"}
                    size="md"
                  />
                  <div>
                    <p className="text-sm font-semibold">
                      {otherProfile?.full_name || "Unknown"}
                    </p>
                    <p className="text-xs text-secondary">
                      {isOwed ? "owes you " : "you owe "}
                      <span
                        className={`font-bold ${
                          isOwed
                            ? "text-on-tertiary-fixed-variant"
                            : "text-error"
                        }`}
                      >
                        {formatCents(s.amount, s.currency ?? "JPY")}
                      </span>
                    </p>
                  </div>
                </div>
                <Button
                  variant={isOwed ? "outline" : "default"}
                  size="sm"
                >
                  {isOwed ? "Remind" : "Settle Up"}
                </Button>
              </div>
            );
          })
        )}
      </div>
    </Card>
  );
}
