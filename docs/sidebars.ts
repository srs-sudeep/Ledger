import type { SidebarsConfig } from "@docusaurus/plugin-content-docs";

const sidebars: SidebarsConfig = {
  docsSidebar: [
    "intro",
    {
      type: "category",
      label: "Getting Started",
      items: [
        "getting-started/prerequisites",
        "getting-started/supabase-setup",
        "getting-started/web-setup",
        "getting-started/flutter-setup",
        "getting-started/vercel-deploy",
      ],
    },
    {
      type: "category",
      label: "Concepts",
      items: [
        "concepts/money-flow",
      ],
    },
    {
      type: "category",
      label: "Database",
      items: [
        "database/schema",
        "database/rls-policies",
        "database/edge-functions",
      ],
    },
    {
      type: "category",
      label: "Web App",
      items: [
        "web-app/landing-page",
        "web-app/overview",
        "web-app/authentication",
        "web-app/dashboard",
        "web-app/accounts",
        "web-app/personal",
        "web-app/groups",
        "web-app/analytics",
        "web-app/settings",
      ],
    },
    {
      type: "category",
      label: "Mobile App",
      items: [
        "mobile-app/overview",
        "mobile-app/screens",
        "mobile-app/state-management",
      ],
    },
    {
      type: "category",
      label: "Design System",
      items: [
        "design-system/overview",
        "design-system/components",
      ],
    },
    {
      type: "category",
      label: "API Reference",
      items: [
        "api-reference/supabase-tables",
        "api-reference/edge-functions",
      ],
    },
  ],
};

export default sidebars;
