# Day-of-Launch Runbook

When Apple emails "Your app is approved" — follow this runbook **in order**, **same day**.

---

## ⏱ T-0:00 — Apple approval received

You'll get an email like:
> "Your app, Milton Nation Alumni, has been approved..."

Do NOT click "Release This Version" yet. Work through the checklist first.

---

## ⏱ T+0:05 — Disable demo bypass (CRITICAL — first thing)

Without this, anyone who guesses the demo phone (`+15550001234`) can sign in.

1. Open https://supabase.com/dashboard/project/hksxzuytcmqqwxmfjzdp/functions/secrets
2. Find `DEMO_BYPASS_ENABLED` → click → change value to `false`
3. Save

OR I can do this for you — just say "disable demo bypass".

**Verify** by hitting the verify-sms-otp function:
```bash
curl https://hksxzuytcmqqwxmfjzdp.supabase.co/functions/v1/verify-sms-otp \
  -X POST \
  -H "apikey: $SUPABASE_ANON_KEY" \
  -H "Content-Type: application/json" \
  -d '{"code":"000000"}'
```
Should return `{"error":"Missing authorization header"}` (which means the function is live and the bypass code path won't fire even with valid auth).

---

## ⏱ T+0:10 — Confirm A2P Campaign approval

If your A2P 10DLC Campaign is still **Pending**, **stop here**. Real users won't receive OTPs without it.

1. Open https://console.twilio.com/us1/develop/sms/regulatory-compliance/brands
2. Confirm Campaign status = **Approved**
3. If Pending: hold the App Store release until Approved. Most users won't notice the day-1 delay; broken sign-up will tank your launch.

If Approved: continue.

---

## ⏱ T+0:15 — Smoke test on a real iPhone

Install the production build on **your own iPhone** via TestFlight first (one final verification):

1. App Store Connect → TestFlight → Internal Testing → invite your own Apple ID
2. Install via TestFlight on iPhone
3. Walk through these flows in this order:

| Test | Pass criteria |
|---|---|
| Open app fresh | Login screen appears, no crashes |
| Sign up with your real phone | OTP arrives within 30 seconds |
| Enter OTP | Lands on pending-approval screen |
| **(switch hat to admin)** Approve yourself in admin dashboard | Real-time push lands on phone |
| Re-open app | Goes to home screen |
| Tap "I'm Struggling" → toggle "Notify Care Team" | Local notification fires |
| Create a community post with text + photo | Post appears (or pending review if first post) |
| Open chat with a care team member | Message thread loads |
| Send a text message | Bubble appears immediately, real-time on other device |
| Send a photo | Image renders (not a placeholder) |
| Pull-to-refresh on community feed | Spinner appears, completes |
| Reset sobriety date in profile | Updates immediately, persists across app relaunch |
| Force-quit + reopen | Auto-signs in (Keychain restore works) |
| Open Settings → Delete My Account | 30-day confirmation alert appears |

If any test fails, **don't release**. Fix and submit a new build. (App Store Connect lets you replace the approved build with a new one without re-review for the same version, as long as you don't change metadata.)

---

## ⏱ T+0:45 — Pre-release sanity checks

| Check | How |
|---|---|
| Welcome email lands | Sign up a fresh phone → check inbox |
| Push notifications work | Have admin approve a test signup → verify push lands |
| Storage uploads work | Upload profile photo → confirm AsyncImage renders it |
| Chat real-time works | Two devices, send message, verify <2s delivery |
| Crash report capture | Force a test crash via dev menu (or just verify `crash_reports` table has at least one row from TestFlight) |

---

## ⏱ T+1:00 — Click "Release This Version"

1. App Store Connect → your app → top-right **Release This Version**
2. Confirm
3. Apple typically pushes globally within 1 hour, but can take up to 24h

---

## ⏱ T+1:00 to T+24:00 — Watch the dashboards

Keep these tabs open for the first 24 hours:

| Dashboard | What to watch |
|---|---|
| https://appstoreconnect.apple.com/apps → Analytics | Installs, sessions |
| https://supabase.com/dashboard/project/hksxzuytcmqqwxmfjzdp/database/tables → profiles | New rows = new signups |
| https://supabase.com/dashboard/project/hksxzuytcmqqwxmfjzdp/database/tables → crash_reports | New rows = something is breaking |
| https://supabase.com/dashboard/project/hksxzuytcmqqwxmfjzdp/database/tables → audit_logs | Login activity |
| https://console.twilio.com → Monitor → Messaging | SMS delivery rates (should be >95%) |
| https://resend.com/emails | Welcome email delivery |
| https://www.apple.com/itunes/charts/ | Optional — see if you crack any subcategory |

---

## Common day-1 issues + responses

### Issue: "I never got my OTP"

1. Check Twilio Console → Messaging → Logs → search by phone number
2. If "Delivered" status: user device issue (carrier filtering, airplane mode) — tell them to wait + retry
3. If "Undelivered" status: check the error code → most often carrier filtering for unverified A2P
4. If error code 30007 ("Carrier Violation"): your A2P Campaign isn't fully linked to the phone number. Twilio Console → Messaging → Services → assign your number to the approved Campaign.

### Issue: "App crashed when I opened it"

1. Check `crash_reports` table — search for the timestamp
2. If reproducible: hot-fix and submit a new build (Apple usually approves bug-fix builds within 24h)
3. If isolated: monitor for 24h before deciding to roll out a fix

### Issue: "I got approved but the app says I'm still pending"

1. Check `profiles` table for the user
2. If `status = 'active'` but app shows pending: client-side cache issue. Tell user to force-quit + reopen.
3. If `status = 'pending'` still: admin didn't approve. Approve via admin dashboard.

### Issue: "Push notifications not arriving"

1. Check `device_tokens` table — does the user have a row?
2. If yes: check `push_notification_log` for delivery attempts
3. If no row: user denied permission. Tell them: Settings → Notifications → Milton Alumni → Allow Notifications.

---

## After 24 hours stable

1. Send announcement to alumni list (use the same template from launch-kit if applicable).
2. Post on Milton Recovery Centers' website + social media.
3. Email staff: "App is live, here's how to use the admin dashboard."
4. Schedule first post-launch retrospective for T+7 days.

🎉 **You shipped.**
