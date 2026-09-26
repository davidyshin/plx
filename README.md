# plx guild roster

A public, collaborative World of Warcraft guild preference board built with React, Supabase, and Netlify.

## Local setup

1. Create a Supabase project.
2. Run `supabase/schema.sql` in the Supabase SQL editor.
3. Copy `.env.example` to `.env` and add the project URL and publishable key from the Supabase Connect dialog.
4. Run `npm install` and `npm run dev`.

The included RLS policies intentionally allow anyone with the site URL to read, add, and remove preferences. Never put a Supabase service-role key in the frontend.

## Netlify

Import this folder as a new site. Netlify reads `netlify.toml`. Add `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` under Site configuration → Environment variables, then deploy.

## Namecheap domain

In Netlify, open Domain management → Add a domain you already own. Netlify will show the exact DNS records. In Namecheap Advanced DNS, add those records (typically an ALIAS/A record for the apex and a CNAME for `www`). Enable Netlify-managed HTTPS after DNS resolves.
