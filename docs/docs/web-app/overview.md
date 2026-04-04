---
sidebar_position: 1
---

# Web App Overview

The web dashboard is the "Command Center" for detailed analytics, complex group management, and bulk entries.

## Tech Stack

- **Next.js 14** with App Router
- **React 18** with Server Components
- **Tailwind CSS** with custom design tokens
- **Shadcn-style** custom UI components (CVA-based)
- **Recharts** for analytics charts
- **Supabase SSR** for auth and data fetching
- **Lucide React** for icons

## Architecture

```mermaid
graph TB
  subgraph layout [App Layout]
    RootLayout[Root Layout]
    AuthLayout["(auth) Layout"]
    DashLayout["(dashboard) Layout"]
  end

  subgraph auth [Auth Routes]
    Login["/login"]
    Register["/register"]
    Callback["/auth/callback"]
  end

  subgraph dash [Dashboard Routes]
    Dashboard["/dashboard"]
    Accounts["/accounts"]
    Personal["/personal"]
    Groups["/groups"]
    GroupDetail["/groups/[id]"]
    Analytics["/analytics"]
  end

  RootLayout --> AuthLayout --> auth
  RootLayout --> DashLayout --> dash
```

## Key Patterns

- **Server Components** for data fetching (no client-side fetching for initial loads)
- **Client Components** for interactive forms and dialogs
- **`loading.tsx`** files in every route group for skeleton loading states
- **`useTransition`** in sidebar for navigation progress indicators
- All monetary values stored as integer cents, formatted on display
