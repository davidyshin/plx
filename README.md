# plx guild roster

## PlxTogether

The installation guide is served at `/plxtogether/` with a link from the roster page. Addon source and tests live in `addons/PlxTogether`.

Push a `plxtogether-v0.4.0` tag or run the **PlxTogether friends package** GitHub Actions workflow to test, build, and publish the single friends download. It contains PlxTogether, the checksum-verified Questie 12.0.4 + QuestieDB 1.0.5 package, matching upstream source archives, notices, and a Windows installer. The website enables its complete-package button once that release asset exists. Netlify deploys the guide with the existing site build.

Build locally from a network-enabled PowerShell terminal with `./addons/PlxTogether/Build-Friends-Bundle.ps1`. Output goes to the ignored `addons/PlxTogether/dist` folder. Pass `-QuestieZip` to reuse an already downloaded official ZIP; its SHA256 is still checked. No large Questie archives are committed to Git.

Hero artwork: “Orgrimmar: Horde Territory” by Leonardo a.C., featured by Blizzard in its community fan-art spotlight.

A public, collaborative World of Warcraft guild preference board built with React, Supabase, and Netlify.

## Local setup

1. Create a Supabase project.
2. Run `supabase/schema.sql` in the Supabase SQL editor.
3. Copy `.env.example` to `.env`, add the project URL and publishable key from the Supabase Connect dialog, and set `VITE_SITE_PASSWORD`.
4. Run `npm install` and `npm run dev`.

The included RLS policies intentionally allow anyone with the site URL to read, add, and remove preferences. Never put a Supabase service-role key in the frontend.

## Netlify

Import this folder as a new site. Netlify reads `netlify.toml`. Add `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY` under Site configuration → Environment variables, then deploy.

The roster is public to view. The password unlocks add/remove controls for the current browser session. This gate runs entirely in the browser and is only a casual-access deterrent; it does not secure the Supabase API.

## Namecheap domain

In Netlify, open Domain management → Add a domain you already own. Netlify will show the exact DNS records. In Namecheap Advanced DNS, add those records (typically an ALIAS/A record for the apex and a CNAME for `www`). Enable Netlify-managed HTTPS after DNS resolves.
