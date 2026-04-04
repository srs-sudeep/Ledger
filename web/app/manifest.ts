import type { MetadataRoute } from "next";
import { getSiteUrl, SITE_DESCRIPTION, SITE_NAME } from "@/lib/site";

export default function manifest(): MetadataRoute.Manifest {
  const base = getSiteUrl();
  return {
    name: SITE_NAME,
    short_name: "Ledger",
    description: SITE_DESCRIPTION,
    start_url: "/",
    display: "standalone",
    orientation: "portrait-primary",
    background_color: "#faf8ff",
    theme_color: "#0053db",
    categories: ["finance", "productivity"],
    icons: [
      {
        src: `${base}/icon`,
        sizes: "32x32",
        type: "image/png",
        purpose: "any",
      },
      {
        src: `${base}/apple-icon`,
        sizes: "180x180",
        type: "image/png",
        purpose: "maskable",
      },
    ],
  };
}
