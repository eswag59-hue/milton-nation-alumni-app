# Master Launch Plan — frozen 2026-06-08 ~7 PM ET

Pick this up tomorrow. Every section has step-by-step click-by-click instructions for what to do. Realistic launch date: **Thursday June 18 or Friday June 19, 2026**.

---

## What we know right now

| Layer | Status |
|---|---|
| Supabase backend | ✅ Working — schema, RLS, auth all verified |
| Twilio campaigns | ❌ Both FAILED — replied to Akash 6/8 asking for vetter notes, waiting |
| iOS Build 10 | ❌ Has a fundamental bug — DB has 0 posts and 0 device tokens EVER. Posts and push notifications never worked in production. |
| Source code | ✅ Looks correct on review — bug is somewhere we can't see without runtime logs |
| HIPAA risk memo | ✅ Drafted, awaiting healthcare counsel signature |
| T&C page update | 🟡 Sent to tech team 6/8, awaiting |

---

## STAGE 0 — Diagnose the iOS bug (PICK BACK UP HERE)

We can't ship Build 11 to Apple until posts and push notifications actually work. Two diagnostic paths — Path A is faster.

### PATH A — Mac Console diagnosis (10 minutes)

1. Plug iPhone (with Build 10) into Mac via cable
2. iPhone: tap **Trust This Computer** if prompted
3. Mac: open **Console.app** (Cmd+Space → type "Console")
4. Console left sidebar → click your iPhone's name under "Devices"
5. Top right filter → type `Milton`
6. On iPhone: open Milton Nation → sign in (`appreviewer@miltonrecovery.com` / `Milton2026!` / OTP `000000`)
7. On iPhone: try to create any post → "Couldn't post" error
8. In Console: scroll to time of post attempt, look for error/Error/red text
9. Screenshot relevant rows → send to Claude
10. Claude diagnoses + fixes the bug in source

### PATH B — Rebuild Build 11 + reship (45–60 min, mostly waiting)

Only do this if Path A doesn't surface an error.

1. Open Xcode → Milton Nation project
2. Top bar → select scheme "Milton Nation Alumni App" + destination "Any iOS Device (arm64)"
3. Menu → **Product → Archive** (5–10 min compile)
4. Organizer opens → select latest archive
5. Right side → **Distribute App** → choose "App Store Connect" → Next
6. Choose "Upload" → Next → accept defaults → Upload
7. Wait 10–15 min for Apple processing email
8. Open TestFlight on both phones → install Build 11
9. Re-test post creation
10. If works: great, move to Stage 2. If broken: back to Path A.

---

## STAGE 1 — Fix the bug + ship Build 11

Once Stage 0 has surfaced the bug:

1. Claude patches the source code
2. You commit + push (Claude drives via Bash)
3. You: Xcode → Archive → Upload to TestFlight (same steps as Path B above)
4. Install Build 11 on both phones
5. Verify: create a post → it appears in feed AND in Supabase DB

**Time:** 1–2 hours from bug identification to Build 11 on phone.

---

## STAGE 2 — Verify push notifications work

Once Build 11 is on both phones with post creation working:

1. Primary phone: sign in as Alex Demo (`appreviewer@miltonrecovery.com` / `Milton2026!` / OTP `000000`)
2. iOS prompt → tap **Allow notifications**
3. Confirm in iPhone Settings → Notifications → Milton Nation → **Allow Notifications: ON**
4. Second phone: sign in as FL admin (`admin@miltonrecovery.com` / `Milton2026!` / OTP `000000`)
5. Primary phone: create a post `Hello world`
6. Background the Milton Nation app (swipe up)
7. Second phone (admin): find that post in feed → add a comment `nice post`
8. Primary phone: push notification banner should appear within 10 sec

If ✅ → push works. Move on.
If ❌ → Claude redeploys admin function, pulls Edge Function logs, debugs.

---

## STAGE 3 — Twilio campaigns (parallel with Stages 1–2)

### When Akash replies with vetter notes (expected Tue 6/9 or Wed 6/10):

1. Forward email to Claude (screenshot or paste)
2. Claude reads vetter notes, identifies specific fixes needed
3. Possible fixes Claude makes:
   - Update message_flow text
   - Update OTP message body to match samples better
   - Request tech team add more content to privacy/T&C pages
4. Claude redeploys admin function, runs delete+recreate on both campaigns via API
5. $30 in vetting fees ($15 × 2)
6. Wait 1–3 business days for TCR re-vetting

### What to do if Akash doesn't reply by Wed 6/10:

1. Reply to ticket asking for status update
2. Ask for escalation to a Trust & Safety lead by name
3. Consider switching SMS vendor (Sinch, AWS End User Messaging) — Claude has a backup plan

---

## STAGE 4 — Tech team finishes T&C update

You already emailed them 6/8. Expected: 1–3 days for them to push it live.

When they confirm:
1. Open `https://miltonrecovery.com/app-terms-of-use/` in browser
2. Cmd+F search for "Reply STOP" — should find it
3. Tell Claude "T&C live" → Claude verifies via curl
4. If we already resubmitted Twilio campaigns by then, this gives us a defensive update for any 30882 re-rejection

---

## STAGE 5 — Full dry-run deep test (only after Build 11 + Twilio approved)

Open `launch-kit/DRY-RUN-DEEP-TEST.md` on phone. Tap through all 15 surfaces:

| Surface | What it tests | Special notes |
|---|---|---|
| 1 | Auth + onboarding | Skip 1A/C/F/G/H/I until Twilio approves |
| 2 | Profile | |
| 3 | Community feed + content safety | All 6 categories, negation, time-immediacy |
| 4 | Chat with care team | |
| 5 | Meetings | |
| 6 | Crisis flow | All 6 dial numbers |
| 7 | Push notifications | Already verified in Stage 2 |
| 8 | Admin panel | Facility isolation critical |
| 9 | Super admin | |
| 10 | Care team | |
| 11 | Settings | Skip 11B until Twilio approves |
| 12 | Edge cases + offline + screenshot protection | |
| 13 | Accessibility + dark mode | |
| 14 | Performance | |
| 16 | Audit logs in Supabase | |
| 17 | TestFlight install | |

**Log every bug.** Bring list to Claude. Triage Showstopper / P1 / Polish.

**Time:** 2–3 hours

---

## STAGE 6 — Test all 4 SMS surfaces (after Twilio approves)

Once both campaigns show `VERIFIED` / `APPROVED` and senders are attached:

1. **Signup OTP** — fresh signup with your real phone number → SMS arrives → enter code
2. **Login OTP** — sign out, sign back in with your real phone → SMS arrives
3. **Admin invite SMS** — admin tries to invite a phone number → SMS arrives at that phone
4. **Phone number change** — Settings → change phone number → SMS arrives at new number

If any fail → Claude pulls Edge Function logs.

**Time:** 30 minutes

---

## STAGE 7 — Healthcare counsel signs HIPAA risk memo

1. Open `launch-kit/HIPAA-RISK-MEMO-TWILIO.md` on your computer
2. Convert to PDF (File → Export → PDF in any markdown viewer, or use `pandoc`)
3. Email to your healthcare counsel: "Quick review and sign — vendor risk memo for app launch. ~10 min read. Need signed copy by [date]."
4. Get signed PDF back
5. Save to `launch-kit/legal/HIPAA-RISK-MEMO-TWILIO-SIGNED.pdf`
6. Cost: ~$500 if your counsel charges hourly

**Can be done in parallel with anything else.**

---

## STAGE 8 — Apple App Store submission

Only after: Build 11 is solid + Twilio approved + all 4 SMS surfaces work + 0 Showstoppers from dry-run.

### Step 8.1 — Archive Build 11 (10 min)

1. Open Xcode → Milton Nation Alumni App.xcodeproj
2. Top bar: scheme "Milton Nation Alumni App" + destination "Any iOS Device (arm64)" — NOT simulator
3. Product → Archive
4. Wait ~5 min for build
5. Organizer opens automatically

### Step 8.2 — Upload to App Store Connect (5 min)

1. In Organizer → select the new archive
2. Right side → **Distribute App**
3. Choose **App Store Connect** → Next
4. Choose **Upload** → Next → accept defaults → Next
5. Click **Upload**
6. Wait 5–10 min for Apple processing email

### Step 8.3 — Update reviewer notes in ASC (5 min)

1. Go to `https://appstoreconnect.apple.com/` → Milton Nation → Build 11
2. **Notes for Reviewer** → paste from `launch-kit/SUBMIT-BUILD-10.md` lines 78–134
3. **Demo Account** → User: `appreviewer@miltonrecovery.com` / Password: `Milton2026!`
4. **Sign-In Required** → Yes
5. **Version Release** → Manually release this version (NOT automatic)
6. Scroll to bottom → **Submit for Review**

### Step 8.4 — Wait for Apple (24–48 hrs)

Apple emails when status changes.
- ✅ "Pending Developer Release" → Stage 9
- ❌ "Metadata Rejected" / "Binary Rejected" → fix per their feedback, resubmit. Usually 1-day turnaround.

---

## STAGE 9 — Launch day flips

When Apple says "Pending Developer Release," do these in this exact order in 30 minutes:

### Step 9.1 — Activate Supabase HIPAA add-on (~$1k/mo, 5 min)

1. Open `https://supabase.com/dashboard/project/hksxzuytcmqqwxmfjzdp/settings/billing`
2. Find "HIPAA Add-on" section
3. Click **Enable** / **Activate**
4. Confirm payment ($1k/mo recurring)
5. Verify under Project Settings → Compliance

### Step 9.2 — Top up Twilio balance to $200 (5 min)

1. Open `https://console.twilio.com/billing`
2. Add Funds → enter $200
3. Confirm payment
4. (Optional) Auto-recharge floor $50

### Step 9.3 — Flip `DEMO_BYPASS_ENABLED` → false (2 min)

Critical — kills demo bypass so real users must use real SMS.

Option A (manual): `https://supabase.com/dashboard/project/hksxzuytcmqqwxmfjzdp/functions/secrets` → edit DEMO_BYPASS_ENABLED → change from `true` to `false` → save.

Option B (Claude): tell Claude "flip demo bypass" — Claude runs the CLI command.

### Step 9.4 — Smoke test on a clean phone (10 min)

On a phone that hasn't installed Milton Nation before:
1. App Store → search "Milton Nation" → install
2. Open → sign up with a real phone number
3. OTP must arrive via real SMS (no bypass)
4. Complete profile → land in feed
5. Create a normal post → it appears
6. Trigger crisis post → resources sheet appears
7. Sign out, sign back in → another real OTP arrives

If any ❌ → STOP. Fix before releasing.

### Step 9.5 — Click "Release This Version" in ASC (10 sec)

1. App Store Connect → Milton Nation
2. Big blue button **Release This Version**
3. App goes live in App Store within 1–24 hours

---

## STAGE 10 — First 48 hours vigilance

### Every 30 min check (you):

1. Supabase Dashboard → `content_flags` table → any HIGH-risk rows unreviewed?
2. App Store Connect → Reviews → any 1-star complaints?
3. Twilio Console → Messaging Insights → SMS delivery rate >95%?

### Ask Claude when needed:

- Pull Edge Function error logs
- Query Supabase for unusual signup patterns
- Triage any reported bugs

### Triage bugs in real time

- Critical → Claude patches in hours, you redeploy
- Cosmetic → log for 1.1

---

## STAGE 11 — User onboarding rolls out (Mon 6/22 +)

### Step 11.1 — Tell MRC staff app is live

Send announcement to Bil, Michael, clinical staff: "Milton Nation app is live — start onboarding alumni."

### Step 11.2 — Staff invite alumni (rolling)

Each MRC counselor/admin:
1. Signs in to Milton Nation
2. Admin → Send Invite
3. Enter alumni phone number
4. SMS arrives at alumni
5. Alumni clicks App Store link → installs → signs up
6. Admin approves

### Step 11.3 — Care team starts engaging (rolling)

Case managers, therapists sign in, see assigned alumni, start chatting and responding to crises.

### Step 11.4 — Monitor growth + iterate

Weekly: review signup count, retention, content safety hits, support tickets. Plan 1.1 features.

---

## What we're waiting on (the queue, as of right now)

| # | Waiting on | Expected | Unblocks |
|---|---|---|---|
| 1 | Your Path A diagnosis | Tomorrow 6/9 | Stage 1 (fix bug) |
| 2 | Akash's vetter notes (Twilio) | Tue 6/9 or Wed 6/10 | Stage 3 (campaign fixes) |
| 3 | Tech team T&C update | This week | Stage 4 |
| 4 | TCR re-vetting (after Stage 3 resubmit) | 1–3 biz days | Stage 6 |
| 5 | Apple review (after Stage 8 submit) | 24–48 hr | Stage 9 |
| 6 | Healthcare counsel signature | Anytime this week | Closes Stage 7 |

---

## Realistic timeline

| Date | What happens | What's done |
|---|---|---|
| Tue 6/9 morning | You: Path A diagnosis (10 min) | We see the actual iOS error |
| Tue 6/9 daytime | Claude: source patch + you: Build 11 archive + ship | Build 11 on TestFlight |
| Tue 6/9 evening | You: Push notification verification (Stage 2) | Push confirmed working OR new bug found |
| Tue–Wed 6/10 | Akash replies with vetter notes; Claude fixes Twilio campaigns | Twilio re-submitted |
| Thu–Fri 6/12 | TCR re-vets (1–3 biz days) | Campaigns approved (or iterate) |
| Mon 6/15 | You: full dry-run deep test (Stage 5) | All bugs logged |
| Tue 6/16 | Claude: fixes Showstoppers; You: 4 SMS surfaces test | Build 11 + SMS verified |
| Tue 6/16 evening | You: archive Build 11 final + ASC submit | Apple review starts |
| Thu 6/18 | Apple approves | Pending Developer Release |
| Thu 6/18 evening | You: launch day flips + click Release | App goes live |
| Fri 6/19 | App live in App Store (Apple cache propagates) | Public availability |
| Sat–Sun 6/20–21 | First 48 hr vigilance | |
| Mon 6/22 | MRC staff start sending invite SMS to alumni | Patients begin onboarding |

**Patient/staff usage start: Monday June 22 (rolling thereafter).**

---

## Decisions already made (not re-litigating)

- Twilio HIPAA BAA → SKIP. Brand-anonymous OTPs mean no PHI flows through Twilio. Documented in HIPAA risk memo.
- Supabase HIPAA add-on → ACTIVATE on launch day ($1k/mo).
- DEMO_BYPASS_ENABLED → flip to false on launch day.
- Invite SMS → handled by second Marketing campaign (currently failed, awaiting re-vetting).

---

## Files you might need

| File | What it is |
|---|---|
| `launch-kit/DRY-RUN-DEEP-TEST.md` | The 15-surface dry-run script for Stage 5 |
| `launch-kit/SUBMIT-BUILD-10.md` | Reviewer notes to paste into ASC at Stage 8.3 |
| `launch-kit/HIPAA-RISK-MEMO-TWILIO.md` | Memo for healthcare counsel (Stage 7) |
| `launch-kit/AKASH-REPLY-2026-06-08.md` | The reply you sent to Akash 6/8 |
| `launch-kit/TERMS-OF-USE-SMS-PATCH.md` | What the tech team is adding to T&C page |
| `supabase/functions/twilio-campaign-admin/index.ts` | Source for the admin function Claude redeploys for Twilio API ops |

---

## When you come back

Just say: **"Let's pick up from Stage 0"** — Claude resumes wherever we left off.
