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

### Step 3: Demo account (paste exactly)
| Field | Value |
|---|---|
| User name | `appreviewer@miltonrecovery.com` |
| Password | `Milton2026!` |

### Step 4: Notes for Reviewer — paste this verbatim

```
APP STORE REVIEWER — Sign-In Instructions

The Milton Nation app uses TWO-FACTOR authentication:
  Step 1: Email + password
  Step 2: SMS one-time code (OTP)

To sign in as the demo alumni account:

1. Tap the email field. Enter: appreviewer@miltonrecovery.com
2. Tap the password field. Enter: Milton2026!
3. Tap "Login".
4. The app will display the 2FA verification screen.
5. Enter the 6-digit code: 000000
6. Tap "Verify".

You will land on the home screen as "Alex Demo" — a Florida-facility
alumni account with 90 days of sobriety, an assigned care team, and
sample badges.

The SMS OTP step is bypassed server-side for this demo account only.
This bypass is gated behind an environment variable
(DEMO_BYPASS_ENABLED=true) on our backend, active only during App
Review. It will be disabled within minutes of approval.

To exercise the safety/crisis features:
1. After login, tap "+" or the Community tab to create a post.
2. Type a phrase that includes "I want to end it all" or "I'm thinking
   about relapsing tonight" and tap Post.
3. The app will surface the Support Resources sheet with 988 Suicide &
   Crisis Lifeline, Crisis Text Line, SAMHSA, Milton Recovery Centers
   (FL + OH lines), and 911.
4. The post is routed to admin moderation (flaggedForCrisis status).

The app is intended for verified alumni of Milton Recovery Centers, a
substance use disorder treatment provider. All real users go through
phone verification + admin approval before gaining access. The demo
bypass exists solely to allow App Review without involving a real
recovery alumni's PHI.

Compliance posture:
- HIPAA-aware: PHI encrypted at rest (Supabase) and in transit (TLS 1.2+).
- Authentication via email/password + SMS OTP 2FA (Twilio).
- Server-side content moderation with crisis escalation.
- Audit logging for every privileged action.
- 30-day account deletion grace period (Settings → Delete Account).

Vendor BAAs: Supabase (signed), Twilio (in process; expected before
public release). Resend handles welcome emails only — body contains
no PHI.

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
