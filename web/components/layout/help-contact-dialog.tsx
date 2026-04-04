"use client";

import { Mail, Phone, Globe, User } from "lucide-react";
import {
  Dialog,
  DialogContent,
  DialogHeader,
  DialogTitle,
} from "@/components/ui/dialog";

const CONTACT = {
  name: "Sudeep Ranjan Sahoo",
  email: "sudeep160403@gmail.com",
  phones: [
    {
      label: "Japan",
      display: "+81 090-8836-2234",
      href: "tel:+819088362234",
    },
    {
      label: "India",
      display: "+91 6372432280",
      href: "tel:+916372432280",
    },
  ],
  website: {
    display: "iamsrs.com",
    href: "https://iamsrs.com",
  },
} as const;

export function HelpContactDialog({
  open,
  onOpenChange,
}: {
  open: boolean;
  onOpenChange: (open: boolean) => void;
}) {
  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent onClose={() => onOpenChange(false)} className="max-w-md">
        <DialogHeader>
          <DialogTitle>Help & contact</DialogTitle>
          <p className="text-sm text-secondary">
            Reach out if you need support or have feedback about The Ledger.
          </p>
        </DialogHeader>

        <ul className="space-y-4 text-sm">
          <li className="flex gap-3">
            <User
              className="h-5 w-5 shrink-0 text-surface-tint mt-0.5"
              aria-hidden
            />
            <div>
              <p className="text-[10px] font-semibold uppercase tracking-wider text-secondary">
                Name
              </p>
              <p className="font-medium text-on-surface">{CONTACT.name}</p>
            </div>
          </li>

          <li className="flex gap-3">
            <Mail
              className="h-5 w-5 shrink-0 text-surface-tint mt-0.5"
              aria-hidden
            />
            <div>
              <p className="text-[10px] font-semibold uppercase tracking-wider text-secondary">
                Email
              </p>
              <a
                href={`mailto:${CONTACT.email}`}
                className="font-medium text-surface-tint hover:underline break-all"
              >
                {CONTACT.email}
              </a>
            </div>
          </li>

          {CONTACT.phones.map((p) => (
            <li key={p.label} className="flex gap-3">
              <Phone
                className="h-5 w-5 shrink-0 text-surface-tint mt-0.5"
                aria-hidden
              />
              <div>
                <p className="text-[10px] font-semibold uppercase tracking-wider text-secondary">
                  Phone ({p.label})
                </p>
                <a
                  href={p.href}
                  className="font-medium text-surface-tint hover:underline"
                >
                  {p.display}
                </a>
              </div>
            </li>
          ))}

          <li className="flex gap-3">
            <Globe
              className="h-5 w-5 shrink-0 text-surface-tint mt-0.5"
              aria-hidden
            />
            <div>
              <p className="text-[10px] font-semibold uppercase tracking-wider text-secondary">
                Website
              </p>
              <a
                href={CONTACT.website.href}
                target="_blank"
                rel="noopener noreferrer"
                className="font-medium text-surface-tint hover:underline"
              >
                {CONTACT.website.display}
              </a>
            </div>
          </li>
        </ul>
      </DialogContent>
    </Dialog>
  );
}
