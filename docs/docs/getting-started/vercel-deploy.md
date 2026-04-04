---
sidebar_position: 5
---

# Vercel Deployment

The web app is configured for Vercel deployment via a `vercel.json` at the repo root.

## Setup

1. Push the repo to GitHub / GitLab / Bitbucket.
2. In [Vercel](https://vercel.com) > **Add New > Project** > import the repo.
3. The `vercel.json` file sets `rootDirectory` to `web`, so Vercel auto-detects the Next.js project.
4. Add environment variables:

| Name | Value |
|------|-------|
| `NEXT_PUBLIC_SUPABASE_URL` | Your Supabase project URL |
| `NEXT_PUBLIC_SUPABASE_ANON_KEY` | Your anon key |

5. Deploy.

## Post-Deploy

Update Supabase authentication URLs:

- **Site URL**: `https://your-app.vercel.app`
- **Redirect URLs**: `https://your-app.vercel.app/**`

## Custom Domain

1. Add a custom domain in Vercel project settings.
2. Add that domain to Supabase **Authentication > URL Configuration > Redirect URLs**.
