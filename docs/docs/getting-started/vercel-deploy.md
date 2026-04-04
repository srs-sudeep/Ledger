---
sidebar_position: 5
---

# Vercel Deployment

The repo includes a `vercel.json` at the root that tells Vercel how to build and output the Next.js web app.

## Setup

1. Push the repo to GitHub / GitLab / Bitbucket.
2. In [Vercel](https://vercel.com) > **Add New > Project** > import the repo.
3. Set **Root Directory** to `web` in the Vercel project settings (under **General > Root Directory**), or leave it at the repo root and rely on the `vercel.json` build/output commands.
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
