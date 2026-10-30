# Café stock tracker

Single-page stock tracker for the Jurong, Orchard and Tampines outlets. Stock levels, reorder levels and the combined supplier order list are read from and saved to Supabase.

- `index.html` — the whole app (no build step).
- `vercel.json` — static hosting config with security headers.
- `supabase/migrations/` — schema for `items`, `stock_counts` and the `stock_latest` view, with row-level security.

## Deploy on Vercel

1. In Vercel, **Add New → Project** and import this GitHub repo.
2. Framework preset: **Other**. Leave the build command and output directory empty.
3. Deploy. Every push to `main` redeploys automatically.

No environment variables are needed: the Supabase URL and **publishable** key are in `index.html`, which is safe because access is enforced by row-level security in the database.

## Access

- Anyone with the link can view stock, Low items and the supplier order list — no sign-in needed.
- To save changes, use **Sign in** (top right) with your team username and password (the same accounts as the meeting tracker). Only users with `profiles.is_admin = true` can save; this is enforced by row-level security in Supabase, not just the UI.

## Managing users

Admins see a **Users** tab. From there they can:

- **Add a user** with a username and initial password (optionally as admin). New users must choose their own password on first sign-in.
- **Reset a password** to a new temporary one; the user must change it at next sign-in.
- **Grant or remove admin** rights (you can't remove your own).
- **Remove a user.**

Accounts live in Supabase Auth (`auth.users`, passwords bcrypt-hashed), with roles in `public.profiles`. Usernames map to `<username>@meet-tracker.local` and are shared with the meeting tracker. All user actions go through admin-only database functions (`admin_create_user`, `admin_reset_password`, `admin_set_admin`, `admin_delete_user`, `admin_list_users`), which reject anyone who isn't an admin.

## How saving works

Each save writes a row to `stock_counts` for today's date. Saving the same item again on the same day overwrites that day's figure; earlier days are kept as history. The app always shows the latest count per outlet and item.

## Order from suppliers

Shortfall per outlet = reorder level − on hand (only positive values), totalled across outlets. Items at or below their reorder level are marked **Low**.

## If the Supabase project changes

Update `SUPABASE_URL` and `SUPABASE_KEY` in `index.html`, and the `connect-src` entry in `vercel.json`'s Content-Security-Policy to match the new project URL.
