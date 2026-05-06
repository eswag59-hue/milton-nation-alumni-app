# A2P 10DLC Campaign — Text to Paste

For Twilio Console → A2P 10DLC → Create Campaign. Each field is **TCR-approval-optimized** — these phrasings have a high success rate for healthcare/2FA campaigns.

---

## Campaign basics

| Field | Value |
|---|---|
| **Brand** | (the one you submitted earlier — Milton Health Group LLC) |
| **Use Case** | `Account Notifications` (preferred) OR `2FA` if listed separately |
| **Vertical** | `Healthcare` |
| **Campaign Description** | `One-time passcodes (OTP) sent to verified alumni of Milton Recovery Centers when they sign in to the Milton Nation iOS app, plus occasional invite messages from staff to new alumni post-discharge.` |
| **Number of phone numbers** | 1 (just your existing Twilio number) |
| **Embedded Links?** | Yes (only the invite SMS contains a link to the App Store / app onboarding) |
| **Embedded Phone Numbers?** | No |
| **Age-Gated Content?** | No |
| **Direct Lending?** | No |
| **Affiliate Marketing?** | No |

---

## Sample Messages (paste these exactly — TCR loves these formats)

### Sample 1 — OTP login (primary use case)
```
Milton Nation: Your verification code is 123456. Code expires in 10 minutes. Reply STOP to opt out, HELP for help.
```

### Sample 2 — Welcome / invite (admin-initiated)
```
Milton Nation: You're invited to join the Milton Recovery Centers alumni community app. Tap to set up your account: https://miltonrecovery.com/app. Reply STOP to opt out, HELP for help.
```

> **TCR notes**:
> - Each message includes the **brand name** ("Milton Nation") at the start — required.
> - Each message includes **STOP / HELP** keywords — required by carriers.
> - Sample 1 has no link → highest delivery rate.
> - Sample 2 includes a domain link, not a shortener — no `bit.ly` or `t.co` (those auto-fail TCR).

---

## Opt-In Flow (carriers require explicit consent description)

### Opt-In Type
`Verbal` (admin enters phone) **OR** `App-based` (user signs up in iOS app)

Choose **App-based** if available — that matches our reality.

### Opt-In Description
```
Users opt in to receive SMS in one of two ways:

(1) During iOS app sign-up: a verified alumni of Milton Recovery Centers downloads the Milton Nation app from the App Store, enters their phone number on the registration screen, and explicitly consents to receive an SMS verification code by tapping "Send Code". A consent disclosure appears on screen above the phone input: "By tapping Send Code, you agree to receive SMS messages from Milton Nation, including verification codes and occasional account messages. Standard message and data rates may apply. Reply STOP to opt out at any time."

(2) Admin invite flow: a Milton Recovery Centers staff member, after obtaining verbal consent from an alumni at discharge, enters that alumni's phone number into our admin tool. The alumni receives an invite SMS with a link to download the app. The first time they open the app, they're shown the same consent disclosure before any further messages are sent.

All consent records are timestamped and logged in our backend audit_logs table for compliance.
```

### Opt-Out Description
```
Users can opt out at any time by replying STOP to any message from our number. Twilio's default Opt-Out Manager honors this automatically — once a user replies STOP, no further messages are sent to that number until they explicitly opt in again. Users may also delete their account in the iOS app, which removes their phone number from our database.
```

### Help Description
```
Users who reply HELP receive an automated response: "Milton Nation: For app support, email support@miltonrecovery.com or visit https://miltonrecovery.com/app-support. To opt out, reply STOP."
```

---

## Volume Estimate (TCR uses this to set throughput limits)

| Field | Value |
|---|---|
| **Average daily messages (per number)** | `100` (conservative — actual will be ~10/day during ramp) |
| **Peak daily messages** | `500` |
| **Number of subscribers** | `2000` (12-month projection) |

> Pick numbers that are **realistic but not too aggressive** — TCR can deny "high volume + low brand age" combos. 100/day for an OTP service with a Healthcare vertical is normal.

---

## After submission

1. **Cost**: ~$10 one-time campaign vetting fee, then ~$2/month per campaign + per-segment usage.
2. **Approval timeline**: 1–14 days. Healthcare vertical sometimes triggers extra review (3–7 days).
3. **If rejected**: TCR sends a rejection reason. Most common reasons + fixes:
   - "Sample messages don't match opt-in" → make sure samples mention nothing the opt-in didn't authorize
   - "Brand age too low" → wait, then resubmit
   - "Volume too high" → lower the volume estimate, resubmit
4. **Once approved**: link your Twilio phone number to the approved Campaign in Twilio Console → Messaging → Services. You're done.

---

## What to do RIGHT NOW vs LATER

Right now:
- Submit Campaign with the text above

While you wait (1-3 days):
- Phase 6 (App Store Connect listing) — independent track, do in parallel
- Phase 7 (Archive + Upload) — also independent

Once Campaign is Approved:
- No code changes needed. Twilio routes the SMS through the new Campaign automatically once you link the number.
