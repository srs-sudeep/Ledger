import { themes as prismThemes } from "prism-react-renderer";
import type { Config } from "@docusaurus/types";
import type * as Preset from "@docusaurus/preset-classic";

const config: Config = {
  title: "Lyari",
  tagline: "All-in-one ledger — documentation",
  favicon: "img/favicon.ico",
  url: "https://lyari-docs.vercel.app",
  baseUrl: "/",
  organizationName: "lyari",
  projectName: "lyari-docs",
  onBrokenLinks: "throw",

  i18n: {
    defaultLocale: "en",
    locales: ["en"],
  },

  markdown: {
    mermaid: true,
  },

  themes: ["@docusaurus/theme-mermaid"],

  presets: [
    [
      "classic",
      {
        docs: {
          sidebarPath: "./sidebars.ts",
          routeBasePath: "/",
        },
        blog: false,
        theme: {
          customCss: "./src/css/custom.css",
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    navbar: {
      title: "Lyari",
      items: [
        {
          type: "docSidebar",
          sidebarId: "docsSidebar",
          position: "left",
          label: "Documentation",
        },
        {
          href: "https://github.com/your-org/lyari",
          label: "GitHub",
          position: "right",
        },
      ],
    },
    footer: {
      style: "dark",
      links: [
        {
          title: "Docs",
          items: [
            { label: "Getting Started", to: "/getting-started/prerequisites" },
            { label: "Database", to: "/database/schema" },
            { label: "Web App", to: "/web-app/overview" },
          ],
        },
        {
          title: "More",
          items: [
            { label: "GitHub", href: "https://github.com/your-org/lyari" },
          ],
        },
      ],
      copyright: `Copyright ${new Date().getFullYear()} Lyari. Built with Docusaurus.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ["dart", "sql", "toml", "bash"],
    },
    mermaid: {
      theme: { light: "neutral", dark: "dark" },
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
