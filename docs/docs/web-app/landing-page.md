---
sidebar_position: 1
---

# Landing Page

Route: `/`

The landing page is a **public** marketing page accessible to both authenticated and unauthenticated users. It serves as the entry point to the app.

## Sections

| Section | Description |
|---------|-------------|
| **Hero** | Headline, sub-headline, and primary CTA button |
| **Features** | Grid of feature cards highlighting personal expenses, group splitting, analytics, and more |
| **CTA** | Call-to-action section encouraging sign-up |

## Auth-Aware Behavior

The page checks the user's authentication state and adjusts CTAs accordingly:

| User State | CTA Text | Links To |
|------------|----------|----------|
| Unauthenticated | "Get Started" / "Sign Up" | `/register` |
| Authenticated | "Go to Dashboard" | `/dashboard` |

## Middleware

The `/` route is listed as a **public route** in `web/middleware.ts`. Unauthenticated users are not redirected to `/login` when visiting the landing page. Previously, `/` redirected all visitors to `/dashboard` (which itself required authentication).

## Design

The landing page uses the same Tailwind CSS design tokens and component library as the rest of the app, maintaining visual consistency with the dashboard while presenting a distinct marketing layout.
