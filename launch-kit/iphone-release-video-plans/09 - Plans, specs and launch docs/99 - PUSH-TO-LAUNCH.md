# 🚀 PUSH TO LAUNCH — Master Action Plan
**Effective date:** 2026-05-19
**Realistic launch ETA:** ~10-14 days
**Owner:** Ezra Barishansky
**Status:** All vendor wait-times started; you and Claude executing in parallel

---

## Reference card — entity facts (DON'T MISTYPE THESE)

```
PARENT — MILTON HEALTH GROUP LLC
  Doc Number:  L23000380354
  EIN:         93-2880131
  Filed:       Florida (08/14/2023)
  HQ Address:  560 Sylvan Avenue, Suite 1000, Englewood Cliffs, NJ 07632
  CEO:         Bil "Dovi" Denciger — dovi@miltonhealthgroup.com — (845) 300-9415
  Co-Owner:    Michael Schwartz — michael@miltonhealthgroup.com — (917) 648-6394

FL SUB — MILTON RECOVERY LLC   (NOT "Milton Recovery Centers LLC")
  Doc Number:  L24000051515
  EIN:         99-1013461
  Address:     521 Northlake Blvd, North Palm Beach, FL 33408

OH SUB — MILTON JEFFERSON LLC   (NOT "Milton Jefferson Recovery LLC")
  Entity #:    5237478
  EIN:         [pending]
  Address:     [pending]

TWILIO ACCOUNT SID:  AC3ad114d4769975de61f426a49e52a2de
SUPABASE PROJECT:    hksxzuytcmqqwxmfjzdp
APP BUILD:           11
```

---

## YOUR ACTION QUEUE (in order, do them today)

### ✅ A1. Forward authorization letter to Bil + Michael — 5 min

1. Open Outlook → New Email
2. **To:** `dovi@miltonhealthgroup.com`
3. **CC:** `michael@miltonhealthgroup.com`
4. **Subject:** Quick signature needed — Twilio authorization for Milton Nation app
5. **Body:** (paste this)

> Hi Bil (cc Michael),
>
> We're in the final stretch of launching the Milton Nation alumni app, but Twilio's compliance team is blocking SMS service until they have a letter on file authorizing me to act on Milton Health Group's behalf for vendor contracts (specifically: their A2P 10DLC messaging registration and HIPAA Business Associate Agreement).
>
> Michael already signed an employment verification letter for me back in March — this is the companion authorization letter Twilio specifically needs.
>
> **Attached:** Draft letter on letterhead, ready for your signature. Should take ~2 minutes to sign and scan back.
>
> Without this letter, the app can't send the SMS verification codes alumni need to log in. So this is the one thing standing between us and launch.
>
> Sign and reply with the scanned PDF? Either of you can sign — Bil's signature is preferred but Michael's works too.
>
> Thanks,
> Ezra

6. **Attach:** the letter draft. Two paths:
   - **Easy path:** Paste content from `launch-kit/MHG-AUTHORIZATION-LETTER-DRAFT.md` into a Word doc with Michael's letterhead format (same one used on March 11 employment letter). Export to PDF. Attach.
   - **Lazy path:** Attach the markdown file as-is. Bil will know what to do.
7. Send.

### ✅ A2. Email tech team about Privacy + Terms page fixes — 3 min

The live pages have 4 issues. They need to fix before Apple review.

1. Open Outlook → New Email
2. **To:** [your tech team email]
3. **Subject:** Quick fixes needed on Milton Nation Privacy + Terms pages (App Store submission blocker)
4. **Body:** (paste this)

> Hey team,
>
> The pages you put up at miltonrecovery.com/milton-nation-privacy and /app-terms-of-use are LIVE and look great — thanks for the fast turnaround. Apple Reviewer reads these during app review, so I need 4 small fixes before submission:
>
> **On `/milton-nation-privacy`:**
> 1. The effective date is truncated — currently shows "Effective: May 18, **202**" — should be "May 18, **2026**"
> 2. The "Privacy Officer Email" currently shows `media@miltonjefferson.com` — this isn't a real inbox. Replace all 3 instances with `media@miltonhealthgroup.com`
>
> **On `/app-terms-of-use`:**
> 3. The contact email currently shows `ezra@miltonrecovery.com` — this isn't a real inbox. Replace all 4 instances with `ebarish@miltonhealthgroup.com`
>
> **Both pages — please verify:**
> 4. All emails are real, monitored inboxes (App Store Reviewer may email these and bouncing = rejection)
>
> Can you push these updates by EOD tomorrow? Even though the content is solid, even one wrong email could fail App Store review.
>
> Thanks,
> Ezra

5. Send.

### ✅ A3. Text Bil for the OH EIN — 30 sec

If you have Bil's mobile (he's at (845) 300-9415), text him:

> Hey Bil — also need the EIN for Milton Jefferson LLC (OH entity #5237478) for the same Twilio paperwork. Should be in our books or with the accountant. When you get a sec, just shoot it over. Thanks!

### ✅ A4. (Optional, can wait) — Twilio Sales call for BAA — 10 min

Call **1-877-486-9866** (Twilio Sales). Opening line:
> *"I'm a HIPAA-covered entity needing a BAA for SMS messaging. Account SID AC3ad114d4769975de61f426a49e52a2de. We're with Milton Health Group LLC — what plan tier do I need to have access to a BAA?"*

Take notes on:
- Is BAA available on current plan? Y/N
- If upgrade needed: which plan + monthly cost
- Sales rep name + email

Reply to me with what they say.

### (Deferred to Phase 5) — Twilio balance top-up

Skipping for now. Will handle as part of day-before-launch checklist when you're ready.

---

## CLAUDE'S ACTION QUEUE (running in parallel — no action needed from you)

| # | Task | Status |
|---|---|---|
| C1 | Look up Milton Jefferson LLC's operational address from miltonjefferson.com / Google | In progress |
| C2 | Draft Twilio support ticket (ready to file once letter is signed) | Ready |
| C3 | Save Sunbiz/OH SOS records as PDFs in `launch-kit/legal/` | In progress |
| C4 | Run full test suite on Build 11 (247 tests, 18 suites) | Queued |
| C5 | Re-validate content safety engine against clinical-approved phrases | Queued |
| C6 | Audit App Store Connect metadata spec → prep checklist | In progress |
| C7 | Code cleanup: remove any leftover `media@miltonjefferson.com` / `ezra@miltonrecovery.com` references | In progress |

---

## VENDOR WAIT TIMELINE (set expectations)

| Vendor | What we're waiting for | ETA |
|---|---|---|
| Bil/Michael | Sign + return authorization letter | 1-2 days |
| Twilio Privacy/Compliance | Approve Trust Hub re-submission with new auth letter | 1-3 days after letter |
| Twilio TCR | Approve resubmitted Campaign | 1-3 days after Trust Hub |
| Twilio Sales | BAA paperwork | 3-7 days |
| Tech team | Privacy + Terms email fixes | 1-2 days |
| Tech team | OH EIN (via Bil/accountant) | 1-3 days |

---

## PHASE-BY-PHASE TO LAUNCH

### 🟢 PHASE 1: Now → +3 days (vendor wait window)

You: forward emails (A1-A3), call Twilio Sales (A4), top up funds (A5).
Me: run tests, prep ticket, code cleanup.

### 🟢 PHASE 2: Letter signed → file Twilio ticket → +3 days more

Me: file the support ticket with new auth letter attached.
Twilio: approves Trust Hub + Brand + Campaign.

### 🟢 PHASE 3: SMS green → submit to Apple — 1 day work

You + 2 helpers: TestFlight dress rehearsal (~90 min).
Me: final regression test suite, content safety validation.
You: Xcode → Archive → Distribute → Upload Build 11 → click Submit for Review (~20 min).

### 🟢 PHASE 4: Apple review — 24-48 hours

Watch dashboard. Fix any rejections within 1-4 hours.

### 🟢 PHASE 5: Day-before-launch — 30 min, in this order

1. Supabase Dashboard → Billing → **Activate HIPAA add-on (~$1000/mo)**
2. Supabase → Edge Functions → `verify-sms-otp` → env → `DEMO_BYPASS_ENABLED: true → false → Save`
3. **Twilio: top up balance to $200** (https://1console.twilio.com/account/AC3ad114d4769975de61f426a49e52a2de/us1/billing → Add Funds) — covers ~50K OTPs. Optional: enable auto-recharge at $50 threshold.
4. Real phone smoke test: signup → OTP → welcome email → push notification
5. Delete test account
6. Confirm `content_flags` table empty

### 🟢 PHASE 6: LAUNCH DAY

1. App Store Connect → "Release This Version" → click
2. 1-4 hour propagation
3. Verify on a fresh iPhone (search "Milton Nation", download, run)
4. Alumni outreach (email blast, facility signage, family text chains)
5. Be reachable by phone

### 🟢 PHASE 7: First 48 hours — vigilance mode

- Every 30 min: `content_flags` HIGH-RISK entries → review within 1 hour, clinical outreach if needed
- Every hour: Supabase logs, App Store reviews, signup rate
- Every day: crash reports, SMS delivery rate (>95%), email delivery rate

---

## REALISTIC TIMELINE

| Day | Milestone |
|---|---|
| Today (Day 0) | Send letter to Bil. Email tech team. Call Twilio Sales. Top up Twilio. |
| Day 1-2 | Letter comes back signed. Tech team fixes Privacy/Terms emails. |
| Day 3 | I file Twilio support ticket. |
| Day 4-6 | Twilio Privacy approves Trust Hub → Brand resubmitted → Campaign resubmitted → SMS unblocked. |
| Day 6-7 | BAA signed. Run full test suite. TestFlight dress rehearsal. |
| Day 8 | Archive + Submit Build 11 to Apple. |
| Day 9-10 | Apple review. |
| Day 11 | Day-before flips. |
| Day 12 | 🚀 LAUNCH DAY |
| Day 13-14 | Vigilance mode. |

**= ~12-14 days to launch.**

The Twilio Campaign approval is the only critical-path item — everything else can happen in parallel.

---

## DECISIONS LOCKED IN

- ✅ Twilio account entity: **Milton Health Group LLC** (parent)
- ✅ BAA contracting party: **Milton Health Group LLC**
- ✅ Brand identity to clients: Milton Recovery (FL) or Milton Jefferson (OH), NEVER Health Group
- ✅ App "About" copy: small print "Operated by Milton Health Group LLC", big branding stays facility-specific
- ✅ Clinical sign-off: Done (verbal, no written record needed)
- ✅ Demo accounts: Stay fake (logins only, not real inboxes)
- ✅ Build target: Build 11
- ✅ Content safety engine: Locked, 6 categories, clinically approved

---

## OPEN OPTIONS

- 🔘 OH EIN (Milton Jefferson LLC) — pending from Bil/accountant. Workaround: if not provided in time, register only MHG + MRC on Twilio, add MJ later.
- 🔘 Apple submission timing — soon as Twilio is green
- 🔘 Twilio Plan B (vendor swap to Bandwidth/Plivo) — only if Twilio drags past Day 10
