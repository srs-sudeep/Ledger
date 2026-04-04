---
sidebar_position: 1
---

# Prerequisites

Before setting up The Ledger, ensure you have the following installed:

## Required

| Tool | Version | Purpose |
|------|---------|---------|
| **Node.js** | 18+ | Next.js web app and Docusaurus docs |
| **npm** or **pnpm** | Latest | Package management |
| **A Supabase project** | -- | Database, auth, and Edge Functions |

## Optional

| Tool | Version | Purpose |
|------|---------|---------|
| **Flutter** | 3.x (stable) | Mobile app development |
| **Android Studio** | Latest | Android emulator and SDK |
| **Xcode** | Latest | iOS development (macOS only) |
| **Supabase CLI** | Latest | Local dev, migrations, Edge Function deploys |

## Create a Supabase Project

1. Go to [supabase.com/dashboard](https://supabase.com/dashboard) and create a new project.
2. Note your **Project URL** and **anon public key** from **Project Settings > API**.
3. Note your **Project Reference ID** from the dashboard URL or **Project Settings > General**.

These values will be used as environment variables in both the web and mobile apps.
