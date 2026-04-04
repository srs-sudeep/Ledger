import type { Config } from "tailwindcss";

const config: Config = {
  darkMode: "class",
  content: [
    "./pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./components/**/*.{js,ts,jsx,tsx,mdx}",
    "./app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        surface: {
          DEFAULT: "#faf8ff",
          bright: "#faf8ff",
          dim: "#d2d9f4",
          container: {
            DEFAULT: "#eaedff",
            low: "#f2f3ff",
            lowest: "#ffffff",
            high: "#e2e7ff",
            highest: "#dae2fd",
          },
          tint: "#0053db",
          variant: "#dae2fd",
        },
        primary: {
          DEFAULT: "#000000",
          container: "#00174b",
          fixed: "#dbe1ff",
          "fixed-dim": "#b4c5ff",
        },
        secondary: {
          DEFAULT: "#515f74",
          container: "#d5e3fc",
          fixed: "#d5e3fc",
          "fixed-dim": "#b9c7df",
        },
        tertiary: {
          DEFAULT: "#000000",
          container: "#271901",
          fixed: "#fcdeb5",
          "fixed-dim": "#dec29a",
        },
        error: {
          DEFAULT: "#ba1a1a",
          container: "#ffdad6",
        },
        outline: {
          DEFAULT: "#76777d",
          variant: "#c6c6cd",
        },
        "on-surface": {
          DEFAULT: "#131b2e",
          variant: "#45464d",
        },
        "on-primary": {
          DEFAULT: "#ffffff",
          container: "#497cff",
          fixed: "#00174b",
          "fixed-variant": "#003ea8",
        },
        "on-secondary": {
          DEFAULT: "#ffffff",
          container: "#57657a",
          fixed: "#0d1c2e",
          "fixed-variant": "#3a485b",
        },
        "on-tertiary": {
          DEFAULT: "#ffffff",
          container: "#98805d",
          fixed: "#271901",
          "fixed-variant": "#574425",
        },
        "on-error": {
          DEFAULT: "#ffffff",
          container: "#93000a",
        },
        "on-background": "#131b2e",
        "inverse-surface": "#283044",
        "inverse-on-surface": "#eef0ff",
        "inverse-primary": "#b4c5ff",
        background: "#faf8ff",
      },
      fontFamily: {
        headline: ["var(--font-manrope)", "sans-serif"],
        body: ["var(--font-inter)", "sans-serif"],
        label: ["var(--font-inter)", "sans-serif"],
      },
      boxShadow: {
        ambient: "0 12px 40px -12px rgba(19, 27, 46, 0.08)",
        "ambient-lg": "0 16px 48px -12px rgba(19, 27, 46, 0.12)",
      },
      borderRadius: {
        DEFAULT: "0.125rem",
        lg: "0.25rem",
        xl: "0.5rem",
        "2xl": "1rem",
        "3xl": "1.5rem",
        "4xl": "2rem",
      },
    },
  },
  plugins: [require("tailwindcss-animate")],
};
export default config;
