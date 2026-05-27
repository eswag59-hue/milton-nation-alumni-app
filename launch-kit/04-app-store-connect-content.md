# App Store Connect — Every Field, Ready to Paste

Open https://appstoreconnect.apple.com → My Apps → Milton Nation Alumni → 1.0 Prepare for Submission. Walk top-to-bottom and paste these.

---

## App Information

| Field | Value |
|---|---|
| **Name** (visible on listing) | `Milton Nation Alumni` |
| **Subtitle** (30 char max) | `Recovery support for alumni` |
| **Primary Category** | `Health & Fitness` |
| **Secondary Category** (optional) | `Medical` |
| **Content Rights** | ☑ "Does not contain, show, or access third-party content" |
| **Bundle ID** | `milton-recovery-centers.Milton-Nation-Alumni-App` |
| **SKU** | `milton-alumni-001` |

---

## Age Rating (click "Edit")

| Question | Answer |
|---|---|
| Cartoon or Fantasy Violence | None |
| Realistic Violence | None |
| Sexual Content or Nudity | None |
| Profanity or Crude Humor | None |
| Alcohol, Tobacco, or Drug Use or References | **Frequent/Intense** (recovery context) |
| Mature/Suggestive Themes | None |
| Simulated Gambling | None |
| Horror/Fear Themes | None |
| Prolonged Graphic or Sadistic Realistic Violence | None |
| Graphic Sexual Content and Nudity | None |
| **Medical/Treatment Information** | **Frequent/Intense** (sobriety, recovery program data) |
| **Unrestricted Web Access** | No |
| Gambling and Contests | No |

**Result**: 17+

---

## URLs

| Field | Value |
|---|---|
| Privacy Policy URL | `https://miltonrecovery.com/app-privacy-policy/` |
| Terms of Use URL | `https://miltonrecovery.com/app-terms-conditions/` |
| Marketing URL (optional) | `https://miltonrecovery.com` |

---

## Pricing & Availability

| Field | Value |
|---|---|
| Price | `Free` |
| Availability | `All countries and regions` (or limit to United States if you want a soft launch) |

---

## Version 1.0 — Prepare for Submission

### Promotional Text (170 char)
```
Stay connected to your Milton Recovery community. Track sobriety, message your care team, share wins with peers, and find 24/7 support — wherever recovery takes you.
```

### Description (4000 char)
```
Milton Nation is the official alumni app for Milton Recovery Centers — a private, secure space designed to support your recovery journey long after treatment ends.

WHY MILTON NATION?

Recovery doesn't end at discharge. It's a daily practice, and the people who've walked the same path are often the ones who understand best. Milton Nation keeps you connected to the community, tools, and care team that helped you get here.

KEY FEATURES

• Sobriety Tracker — Mark your start date and watch your streak grow. Celebrate every milestone with badges, daily quotes, and reflections curated for your stage of recovery.

• Private Community Feed — Share wins, struggles, gratitude, and questions with fellow alumni in moderated, category-based posts. All content is screened to keep the space safe and supportive.

• Direct Care Team Chat — Message your assigned counselor, therapist, or case manager 1-on-1 in encrypted conversations. Send photos, voice notes, and check-ins — your care team is just a tap away.

• Meeting Finder — Discover thousands of nearby AA, NA, and SMART Recovery meetings using our integrated meeting database. Filter by day, time, format, and distance.

• Crisis Support — Tap "I'm Struggling" anytime to instantly access crisis lifelines, your care team's contact info, and a focused mode that locks the app to chat-only so you can get help without distraction.

• Daily Reflections — Start each day with a curated quote and reflection to ground your recovery practice.

• Earn Recognition — Earn badges for sobriety milestones, community engagement, and meeting attendance. Recovery is hard work — celebrate it.

DESIGNED FOR PRIVACY

Milton Nation is built with HIPAA-aware architecture from the ground up:
• End-to-end encrypted authentication with phone verification
• Screenshot detection and privacy blur when the app is backgrounded
• Face ID / Touch ID locks
• Server-side content moderation that never sees identifying data
• Automatic secure session timeouts

WHO IS THIS FOR?

Milton Nation is exclusively for verified alumni of Milton Recovery Centers in Florida and Ohio. Account creation requires admin approval to keep the community safe and authentic.

JOIN THE NATION

Recovery is stronger together. Download Milton Nation today and stay connected to the people, programs, and progress that brought you this far.

Need help? Tap "Support" inside the app or visit miltonrecovery.com/app-support.
```

### Keywords (100 char)
```
recovery,sobriety,alumni,milton,addiction,support,community,counseling,12 step,peer,sober,mental
```

### What's New in This Version (4000 char)
```
Welcome to Milton Nation 1.0 — the official alumni app for Milton Recovery Centers.

This first release includes everything you need to stay connected to your recovery community:

• Sobriety tracker with milestone badges
• Private, moderated community feed
• 1-on-1 chat with your assigned care team
• Daily reflections and quotes
• Meeting finder for AA, NA, and SMART Recovery
• "I'm Struggling" crisis support shortcut
• Encrypted, HIPAA-aware design

Thank you for being part of this. We've built this for you.
```

---

## App Review Information

### Sign-In Required
☑ Yes

### Demo Account
| Field | Value |
|---|---|
| User name | `+15550001234` |
| Password | leave blank |

### Notes
```
DEMO BYPASS — App Store Reviewer Instructions

To sign in:
1. Tap "Sign In" on the home screen.
2. Enter phone number: +1 (555) 000-1234
3. Tap "Send Code".
4. Enter 6-digit code: 000000
5. Tap "Verify".

This bypass is gated behind an environment variable (DEMO_BYPASS_ENABLED=true) on our backend, active only during App Review. It will be disabled within minutes of approval.

The demo account "Alex Demo" is pre-loaded with:
- Sample sobriety date (90 days ago)
- Approved alumni status (Florida facility)
- Assigned care team (Case Manager + Therapist)
- Sample posts in the community feed

The app is intended for verified alumni of Milton Recovery Centers (a substance use disorder treatment provider). All real users go through phone verification + admin approval. The demo bypass exists solely to allow App Review without involving a real recovery alumni's PHI.

Crisis content disclosure: The app includes a "I'm Struggling" feature that connects users to suicide prevention hotlines (988), SAMHSA, and care team contacts. Content moderation flags crisis language and surfaces support resources automatically. No content is autonomously blocked — only flagged for human review.
```

### Contact Information
| Field | Value |
|---|---|
| First name | `Ezra` |
| Last name | `Barishansky` |
| Phone | `<your real phone>` |
| Email | `media@miltonhealthgroup.com` |

### Notes for Reviewer (additional, beyond demo)
```
Milton Nation is the alumni app for Milton Recovery Centers (Florida + Ohio facilities). It supports recovery alumni with sobriety tracking, peer community posts, secure 1:1 chat with assigned care-team staff, meeting reminders, and crisis support.

Compliance posture:
• HIPAA-aware: PHI encrypted at rest (Supabase) and in transit (TLS 1.2+)
• Authentication via phone OTP (Twilio) + Supabase Auth + Keychain JWT
• Server-side content moderation with crisis escalation
• Audit logging for every privileged action
• 30-day account deletion grace period (in Settings → Delete Account)

Vendor BAAs: Supabase (signed), Twilio (in process). Resend handles welcome emails only — body contains no PHI.

If you have questions during review, please email media@miltonhealthgroup.com or call +1-844-406-4325 (Milton Recovery Centers main line).
```

---

## Version Release

| Field | Value |
|---|---|
| **Release Type** | ☑ "Manually release this version" |

This is critical — it lets you flip DEMO_BYPASS_ENABLED off + run a real-device smoke test before going public.

---

## Pre-submission checklist

Look for **red dots** in the left sidebar — those are required fields you missed. Common ones:

- [ ] Build attached (Phase 7 must be complete)
- [ ] Privacy Questionnaire (App Privacy section — see launch-kit/05-privacy-questionnaire.md)
- [ ] Age Rating set
- [ ] Screenshots uploaded (6.7" + 6.9" iPhone)
- [ ] Encryption export compliance (auto-passes because we set ITSAppUsesNonExemptEncryption=NO in xcconfig)

When all sections show green checkmarks → top-right **"Add for Review"** → confirm → **"Submit to App Review"**.
