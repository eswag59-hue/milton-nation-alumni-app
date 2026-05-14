# Submit Build 10 — Step-by-Step Checklist

Everything you need to ship Build 10 to Apple. Open this on one screen, App Store Connect on the other.

---

## ✅ Pre-Submission (already done in code)

- [x] Build 10 compiles + commits clean (a `08f22af`)
- [x] Real Milton FL + OH phone numbers wired into Support Resources
- [x] Edit-flow content moderation closed
- [x] Info.plist permissions audited (Guideline 5.1.1)
- [x] PrivacyInfo.xcprivacy in place
- [x] Analytics flush verified

---

## 🟡 Before clicking Archive — verify on Supabase Dashboard

URL: https://supabase.com/dashboard/project/hksxzuytcmqqwxmfjzdp

### 1. Edge Functions → Secrets
Open Project Settings → Edge Functions → **Secrets** and confirm:

- [ ] `DEMO_BYPASS_ENABLED` = `true`
- [ ] `TWILIO_ACCOUNT_SID` is set (non-empty)
- [ ] `TWILIO_AUTH_TOKEN` is set (non-empty)
- [ ] `TWILIO_PHONE_NUMBER` is set (your Twilio number)
- [ ] `RESEND_API_KEY` is set (for welcome emails)

### 2. Edge Functions → Deployed
Confirm all 6 functions show "Active":
- [ ] `send-sms-otp`
- [ ] `verify-sms-otp`
- [ ] `flag-content`
- [ ] `send-push-notification`
- [ ] `send-welcome-email`
- [ ] `send-invite-sms`

### 3. Demo Accounts → still exist
Authentication → Users — confirm 3 rows with `user_metadata.is_test_account = true` exist:
- [ ] Alumni demo account (the phone `+15550001234` user)
- [ ] Admin demo account
- [ ] Super admin demo account

---

## 📲 Archive + Upload (Xcode)

1. Open Xcode
2. Top bar device selector → **Any iOS Device (arm64)**
3. Menu: **Product → Archive**
4. Wait for archive to build (~3–5 min)
5. **Organizer window opens automatically** → select your new Build 10 archive
6. Click **Distribute App** → **App Store Connect** → **Upload**
7. Signing: **Automatically manage signing**
8. Click **Upload**
9. Wait 10–30 minutes for Apple to process the build (you get an email when ready)

---

## 🌐 App Store Connect — fill review form

URL: https://appstoreconnect.apple.com → My Apps → Milton

### Step 1: Select Build 10
- App Store tab → Prepare for Submission → **+ Build** → select Build 10

### Step 2: Sign-In Required
- ☑ Yes

### Step 3: Demo account
| Field | Value |
|---|---|
| User name | `+15550001234` |
| Password | (leave blank) |

### Step 4: Notes for Reviewer — paste this verbatim

```
DEMO BYPASS — App Store Reviewer Instructions

To sign in:
1. Tap "Sign In" on the home screen.
2. Enter phone number: +1 (555) 000-1234
3. Tap "Send Code".
4. Enter 6-digit code: 000000
5. Tap "Verify".

This bypass is gated behind an environment variable (DEMO_BYPASS_ENABLED=true)
on our backend, active only during App Review. It will be disabled within
minutes of approval.

The demo account is pre-loaded with:
- Sample sobriety date (90 days ago)
- Approved alumni status (Florida facility)
- Assigned care team (Case Manager + Therapist)
- Sample posts in the community feed
- Sample badges + milestones

To exercise the safety/crisis features:
1. Tap the "+" button to create a post.
2. Type a phrase that includes "I want to end it all" or "I'm thinking about
   relapsing tonight" and tap Post.
3. The app will surface the Support Resources sheet with 988, Crisis Text
   Line, SAMHSA, Milton Recovery Centers (FL + OH), and 911.
4. The post itself routes to admin review (flaggedForCrisis status).

The app is intended for verified alumni of Milton Recovery Centers (a
substance use disorder treatment provider). All real users go through phone
verification + admin approval. The demo bypass exists solely to allow App
Review without involving a real recovery alumni's PHI.

Compliance posture:
- HIPAA-aware: PHI encrypted at rest (Supabase) and in transit (TLS 1.2+).
- Authentication via phone OTP (Twilio) + Supabase Auth + Keychain JWT.
- Server-side content moderation with crisis escalation.
- Audit logging for every privileged action.
- 30-day account deletion grace period (Settings → Delete Account).

Vendor BAAs: Supabase (signed), Twilio (in process). Resend handles
welcome emails only — body contains no PHI.

If you have questions during review:
- Email: ezra@miltonrecovery.com
- Phone: (844) 406-4325 (Milton Recovery Centers main line)
```

### Step 5: Contact Information
| Field | Value |
|---|---|
| First name | `Ezra` |
| Last name | `Barishansky` |
| Phone | *(your real phone)* |
| Email | `ezra@miltonrecovery.com` |

### Step 6: Version Release
- ☑ **Manually release this version**
  *(Critical — lets you flip DEMO_BYPASS_ENABLED off + smoke-test before going public)*

### Step 7: Final check — scan for red dots in the sidebar
Look at the left sidebar in App Store Connect. Any field with a red dot is required.
Common ones to double-check:
- [ ] App Privacy questionnaire (already done per your earlier work)
- [ ] Age Rating (17+ recommended for recovery content)
- [ ] Pricing & Availability
- [ ] App Review Information (this page)

### Step 8: Submit
- Click **Add for Review** → **Submit for Review**
- Typical review time: 24–48 hours

---

## 🚀 After Apple approves — Day-of-Launch (DON'T release yet)

Because you chose "Manually release this version":

1. Supabase Dashboard → Edge Functions → Secrets
2. Set `DEMO_BYPASS_ENABLED` = `false`
3. Smoke-test on a real device with a real phone number (15-min flow):
   - Phone OTP works
   - Real Twilio SMS arrives
   - Login → Home → Community → Post → Logout
4. In App Store Connect → click **Release This Version**
5. Live on the App Store within 24h

---

## If Apple rejects

1. Open the rejection email
2. Read the specific guideline number cited
3. Cross-reference `launch-kit/07-rejection-recovery-playbook.md`
4. Fix in code → Build 11 → resubmit
5. Note: Don't argue. Fix and resubmit is always faster than appeals.

---

## TL;DR

| Step | Owner | Time |
|---|---|---|
| Verify Supabase secrets + functions | You | 5 min |
| Archive + upload in Xcode | You | 10 min |
| Fill review form in ASC | You | 15 min |
| Submit | You | 1 click |
| **Total** | | **~30 min** |

Then wait 24–48h for Apple.
