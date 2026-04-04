import type { Metadata } from "next";
import { SITE_NAME } from "@/lib/site";

export const metadata: Metadata = {
  title: "Create account",
  description: `Create your ${SITE_NAME} account. Start tracking personal spend and splitting bills with groups in minutes.`,
};

export default function RegisterLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
