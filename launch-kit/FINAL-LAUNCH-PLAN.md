# Final Launch Plan — Build 10 → App Store

**Goal:** One full dress rehearsal in TestFlight with **zero mock data, real Twilio SMS, real signup-approval-login flow**. Once that passes end-to-end, submit to Apple with confidence.

Three phases:
1. **Dress Rehearsal Prep** — clean production, seed real data, flip bypass off
2. **Dress Rehearsal** — sign up + use the app as a real consumer
3. **Apple Submission** → **Public Launch**

---

# PHASE 1 — Dress Rehearsal Prep

**Time: ~90 min of your time + work for me. Most can run in parallel.**

## 1.1 — Production database cleanup

**State:** Production Supabase currently has TestFlight-era seed content (test posts, mock comments, possibly fake care-team assignments) that real consumers shouldn't see.

**Steps (I do via Chrome MCP, you watch + approve):**

1.1.1 — I run a read-only SQL audit query to list everything that looks like mock/test content:
- Posts with content like "test test test"
- Comments seeded for testing
- Profile rows with `username LIKE 'test_%'`
- Meeting rows that are demo seed data
- `staff_assignments` rows pointing at non-real staff

1.1.2 — I show you the list. You approve deletion.

1.1.3 — I run a single transactional cleanup SQL — wipe everything you approved.

1.1.4 — I verify: post-cleanup audit returns 0 rows of mock content.

**Click-by-click for you:** Just say "go" — I drive Chrome.

---

## 1.2 — Demo accounts decision

**State:** 3 demo accounts exist in `auth.users`: Alex Demo (alumni), Admin Demo, Super Admin Demo.

**Decision for you:**

- **Option A (recommended): Delete all 3 demo accounts entirely.** Your real account becomes the first admin. Cleanest state, no risk of someone finding their credentials post-launch.
- **Option B: Keep them but rename/strip the `is_test_account` flag so they become real-looking accounts.** Useful if you want demo content visible.
- **Option C: Keep them flagged + locked.** They exist for App Store Reviewer use only; never visible to consumers (the `is_test_account` filter handles this).

**My recommendation: A.** No demo accounts in production once we're past Apple review.

---

## 1.3 — Real care team seeding

**State:** Today the assigned staff in production are demo entries.

**Steps (you provide info, I seed):**

1.3.1 — You give me a list:
- Real Milton staff per facility (FL + OH)
- For each: full name, real phone number, real email, role (`case_manager` / `therapist` / `admin`)

1.3.2 — I create their `auth.users` rows + `profiles` rows + assign them to the correct facility.

1.3.3 — Initially nobody is assigned to anyone — when real alumni sign up, an admin manually assigns them to a staff member via the admin panel.

---

## 1.4 — Real meetings strategy

**Decision for you:**

- **Option A: Admin-entered meetings only.** Milton staff log in as admins and create real meeting rows. No BMTL/BMLT API integration. Simplest, most reliable.
- **Option B: BMLT real-API integration.** App pulls public NA/AA meeting data from BMLT (geographically filtered). Today the app has a mock + a real client; we'd flip the toggle.

**My recommendation: A for launch.** Add BMLT integration in v1.1.

**Steps:**
1.4.1 — Pick option above.
1.4.2 — If A: I delete any seeded BMLT mock meetings + leave the table empty for admins to populate.
1.4.3 — If B: I confirm the real BMLT client works against production + remove mock fallbacks.

---

## 1.5 — First admin account (chicken-and-egg fix)

**State:** Once demo accounts are deleted, there's no admin to approve real signups. We need at least one real admin before turning bypass off.

**Steps:**

1.5.1 — You give me your real phone number (the one you'll use as Ezra-the-admin).

1.5.2 — I create your real admin account in Supabase: `auth.users` + `profiles` row with `role = 'super_admin'`, `status = 'active'`, your real name, your phone.

1.5.3 — When you log into TestFlight with this phone, you'll receive a real Twilio OTP and land in the app as super_admin — able to approve other real signups.

---

## 1.6 — Server-side: flip DEMO_BYPASS_ENABLED → false

**State:** I just set it to `true` 10 minutes ago for Apple Review prep. We flip it OFF for the dress rehearsal.

**Steps (I do via Chrome MCP):**
1.6.1 — Supabase Dashboard → Edge Functions → Secrets → `DEMO_BYPASS_ENABLED` → Edit → value = `false` → Save.

1.6.2 — I trigger a test edge function call to confirm Twilio SMS actually fires (using your real phone — you'll get a text).

---

## 1.7 — Validate Twilio + Resend + APNS work end-to-end

**Steps (mostly automated):**

1.7.1 — **Twilio SMS:** I invoke `send-sms-otp` against your real phone. You confirm the SMS arrives within 30s.

1.7.2 — **Resend welcome email:** Once you create your real admin profile, the welcome email should fire. Confirm it lands in your inbox.

1.7.3 — **APNS push:** Push registration happens automatically on first launch. We test this in the next phase (TestFlight signup).

---

## 1.8 — Document key info you'll need

I'll write a `DRESS-REHEARSAL-CREDENTIALS.md` (private, gitignored) with:
- Your real admin phone
- Real care-team names (no passwords — phone-OTP only)
- Supabase Dashboard direct links
- Twilio console link (for checking SMS delivery logs if something fails)
- Resend dashboard link

---

# PHASE 2 — The Dress Rehearsal (you, on a real iPhone)

**Time: ~60 min active + several days passive use.**

## 2.1 — Install Build 10 fresh

2.1.1 — Delete the existing TestFlight Build 10 install on your phone (Settings → General → iPhone Storage → Milton → Delete App). This wipes Keychain so you start truly fresh.

2.1.2 — Open TestFlight app → Milton → Install. Wait for download.

## 2.2 — Sign up as a real new alumni (one of two paths)

**Path A (most realistic): Use a SECOND phone.** Your real phone is admin (Step 1.5). Use a partner's/spouse's/colleague's phone OR a different number you control to simulate a real alumni signing up. This is the gold-standard dress rehearsal.

**Path B (acceptable): Use your one phone.** Sign up with your real phone first (alumni). Approve yourself later via Supabase Dashboard SQL. Less realistic but works if you only have one device.

**Steps (Path A — using a second phone):**

2.2.1 — On the second phone, open Milton → tap "Sign Up" (not Sign In)

2.2.2 — Enter the second phone's real number → tap Send Code

2.2.3 — Real SMS arrives on the second phone within 30s → enter the code → Verify

2.2.4 — Fill in signup form: full name, sobriety date, etc.

2.2.5 — Submit → "Application submitted, awaiting admin approval"

2.2.6 — *On your real-admin phone (TestFlight, same app):* push notification arrives: "New Member Request"

2.2.7 — Open the admin dashboard → Pending Users → review the new signup → Approve → assign to a facility (FL or OH)

2.2.8 — *Back on the second phone:* push notification arrives: "You're Approved!"

2.2.9 — Second phone logs into the app fully → sees the empty community feed (because mock data was wiped), can post, comment, etc.

## 2.3 — Exercise every feature as a real consumer

Open `launch-kit/TESTFLIGHT-QA-BUILD-10.md` and walk every section. The difference this time: **everything is real**, no demo accounts, no fake OTPs. If it breaks, it breaks for a real customer too.

Specifically test:
- Real Twilio SMS round-trip on cold login
- Welcome email arrives via Resend
- Push notifications actually deliver
- Photo upload from real photos library
- Real meetings showing in feed (or empty if no admin entered any yet)
- Care team in "I'm Struggling" → real staff phone numbers dial correctly (yours + the Milton FL/OH lines)
- Crisis content detection — type something the filter catches, confirm flagged + admin notified

## 2.4 — Multi-day soak test

Use the app for **3–5 days** as a normal consumer would. Things only surface after extended use:
- Token expiry / refresh
- Push notifications when app is fully closed for >24h
- Memory creep
- Background fetch / data freshness
- Battery drain
- Subtle UI bugs in different lighting / orientations

Take screenshots of anything that feels off. Send me the list at the end.

## 2.5 — Trigger every push notification type

Confirm every notification in `Docs/PUSH_NOTIFICATIONS.md` actually fires:
- [ ] Application submitted (alumni side)
- [ ] New member request (admin side)
- [ ] Account approved (alumni receives)
- [ ] Post approved
- [ ] Post not approved
- [ ] New comment
- [ ] Crisis content alert (admin receives)
- [ ] Struggling button alert (admin receives)
- [ ] Sobriety reset alert (admin receives)
- [ ] Emergency access privacy notice

---

# PHASE 3 — Apple Submission

**Time: ~30 min of your time. Apple takes 24–48h.**

## 3.1 — Pre-submission state setup

3.1.1 — *Flip `DEMO_BYPASS_ENABLED` BACK to `true`* via Supabase Dashboard. I do this via Chrome MCP. (Apple reviewers need it for their alumni demo login.)

3.1.2 — Verify the demo alumni account (Alex Demo / +15550001234) was kept (or re-create it if Phase 1.2 deleted it).

3.1.3 — Confirm the alumni demo account has clean, presentable content visible to reviewers — sample sobriety date, approved status, sample posts, assigned care team. *Re-seed minimal demo content under the demo alumni's user_id only, isolated from real users.*

## 3.2 — Bump version + archive

3.2.1 — Decide: Build 10 unchanged, OR cut Build 11 if anything from the dress rehearsal required a code fix.

3.2.2 — If Build 11: bump `CURRENT_PROJECT_VERSION` 10 → 11, commit, build, verify.

3.2.3 — Xcode → Top toolbar device → **Any iOS Device (arm64)**.

3.2.4 — Menu: Product → Clean Build Folder (⇧⌘K).

3.2.5 — Menu: Product → Archive. Wait 3–5 min.

3.2.6 — Organizer opens → select your new archive → Distribute App.

3.2.7 — App Store Connect → Upload → Automatically manage signing → Upload.

3.2.8 — Wait 10–30 min for processing. Email arrives: "Your build has completed processing."

## 3.3 — Fill App Review form

Follow `launch-kit/SUBMIT-BUILD-10.md` Sections 4 onwards exactly.

Key checkpoints:
- ☑ Sign-In Required
- Demo phone: `+15550001234`, OTP: `000000`
- Reviewer notes pasted verbatim from `SUBMIT-BUILD-10.md`
- Contact: ezra@miltonrecovery.com + your real phone
- ☑ Manually release this version
- Sweep left sidebar for red dots

## 3.4 — Submit for Review

Click **Add for Review** → **Submit for Review**.

Wait 24–48h. Expected response: Approved.

## 3.5 — If rejected

1. Read rejection email carefully — note the specific guideline number cited.
2. Cross-ref `launch-kit/07-rejection-recovery-playbook.md`.
3. Fix → Build 11 (or 12) → Re-submit.

---

# PHASE 4 — Day of Launch (after Apple approves)

**Time: 20 min of your time. Then app is live.**

## 4.1 — Flip the kill switch

4.1.1 — Supabase Dashboard → Edge Functions → Secrets → `DEMO_BYPASS_ENABLED` → value = `false` → Save.

4.1.2 — Verify: try logging in via TestFlight Build 10 with the demo phone `+15550001234` — confirm it now FAILS (because real Twilio doesn't have that fake number).

## 4.2 — Decide demo account fate

Either:
- Delete the 3 demo accounts entirely (recommended now)
- Leave them present but inert (they can't log in anyway since bypass is off)

## 4.3 — Real-phone smoke test against production

4.3.1 — Pull Build 10 from App Store (it's live now, just not "released" yet from your side — App Store Connect needs you to click Release).

Wait — actually, the app isn't on the public store until you click Release. So:

4.3.2 — Use TestFlight Build 10 (or pull from App Store after release if you flip the order).

4.3.3 — Sign up with your real phone (or someone else's) → real OTP → real flow.

4.3.4 — Approve → log in → confirm the full experience works against real production.

## 4.4 — Release

4.4.1 — App Store Connect → My Apps → Milton → Version 1.0 → **Release This Version**.

4.4.2 — App goes live on the App Store within ~24 hours (usually <2h).

## 4.5 — Watch the first 48 hours

- Supabase logs for errors
- Supabase Auth → Users tab for new signups
- Sentry/crash reports (if wired up)
- Inbound emails for support questions
- App Store reviews (Apple emails you new ones)

Have your phone on you. The first crisis flag from a real user is the moment that matters.

---

# Master Order of Operations

| # | Phase | Step | Who | Time |
|---|---|---|---|---|
| 1 | 1.1 | Audit + clean production mock data | Me | 10 min |
| 2 | 1.2 | Decide demo accounts (A/B/C) | You | 1 min |
| 3 | 1.3 | Real care-team list → seed | You + Me | varies |
| 4 | 1.4 | Meetings approach (A/B) | You | 1 min |
| 5 | 1.5 | Create your real admin account | Me | 5 min |
| 6 | 1.6 | Flip DEMO_BYPASS → false | Me | 1 min |
| 7 | 1.7 | Smoke-test Twilio + Resend | Me + You confirm | 10 min |
| 8 | 2.1 | Reinstall Build 10 fresh | You | 5 min |
| 9 | 2.2 | Real signup + admin approval | You | 10 min |
| 10 | 2.3 | Full feature QA pass | You | 30 min |
| 11 | 2.4 | 3–5 day soak test | You (passive) | days |
| 12 | 2.5 | Trigger every push notification | You | 30 min |
| 13 | 3.1 | Flip DEMO_BYPASS → true | Me | 1 min |
| 14 | 3.2 | Archive + upload | You in Xcode | 30 min |
| 15 | 3.3 | Fill ASC review form | You | 15 min |
| 16 | 3.4 | Submit for Review | You | 1 click |
| 17 | — | Apple reviews | Apple | 24–48h |
| 18 | 4.1 | Flip DEMO_BYPASS → false | Me | 1 min |
| 19 | 4.2 | Decide demo account deletion | You | 1 min |
| 20 | 4.3 | Real-phone production smoke | You | 15 min |
| 21 | 4.4 | Click Release in ASC | You | 1 click |
| 22 | 4.5 | Monitor first 48h | You | passive |

**Active time on your side (excluding soak test wait):** ~3 hours total spread over 5–7 days.

---

# What I need from you RIGHT NOW to start Phase 1

1. **Demo accounts decision** — A, B, or C from Section 1.2?
2. **Meetings approach** — A (admin-entered) or B (BMLT real)?
3. **Your real phone number** for the admin account (so I can seed it in Step 1.5)
4. **Real care-team list** — names + phones + emails + facility for FL and OH staff (you can send this in stages — just give me whoever you have ready)
5. **A second phone you can use as the "real alumni"** during dress rehearsal (or confirm you'll use Path B with your one phone)
6. **Twilio BAA status** — signed, in-process, or unknown? (Not a TestFlight blocker but a public-launch blocker)

Answer those 6 things and I'll start executing Phase 1 immediately via Chrome MCP. I'll show you everything before destructive changes.
