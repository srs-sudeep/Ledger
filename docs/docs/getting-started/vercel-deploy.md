---
sidebar_position: 5
---

# Vercel Deployment

The Next.js app lives in `web/`. There is **no** `vercel.json` in the repository -- the framework is auto-detected by Vercel when the Root Directory is set correctly.

## Setup

1. Push the repo to GitHub / GitLab / Bitbucket.
2. In [Vercel](https://vercel.com) > **Add New > Project** > import the repo.
3. **Required:** Set **Root Directory** to `web` (**Settings > General > Root Directory**). The install and build commands then run inside `web/` automatically (`npm install`, `npm run build`). Do not use a root-level `vercel.json` -- it is not needed and can cause issues.
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
