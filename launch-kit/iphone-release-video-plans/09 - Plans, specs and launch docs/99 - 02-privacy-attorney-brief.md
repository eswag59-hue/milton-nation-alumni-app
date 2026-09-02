# Privacy Attorney Brief — Milton Nation Alumni App

Send this to your privacy / healthcare attorney **before** launching publicly. Most of it is a checklist they'll work through with you in a 60–90 min review meeting.

---

## What we need from you

A pre-launch privacy & HIPAA review covering:

1. ✅ Verify our Privacy Policy + Terms of Service comply with current HIPAA, CCPA/CPRA, and Apple App Store requirements.
2. ✅ Sign-off that our data flow doesn't trigger any unexpected disclosure obligations.
3. ✅ Recommendation on data retention + deletion windows.
4. ✅ Review of our HIPAA Risk Assessment document (we'll prepare a draft).
5. ✅ Confirm BAAs are in place with every vendor that handles PHI (list below).

---

## App overview

**Milton Nation Alumni** is a private, invite-only iOS app for verified alumni of Milton Recovery Centers (Florida + Ohio). Users are alumni of a substance use disorder treatment program, so the very fact of someone being a user is PHI under HIPAA.

### What the app does
- Sobriety tracking with milestone badges
- Private community feed (moderated, alumni-only)
- 1-on-1 chat with assigned care team (counselor / therapist / case manager)
- Meeting finder (AA, NA, SMART Recovery via public BMLT API)
- Crisis support shortcut
- Daily reflections + quotes

### What data we collect
| Data type | Why | PHI? |
|---|---|---|
| Phone number | Sign-in via SMS OTP | Yes |
| Email address | Account recovery, welcome email | Yes |
| Full name | Display in chat / posts | Yes |
| Username | Public display alias (max 20 chars) | Yes (when linked to other PHI) |
| Sobriety date | Streak tracking | Yes (highly sensitive) |
| Discharge date from treatment | Eligibility window | Yes |
| Recovery program type (IOP/PHP/etc.) | Filter content | Yes |
| Profile photo | Display | Yes |
| Community posts (text, image, video) | The product | Yes |
| Chat messages with care team | The product | Yes |
| Push device token | Notifications | Linked to user — treat as PHI |
| Coarse location | Optional, for nearby meetings only | No (not stored on backend) |
| Crash reports | Debugging | No PHI in payload |
| Analytics events | Usage tracking | No PHI in payload |

---

## Vendors that touch PHI

| Vendor | Role | BAA status | Action |
|---|---|---|---|
| **Supabase** (Postgres + Storage + Auth + Edge Functions + Realtime) | Primary data store + compute | ✅ Yes (Pro plan) | Confirm Pro tier still active |
| **Twilio** (SMS OTP) | Phone verification | ⏳ Requested (see launch-kit/01-twilio-baa-request.md) | Submit BAA request before launch |
| **Apple APNs** | Push notifications | N/A — Apple handles this under their iOS ToS | No action |
| **Resend** (transactional email) | Welcome emails post-approval | ❌ No BAA available | We never send PHI via email — verify with attorney that "Welcome to Milton Nation" is acceptable as a generic, non-PHI transactional message |
| **BMLT** (meeting finder) | Public meeting database | N/A — read-only public API, no user data sent | No action |
| **GitHub** | Source code hosting | N/A — no PHI stored in source | No action |

---

## Architecture summary (for the attorney)

- **All PHI lives in Supabase Postgres**, encrypted at rest, accessible only via Row-Level Security (RLS) policies that scope every query to the authenticated user.
- **All app→backend traffic is HTTPS/TLS 1.2+** with Apple's App Transport Security enforced.
- **No PHI in URL parameters**, query strings, server logs, or client-side analytics.
- **Audit trail**: every privileged action (admin views, exports, deletions) is recorded to `audit_logs` table with timestamp + actor.
- **Authentication**: phone OTP via Twilio + Supabase Auth + Keychain-stored JWT.
- **Device security**: jailbreak detection + Face ID/Touch ID + screenshot detection + automatic background blur.
- **Content moderation**: 257-keyword local scan + server-side escalation for high-risk content. Crisis content surfaces 988 / SAMHSA / care team directly.
- **Account deletion**: 30-day grace period, then permanent deletion of all personal data including Storage objects.
- **Multi-facility isolation**: Florida and Ohio data physically separated by RLS policies (Florida admins cannot read Ohio rows and vice versa).

---

## Data retention + deletion policy (proposed — please review)

| Record type | Retention | Deletion trigger |
|---|---|---|
| Active user account | Indefinite while active | User-initiated delete (30-day grace) OR 18 months of inactivity |
| Posts + comments | Indefinite while account active | Cascading delete on account deletion |
| Chat messages | Indefinite while account active | Cascading delete on account deletion |
| Audit logs | 7 years | Required for HIPAA — retention legally mandated |
| Crash reports | 90 days | Auto-purge via cron |
| Analytics events | 1 year | Auto-purge via cron |
| OTP challenges | 10 minutes (expires) | Auto-purge via cron |
| Storage objects (photos, videos) | Bound to parent record | Cascading delete |

---

## HIPAA Risk Assessment summary (for attorney to formalize)

### Threats considered
- Unauthorized access via stolen phone → mitigated by Face ID + Keychain + auto-logout
- Compromised admin account → mitigated by audit logs + role-based RLS + emergency revocation
- Network MITM → mitigated by TLS + cert pinning (TODO: confirm with attorney whether cert pinning is recommended for our threat model)
- Data exfiltration via screenshot → mitigated by screenshot detection + background blur
- Vendor breach (Supabase) → covered by BAA + their security posture (SOC 2 Type II)
- Reverse engineering of client → mitigated by minimal client-side secrets (anon key only); RLS enforces all data access server-side

### Outstanding items for attorney input
1. Should we implement TLS certificate pinning?
2. Are 7 years of audit log retention sufficient for SUD/recovery context?
3. Does the welcome email's generic content (no name, no diagnosis) require a BAA from Resend, or is it considered non-PHI transactional?
4. Do we need state-specific addenda (Florida + Ohio) to the privacy policy?
5. What's our breach notification plan + threshold?

---

## Documents we'll send you

- [ ] Current Privacy Policy (live at https://miltonrecovery.com/app-privacy-policy/)
- [ ] Current Terms of Service (live at https://miltonrecovery.com/app-terms-conditions/)
- [ ] App Privacy Nutrition Label answers (see launch-kit/04-app-privacy-questionnaire.md)
- [ ] Architecture & data flow diagram (see ARCHITECTURE.md in repo)
- [ ] Sample of every SMS / email body the app sends
- [ ] List of all RLS policies in our database
- [ ] Vendor BAAs (Supabase signed; Twilio in flight)

---

## Engagement scope (please quote)

- Pre-launch review meeting (60–90 min)
- Privacy Policy + ToS amendments based on review
- HIPAA Risk Assessment formalization (1-page summary signed by attorney)
- Quarterly check-in for first year post-launch

We're aiming to launch publicly within 30 days. Please let us know your availability for the pre-launch review.

Thanks,
**Ezra Barishansky**
Milton Health Group LLC
