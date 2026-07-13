import type { Config } from "tailwindcss";

const config: Config = {
  darkMode: "class",
  content: ["./index.html", "./src/**/*.{js,ts,jsx,tsx}"],
  theme: {
    extend: {
      colors: {
        surface: {
          DEFAULT: "#faf8ff",
          container: {
            DEFAULT: "#eaedff",
            low: "#f2f3ff",
            lowest: "#ffffff",
            high: "#e2e7ff",
          },
          tint: "#0053db",
        },
        primary: { DEFAULT: "#000000", container: "#00174b" },
        secondary: { DEFAULT: "#515f74", container: "#d5e3fc" },
        error: { DEFAULT: "#ba1a1a", container: "#ffdad6" },
        outline: { DEFAULT: "#76777d", variant: "#c6c6cd" },
        "on-surface": { DEFAULT: "#131b2e", variant: "#45464d" },
        "on-primary": { DEFAULT: "#ffffff" },
        background: "#faf8ff",
      },
      fontFamily: {
        headline: ["Manrope", "sans-serif"],
        body: ["Inter", "sans-serif"],
      },
      boxShadow: {
        ambient: "0 12px 40px -12px rgba(19, 27, 46, 0.08)",
        "ambient-lg": "0 16px 48px -12px rgba(19, 27, 46, 0.12)",
      },
    },
  },
  plugins: [],
};
export default config;
