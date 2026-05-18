# Milton Nation — Launch Checklist (Single Source of Truth)

Everything from RIGHT NOW until consumers are downloading the app from the App Store and using it daily.

**Current state going into this checklist:**
- ✅ Build 10 uploaded to TestFlight, installed on Ezra's phone
- ✅ Production Supabase cleaned: 0 mock posts, 0 mock comments, 0 mock messages
- ✅ All 8 accounts in production have known passwords (`Milton2026!`)
- ✅ Phones attached: Ezra alumni (+12017477727), Florida Admin (+19296172795), Super Admin placeholder (+15550009999)
- ✅ Profile.phone column synced to auth.users.phone (Edge Function bug fixed)
- ✅ DEMO_BYPASS_ENABLED = `false` (for dress-rehearsal real-Twilio testing)
- ✅ Email domain normalized to `@miltonrecovery.com`
- ❌ Last SMS test on May 14: SMS did not arrive. Probable cause = A2P 10DLC not registered with US carriers (silent drop)
- ❌ Twilio BAA not signed
- ❌ Apple submission not done (Build 10 archive not yet uploaded with final review form)

---

# PHASE 0 — TODAY (parallel tasks, ~60 min active)

These all happen in parallel. Don't wait between them.

## 0.1 — Decide on the branded welcome email (1 min)

You've seen both PDFs in `launch-kit/email-previews/`:
- `01-CURRENT.pdf` — off-brand blue header
- `02-PROPOSED.pdf` — milton serif wordmark, real brand color band, dark footer with FL/OH numbers, 988 crisis snippet

**Tell me: ship the proposed design or keep the current.**
- If proposed → I rewrite `supabase/functions/send-welcome-email/index.ts` and redeploy (~5 min, no app rebuild needed since it's server-side)
- If current → no action

## 0.2 — Send the Twilio BAA request email (2 min)

1. Open `launch-kit/TWILIO-BAA-SEND-NOW.md`
2. Find your Twilio Account SID in `console.twilio.com` → top-right dropdown → Account info (32-char string starting with `AC`)
3. Paste it into the email template + your registered business address
4. Send to `privacy@twilio.com`
5. Tell me when sent — I'll add a reminder to follow up in 5 business days

**Timeline after sending:** 1–2 weeks total. BAA in hand before Apple approves you.

## 0.3 — Log into Twilio and let me audit your account (5 min)

I can't enter your password (security rule). You log in, then I drive.

1. Open `console.twilio.com` in Chrome (I have the tab open)
2. Sign in with your email + password
3. Tell me "I'm in"
4. I'll then drive Chrome to check:
   - **Account tier**: Trial or Paid? (BAA requires paid)
   - **A2P 10DLC**: Brand registered? Campaign registered? **This is the #1 suspect for why SMS didn't arrive yesterday.**
   - **Message logs**: Did the OTP attempt yesterday actually reach Twilio, or did it never leave the Edge Function?
   - **HIPAA eligibility flag**: shown on account settings if/when activated

## 0.4 — Retry SMS smoke test in TestFlight (3 min)

The profile.phone bug from yesterday is fixed. Retry to confirm whether SMS works now:

1. Open TestFlight Milton on your iPhone
2. Log out if logged in (Profile → Logout)
3. Login screen → Email: `media@miltonjefferson.com` → Password: `Milton2026!` → Login
4. Wait 30s
5. **Report back:**
   - ✅ SMS arrived → great, Twilio is working, just need to check why some carriers might still drop
   - ❌ No SMS in 60s → confirms A2P 10DLC is the issue; we register it in Phase 1

---

# PHASE 1 — Fix SMS Delivery (depends on what Twilio audit shows)

## 1.A — If Twilio account is on Trial

1. Console → Billing → Add payment method → Upgrade to Paid
2. Cost: ~$1 to upgrade + ~$0.0083/SMS sent
3. Re-verify your phone in Phone Numbers → Verified Caller IDs (Trial-only requirement)

## 1.B — Register A2P 10DLC (most likely fix for SMS not arriving)

Without this, US carriers silently drop your SMS. **This is independent of the BAA — different process, also required.**

### Step 1 — Brand registration (~5 min to submit, 1–3 days to approve)

1. Console → Messaging → Regulatory Compliance → A2P 10DLC → **Register Brand**
2. Brand type: **Standard Brand** (paid, $4 one-time)
3. Fill in:
   - Legal company name: Milton Recovery Centers (or your registered entity)
   - DBA: Milton Nation
   - Tax ID (EIN): your federal EIN
   - Business website: `https://miltonrecovery.com`
   - Vertical: **Healthcare**
   - Stock symbol: leave blank (you're private)
   - Address: registered business address
   - Contact: Ezra Barishansky, media@miltonjefferson.com, (201) 747-7727
4. Submit → status goes from "pending" → "verified" usually within 24 hours

### Step 2 — Campaign registration (~5 min to submit, instant approval after brand)

1. Same page → **Register Campaign**
2. Campaign type: **Account Notifications** or **2FA / OTP** (these are "low risk" use cases, cheapest)
3. Description: "One-time SMS verification codes for Milton Nation alumni app phone authentication"
4. Sample messages (must give 2 examples carriers will see):
   - `Your Milton Alumni verification code is: 123456. It expires in 5 minutes. Do not share this code.`
   - `Your Milton Alumni verification code is: 987654. It expires in 5 minutes. Do not share this code.`
5. Opt-in workflow: "Users enter their phone number during account signup in the Milton Nation app, agree to terms of service, and request a verification code."
6. Opt-out: "Users can delete their account at any time via the in-app Settings → Delete Account flow, which removes their phone number from the system."
7. Help message: "Reply HELP for assistance, STOP to unsubscribe."
8. Cost: ~$15/month for this campaign type
9. Submit → instant approval if brand is verified

### Step 3 — Associate the campaign with your Twilio phone number (~1 min)

1. Console → Phone Numbers → your sending number → Messaging tab → set Messaging Service / Campaign to your new campaign
2. Save

### Step 4 — Retry SMS smoke test

Repeat Phase 0.4 — SMS should now actually deliver.

---

# PHASE 2 — Dress Rehearsal (2–3 days, mostly passive)

Once SMS works:

## 2.1 — Sign up your second phone as a real new alumni (10 min active)

1. On your second phone, install TestFlight Milton (open the invite email)
2. Open the app → tap **"Don't have an account? Register"** (bottom of login)
3. Fill in:
   - Full name (use your real name or a clearly-test name like "Test Alumni")
   - Username (e.g., `test_alumni`)
   - Email (any email you can receive at)
   - Phone (the second phone's real number)
   - Password (set anything strong; you'll need to remember it)
   - Sobriety date (any past date)
   - Discharge date (any past date)
   - Recovery program (pick one)
4. Submit → "Application submitted, awaiting admin approval"
5. You should receive the **welcome email** at the email you provided (verify it looks good)

## 2.2 — Approve from your admin phone (5 min)

1. On your primary phone, log into TestFlight as admin:
   - Email: `admin@miltonrecovery.com`
   - Password: `Milton2026!`
   - Phone OTP comes to (929) 617-2795
2. You should get a push notification: "New Member Request"
3. Open admin dashboard → Pending Users → tap your test signup
4. Approve → assign Florida facility
5. Second phone receives push: "You're Approved!"

## 2.3 — Use the app as a real consumer for 24-48 hours (passive)

On the second phone, exercise:
- Cold login the next morning (token persistence)
- Create a post in each category
- Comment + like
- Open "I'm Struggling" → verify FL/OH numbers dial
- Open Meetings tab → verify real meetings show
- Push notifications wake up the app from background
- Logout / Login again
- Photo upload from real photo library

Open `launch-kit/TESTFLIGHT-QA-BUILD-10.md` and walk it.

## 2.4 — Document anything broken

Open a text file or Notes. Write down anything that:
- Crashes
- Looks wrong
- Doesn't work as expected
- Looks off-brand
- Feels slow

Send the list to me. I'll cut Build 11 with fixes if needed.

---

# PHASE 3 — Pre-Submission Code Updates (varies)

Do whatever fixes came from Phase 2.4.

## 3.1 — Apply branded welcome email if you approved it in Phase 0.1

I update `send-welcome-email/index.ts` + redeploy. ~5 min, no app rebuild.

## 3.2 — Update launch-kit App Review notes

`launch-kit/SUBMIT-BUILD-10.md` currently says "Password: leave blank" — wrong. I fix it to `Milton2026!` so the Apple reviewer can actually log in.

## 3.3 — Bump build number if any code changed

- If Build 10 is still good (no code changes from dress rehearsal): keep Build 10
- If anything changed: bump to Build 11 in Xcode (CURRENT_PROJECT_VERSION)

## 3.4 — Verify build compiles

```bash
xcodebuild test \
  -project "Milton Nation Alumni App.xcodeproj" \
  -scheme "Milton Nation Alumni App" \
  -destination "platform=iOS Simulator,name=iPhone 16e"
```

Should report all tests passing. Commit any changes.

---

# PHASE 4 — Apple Submission (30 min active + 24-48h Apple wait)

## 4.1 — Flip DEMO_BYPASS back to true (1 min, I do via Chrome)

Required so Apple's reviewer can log in as alexdemo with OTP `000000`.

## 4.2 — Re-seed minimal demo content for the reviewer (5 min, I do via SQL)

Restore the demo experience so when the reviewer logs in as `appreviewer@miltonrecovery.com` they see:
- 2-3 sample community posts authored by alexdemo (clean wholesome content, not "test test test")
- A few sample comments from other demo users
- The 2 meetings already in the meetings table (kept)
- 1 user badge already earned by alexdemo (kept)
- alexdemo's care team assignment to danacase + drnova

## 4.3 — Archive in Xcode (10 min)

1. Open Xcode → top toolbar device picker → **"Any iOS Device (arm64)"**
2. Menu: **Product → Clean Build Folder** (⇧⌘K)
3. Menu: **Product → Archive** — wait ~3-5 min
4. Organizer window auto-opens when done
5. Select the new archive → **Distribute App** → **App Store Connect** → **Upload**
6. Signing: **Automatically manage signing** → Next
7. Click **Upload** → wait for "Upload Successful" toast (~2 min)
8. Email arrives ~15-30 min later: "Your build has completed processing"

## 4.4 — Fill the ASC review form (15 min)

URL: `https://appstoreconnect.apple.com` → My Apps → Milton → App Store tab → Prepare for Submission

1. Click **+ Build** → select your just-uploaded build
2. **Sign-In Required**: ☑ Yes
3. **Demo Account**:
   - Username: `appreviewer@miltonrecovery.com`
   - Password: `Milton2026!`
4. **Notes for Reviewer** — paste from `launch-kit/SUBMIT-BUILD-10.md`, but update demo credentials:
   - Email: `appreviewer@miltonrecovery.com`
   - Password: `Milton2026!`
   - OTP screen: enter `000000` (gated by DEMO_BYPASS_ENABLED on backend)
5. **Contact Information**:
   - First name: Ezra
   - Last name: Barishansky
   - Phone: (201) 747-7727
   - Email: media@miltonjefferson.com
6. **Version Release**: ☑ **Manually release this version** (critical — lets you flip bypass off + smoke-test before going public)
7. Scan left sidebar for red dots — fix anything required (App Privacy questionnaire, Age Rating, Pricing)

## 4.5 — Submit for Review (1 click)

Click **Add for Review** → **Submit for Review**

Expected review time: **24–48 hours**.

## 4.6 — While waiting for Apple

- Twilio BAA process running in parallel (should land 5-10 days from your send date)
- Continue dogfooding TestFlight builds
- Don't push more builds during review unless something is broken

---

# PHASE 5 — Apple Approves (don't release yet — manual release)

You get an email: "Your app has been approved." The app is in "Pending Developer Release" state in App Store Connect — visible to no public users yet.

## 5.1 — Confirm Twilio BAA is signed before going public

If signed → continue.
If not signed yet → **STOP**. Don't release. Wait until BAA is in hand. You can leave the approved build sitting in "Pending Developer Release" indefinitely.

## 5.2 — Flip DEMO_BYPASS_ENABLED to false (1 min, I do via Chrome)

This kills the demo bypass so it can't be used by anyone who finds the credentials in your launch-kit docs.

## 5.3 — Real-phone production smoke test (10 min)

1. Build 10 is approved but not yet released. You can still install it via TestFlight on a fresh device.
2. Use a friend's phone or a brand-new phone you haven't tested before
3. Sign up as a brand-new alumni: real phone, real OTP from Twilio, real welcome email
4. Approve via admin on your phone
5. Confirm everything works end-to-end one more time
6. If anything breaks, flip DEMO_BYPASS back to true and roll back

## 5.4 — Click Release in App Store Connect

App Store Connect → My Apps → Milton → version row → **Release This Version**

App goes live on the App Store within ~2 hours (sometimes faster, occasionally 24h).

---

# PHASE 6 — Day 1 of Public (passive monitoring)

For the first 48 hours after release, watch:

## 6.1 — Supabase Auth → Users tab

Every new signup appears as a new row. Approve quickly from admin.

## 6.2 — Supabase Edge Function logs

Especially `send-sms-otp`, `verify-sms-otp`, `flag-content`. Watch for errors.

## 6.3 — App Store Connect → Sales and Trends

Download numbers. Reviews. App Store reviews.

## 6.4 — Email inbox

`media@miltonjefferson.com` — users may write in for support.

## 6.5 — Twilio Messaging logs

Confirm SMS is being delivered. Watch for failed deliveries (carrier rejections, opt-outs).

## 6.6 — Real-time crisis flags

If anyone posts crisis content, `flag-content` Edge Function pushes to admins. **You need to respond quickly.** Have your phone on you.

---

# Critical Path Summary

| Phase | Time | Blocker for |
|---|---|---|
| 0 (today) | ~60 min active | Everything else |
| 1 (fix SMS) | 1-3 days (A2P approval) | Dress rehearsal |
| 2 (dress rehearsal) | 2-3 days | Apple submission |
| 3 (code updates) | 30 min | Apple submission |
| 4 (Apple submission) | 30 min you + 24-48h Apple | Public release |
| 5 (approval) | 10 min | Public release |
| 6 (monitoring) | passive | — |

**Total realistic timeline from today to public release: 10-14 days.**

The two slowest items run in parallel:
- Twilio BAA: 1-2 weeks
- Apple Review: 1-2 days (with possible 1-2 day rejection-fix-resubmit cycle)

You'll be waiting on Twilio after Apple already approves. Plan for that.

---

# What Could Still Block Us

| Risk | Mitigation |
|---|---|
| Twilio BAA takes longer than 2 weeks | Have BAA conversation by phone, escalate via Twilio account manager if assigned |
| A2P 10DLC brand rejection | Their automated review is fast; if rejected, the rejection email tells you what to fix |
| Apple rejects Build 10 | See `launch-kit/07-rejection-recovery-playbook.md`; usually 1-2 day fix cycle |
| Dress rehearsal finds a critical bug | Build 11, retest, resubmit |
| Real user reports crisis content that nobody catches | Need someone on-call for flag-content alerts |

---

# What I Need From You RIGHT NOW

In order of priority:
1. **Send the BAA email** (Phase 0.2) — runs in background for 1-2 weeks, the longer you delay this the more it delays launch
2. **Log into Twilio** (Phase 0.3) — let me diagnose A2P 10DLC status
3. **Approve or reject the branded welcome email** (Phase 0.1) — quick yes/no
4. **Retry SMS smoke test** (Phase 0.4) — tell me what happens

Tell me when each one is done. I'll take it from there.
