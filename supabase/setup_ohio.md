# Ohio Supabase Project Setup Guide

Complete this guide after creating the Ohio Supabase project.

---

## Step 1 — Create the Ohio Supabase Project

1. Go to [supabase.com/dashboard](https://supabase.com/dashboard)
2. Click **New Project**
3. Name: `Milton Nation Ohio`
4. Region: Choose closest to Ohio users (e.g. `us-east-1`)
5. Generate a strong database password and save it
6. Click **Create new project** (takes ~2 min)

---

## Step 2 — Run Schema

1. Dashboard → SQL Editor → New Query
2. Paste the entire contents of `supabase/schema.sql`
3. Click **Run** — you should see "Success"

---

## Step 3 — Run All Migrations (in order)

Run each migration file in Supabase SQL Editor in date order:

1. `migrations/20260225_add_sms_otp_challenges.sql`
2. `migrations/20260226_security_rls_fixes.sql`
3. `migrations/20260226002_add_content_flags.sql`
4. `migrations/20260302_add_analytics_events.sql`
5. `migrations/20260302_add_crash_reports.sql`
6. `migrations/20260304_add_emergency_access_log.sql`
7. `migrations/20260311_performance_and_constraints.sql`
8. `migrations/20260331_add_facility_isolation.sql`

---

## Step 4 — Run Seeds

1. `supabase/seed.sql` — badges, quotes, announcements
2. `supabase/seed_admin_accounts.sql` — after creating admin auth users

---

## Step 5 — Deploy Edge Functions

Run from terminal in the project root (requires Supabase CLI):

```bash
supabase functions deploy send-sms-otp      --project-ref OHIO_PROJECT_ID
supabase functions deploy verify-sms-otp    --project-ref OHIO_PROJECT_ID
supabase functions deploy flag-content      --project-ref OHIO_PROJECT_ID
supabase functions deploy send-push-notification --project-ref OHIO_PROJECT_ID
supabase functions deploy send-welcome-email --project-ref OHIO_PROJECT_ID
supabase functions deploy send-invite-sms   --project-ref OHIO_PROJECT_ID
```

---

## Step 6 — Add Secrets

Dashboard → Edge Functions → Manage Secrets → Add each:

| Secret | Value |
|--------|-------|
| `TWILIO_ACCOUNT_SID` | Same as Florida |
| `TWILIO_AUTH_TOKEN` | Same as Florida |
| `TWILIO_PHONE_NUMBER` | Same as Florida (single number covers both) |
| `RESEND_API_KEY` | Same as Florida |
| `APNS_KEY_ID` | Same as Florida |
| `APNS_TEAM_ID` | `VUQQKR3A6A` |
| `APNS_PRIVATE_KEY` | Same .p8 key as Florida |
| `DEMO_BYPASS_ENABLED` | `true` (for App Store review, disable after approval) |

---

## Step 7 — Update Ohio Credentials in App

1. Get the Ohio Project ID and anon key from:
   Dashboard → Project Settings → API → `Project URL` and `anon public` key

2. Update `Models/User.swift` — find the `case .ohio:` blocks and replace:
   - `supabaseURL`: Replace `OHIO_PROJECT_ID` with real project ID
   - `supabaseAnonKey`: Replace `OHIO_ANON_KEY_PLACEHOLDER` with real anon key

3. Update `Config/Ohio/Debug.xcconfig` and `Config/Ohio/Release.xcconfig` with the same values.

---

## Step 8 — Set Up Storage Buckets

Dashboard → Storage → New Bucket:
- `post-media` (private)
- `profile-photos` (private)
- `chat-media` (private)

Then run `supabase/storage_policies.sql` in SQL Editor.

---

## Step 9 — Apple Developer

1. Register new Bundle ID: `com.miltonrecovery.ohio-nation`
2. Enable Push Notifications capability
3. Create new App Store Connect listing

---

## Checklist

- [ ] Ohio Supabase project created
- [ ] `schema.sql` executed
- [ ] All 8 migrations executed
- [ ] `seed.sql` executed
- [ ] All 6 Edge Functions deployed
- [ ] All 8 secrets added
- [ ] Ohio credentials filled into `User.swift` and xcconfig files
- [ ] Storage buckets created
- [ ] Apple Bundle ID registered
- [ ] App Store Connect listing created
