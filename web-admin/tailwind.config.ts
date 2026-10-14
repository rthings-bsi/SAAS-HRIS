import type { Config } from "tailwindcss";

const config: Config = {
  content: [
    "./src/pages/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/components/**/*.{js,ts,jsx,tsx,mdx}",
    "./src/app/**/*.{js,ts,jsx,tsx,mdx}",
  ],
  theme: {
    extend: {
      colors: {
        canvas: "#FFFFFF",
        surface: "#F8FAFC",
        "surface-muted": "#F8FAFC",
        "ink-primary": "#0F172A",
        "ink-muted": "#475569",
        "border-neutral": "#CBD5E1",
        "action-accent": "#16A34A",
        "action-accent-hover": "#15803D",
        orange: {
          50: "#FFF7ED",
          100: "#FFEDD5",
          200: "#FED7AA",
          500: "#F97316",
          600: "#EA580C",
        },
        danger: {
          50: "#FEF2F2",
          100: "#FEE2E2",
          200: "#FECACA",
          600: "#DC2626",
          700: "#B91C1C",
        },
        "danger-bg": "#FEF2F2",
        "danger-text": "#B91C1C",
        "danger-border": "#FECACA",
        semantic: {
          success: "#10B981",
          "success-bg": "#ECFDF5",
          warning: "#F59E0B",
          "warning-bg": "#FFFBEB",
          danger: "#E11D48",
          "danger-bg": "#FFF1F2",
          info: "#3B82F6",
          "info-bg": "#EFF6FF",
        },
      },
      fontFamily: {
        sans: ["var(--font-geist-sans)", "system-ui", "-apple-system", "sans-serif"],
        mono: ["var(--font-geist-mono)", "ui-monospace", "monospace"],
      },
      borderRadius: {
        md: "6px",
        lg: "8px",
      },
    },
  },
  plugins: [],
};

export default config;
