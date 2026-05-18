# Milton Nation App Privacy Policy — Page Spec for Milton Tech Team

**Hand this entire document to your web team.**

## Background

The Milton Nation Alumni App needs its own privacy policy page on miltonrecovery.com. The existing `/privacy` page is a generic website privacy policy from April 2024 — it does not disclose app data collection, HIPAA posture, third-party processors, or any of the app-specific data flows that Apple App Store review and Twilio A2P 10DLC will check for.

**Without this page, the app submission will be rejected by Apple AND the Twilio campaign may be rejected again by TCR.**

This page sits separately from the existing `/privacy` page. The existing one stays as the website privacy policy.

---

## Where the page should live

**Primary URL (target):** `https://miltonrecovery.com/app-privacy`

**Acceptable alternates:**
- `https://miltonrecovery.com/mobile-privacy`
- `https://miltonrecovery.com/milton-nation-privacy`

After publishing, **the URL must return HTTP 200**:
```
curl -I https://miltonrecovery.com/app-privacy
```

Also: add a link from the existing `/privacy` page that points at the new one ("For our mobile app privacy practices, see [link]"), and link back to `/privacy` from the new page.

---

## Required structure — exact section list

### 1. Header
- Page title (H1): **"Milton Nation App Privacy Policy"**
- Effective date: **"Effective: May 18, 2026"** (or whatever date you publish)
- Subhead: *"This privacy policy applies to the Milton Nation Alumni iOS app. For our general website privacy practices, see [Website Privacy Policy](/privacy)."*

### 2. Who we are
> Milton Recovery Centers ("we," "us," "Milton") operates the Milton Nation Alumni App. Milton Recovery Centers is a covered entity under the Health Insurance Portability and Accountability Act (HIPAA). Our facilities are located in Florida and Ohio.
>
> **Contact for privacy questions:**
> - Privacy Officer: Ezra Barishansky
> - Email: <a href="mailto:ezra@miltonrecovery.com">ezra@miltonrecovery.com</a>
> - Phone: (844) 406-4325
> - Mail: Milton Recovery Centers, 521 Northlake Blvd, North Palm Beach, FL 33408

### 3. What data we collect

> **Account Information**
> - Full name, username, email address, phone number, profile photo (optional)
>
> **Recovery Context (Protected Health Information — PHI)**
> - Sobriety date, discharge date, recovery program (IOP/PHP/Detox/Residential/OP/Other), facility (Florida or Ohio), milestone achievements
>
> **User-Generated Content**
> - Community posts, comments, likes, direct chat messages with your care team, uploaded photos
>
> **Device & Usage Data**
> - Apple Push Notification Service (APNS) device token, iOS version, in-app analytics events (which screens you visit, which features you use), audit logs of privileged actions
>
> **SMS Verification Data**
> - The phone number you register and the timestamps of verification code requests (for rate limiting and fraud prevention). Verification codes themselves are stored only as one-way SHA-256 hashes and are deleted after 5 minutes or first use.

### 4. How we use the data

> - **Authenticate you** via email/password + SMS one-time code (two-factor authentication)
> - **Deliver the community experience** — show you posts, comments, meetings, and announcements relevant to your facility
> - **Match you with your care team** — assign case manager and therapist, enable secure 1:1 messaging
> - **Detect crisis content** — automated and human review of posts and messages flag indicators of self-harm, suicidal ideation, or substance use relapse, and escalate to your care team for outreach
> - **Improve the service** — aggregated analytics about feature usage and engagement (not tied to identifying information)
> - **Comply with legal obligations** — including HIPAA recordkeeping, breach notification, and lawful subpoenas

### 5. Third-party processors (and their compliance posture)

> | Vendor | What they process | HIPAA BAA |
> |---|---|---|
> | **Supabase** (Postgres database, authentication, edge functions, file storage) | All app data including PHI | ✅ Signed |
> | **Twilio** (SMS one-time verification codes) | Your phone number + the OTP code body | 🟡 Signed/In process (expected before public release) |
> | **Apple APNS** (push notifications) | Push notification body (does NOT contain PHI) | Apple Developer Agreement covers |
> | **Resend** (welcome email after signup) | Email address only; email body contains no PHI | Not required — no PHI flows |
>
> We do not sell your data. We do not share your data with advertising networks. We do not share your data with any third party for their independent marketing purposes.

### 6. Who can see your data within the app

> - **You** — full access to your own data
> - **Other alumni** — only your community-facing data (username, public posts, public comments) that you've chosen to share
> - **Your care team** — your sobriety status, content you've flagged, and 1:1 chat messages with them
> - **Milton admins** — facility-scoped data for moderation, content review, and account management
> - **Super admins** — cross-facility data for system administration
> - **Crisis escalation** — content flagged as crisis by automated detection is shared with admin team for safety response

### 7. SMS messaging program (REQUIRED FOR TCR — DO NOT REWORD)

Use this section verbatim (it's what The Campaign Registry expects to see):

> **Program name:** Milton Nation
>
> **Purpose:** Two-factor authentication. When you sign in to the Milton Nation iOS app, we send a six-digit verification code by SMS to the phone number on your account. This code is required as the second factor of authentication.
>
> **Message frequency:** One SMS per login attempt. Typically 1–10 messages per month per user.
>
> **Message and data rates:** Standard message and data rates may apply per your mobile carrier's plan.
>
> **Opt-out:** Reply <strong>STOP</strong> to any verification message to unsubscribe. Opting out disables your ability to log in until you re-enroll your phone number via in-app Settings → Phone Number.
>
> **Help:** Reply <strong>HELP</strong> to any verification message, or contact <a href="mailto:ezra@miltonrecovery.com">ezra@miltonrecovery.com</a>.

⚠️ **STOP and HELP must be visually bold** (use `<strong>` in HTML). TCR rejects without this.

### 8. Push notifications

> The app may send push notifications for: application status updates (received, approved), comments on your posts, post moderation decisions, care-team messages, milestone celebrations, and crisis escalation alerts (admin only).
>
> You can disable push notifications at any time in iOS Settings → Notifications → Milton Nation.

### 9. Eligibility and children

> The Milton Nation Alumni App is intended solely for verified alumni of Milton Recovery Centers who are at least 18 years of age. We do not knowingly collect personal information from anyone under 18. If we learn we have collected such information, we will delete it.

### 10. Data retention

> - **Active accounts:** We keep your data while your account is active
> - **Deleted accounts:** When you delete your account in Settings → Delete Account, your data is marked for deletion and retained for a 30-day grace period during which you can restore. After 30 days, your account is permanently deleted.
> - **Audit logs:** Retained for 7 years to comply with HIPAA recordkeeping requirements
> - **Anonymized analytics:** Aggregated and de-identified after 90 days

### 11. Your HIPAA + state-law rights

> Because Milton Recovery Centers is a HIPAA covered entity, you have the right to:
>
> - **Access** the PHI we hold about you
> - **Amend** PHI you believe is incorrect
> - **Restrict** certain uses or disclosures
> - **Receive an accounting** of disclosures we've made
> - **Request confidential communications** (e.g., through a different channel)
> - **Delete** your account and associated data (Settings → Delete Account)
> - **Be notified** of any breach affecting your PHI within 60 days of discovery
> - **File a complaint** with the U.S. Department of Health and Human Services Office for Civil Rights, or with the appropriate state agency, if you believe your privacy rights have been violated. Filing a complaint will not affect the treatment or services you receive.
>
> To exercise any of these rights, email <a href="mailto:ezra@miltonrecovery.com">ezra@miltonrecovery.com</a>.

### 12. Security

> We protect your data with:
> - **Encryption at rest** — all data is encrypted using AES-256 by our database provider (Supabase)
> - **Encryption in transit** — all communication between the app and our servers uses TLS 1.2 or higher
> - **Row-level security** — database access controls enforce that you can only read your own data plus content you've been granted access to
> - **Audit logging** — every privileged action (logins, admin actions, content moderation, emergency access) is logged for HIPAA recordkeeping
> - **Multi-factor authentication** — email/password plus SMS one-time code on every login
> - **Screenshot protection** — sensitive screens are blurred when the app is backgrounded; screenshots are flagged for audit

### 13. Crisis content monitoring

> The app uses automated content analysis to identify posts, comments, and messages that may indicate crisis (self-harm, suicidal ideation, relapse risk). Content flagged by this system is reviewed by Milton clinical staff and may trigger outreach from your assigned care team. By using the app, you consent to this monitoring as a condition of receiving support.
>
> If you are in immediate crisis, please call or text **988** (Suicide & Crisis Lifeline) or call **911**.

### 14. Cookies and tracking

> The mobile app does not use web cookies. The app stores a small set of authentication tokens locally on your device in the iOS Keychain (a hardware-encrypted store). These tokens are deleted when you log out or delete the app.

### 15. International users

> The Milton Nation Alumni App is intended for use within the United States. If you access the app from outside the US, your data may be transferred to and stored in the United States.

### 16. Changes to this Privacy Policy

> We may update this Privacy Policy occasionally. Material changes will be communicated in-app and by email at least 30 days before they take effect. Continued use of the app after changes constitutes acceptance.

### 17. Breach notification

> If we discover a breach of unsecured PHI, we will notify affected individuals within 60 days as required by HIPAA. If the breach affects 500 or more individuals, we will also notify the U.S. Department of Health and Human Services and prominent media outlets in the affected state.

### 18. Contact

> **Milton Recovery Centers**
> Email: <a href="mailto:ezra@miltonrecovery.com">ezra@miltonrecovery.com</a>
> Phone: (844) 406-4325 (24/7)
> Ohio: (740) 715-4673 (24/7)
> Mail: 521 Northlake Blvd, North Palm Beach, FL 33408
>
> For HIPAA complaints, you may also contact:
> U.S. Department of Health and Human Services
> Office for Civil Rights
> <a href="https://www.hhs.gov/ocr/">www.hhs.gov/ocr</a>

---

## Visual / formatting requirements

| Item | Requirement |
|---|---|
| **Page accessibility** | Public URL, no login required, no robots.txt block |
| **Mobile responsive** | Must render readable on phone |
| **SSL** | HTTPS required |
| **STOP / HELP** | Must be visually bold (`<strong>`) in Section 7 |
| **Cross-link** | Link to existing `/privacy` website policy + Terms page |
| **Branding** | Match existing miltonrecovery.com look |

---

## How to verify it's ready

```bash
# 1. URL resolves
curl -I https://miltonrecovery.com/app-privacy
# Expected: HTTP/2 200

# 2. All required keywords present
content=$(curl -s -L https://miltonrecovery.com/app-privacy)
for term in HIPAA Twilio Supabase Apple SMS PHI deletion 30-day "Milton Nation" Section ezra; do
  echo "$term: $(echo "$content" | grep -ic "$term")"
done

# 3. STOP / HELP are bold
curl -s https://miltonrecovery.com/app-privacy | grep -i "strong.*STOP\|STOP.*strong"
```

---

## When the page is live — tell Ezra (Claude)

Reply: **`app privacy live`**

Claude will then:
1. Update the Twilio campaign's Privacy Policy URL from `/privacy` → `/app-privacy`
2. Update the Twilio campaign's Terms URL from `/privacy` → `/terms` (once that's also live)
3. Update the App Store Connect privacy URL to the new page
4. Confirm with you that everything is pointing at the right place before submission

---

## Estimated effort for tech team

- Junior dev: **3-4 hours** (it's longer than the Terms page; lots of sections)
- Senior dev: **1.5-2 hours**
- Using a privacy policy template + customizing for app-specific sections: **2 hours**

Sections 3, 4, 5, 7, and 11 are the longest and most specific to this app. Copy them verbatim. The rest can be styled like the existing /privacy page for visual consistency.

---

## Why we're doing this — explicit

Without this page:
- 🚫 Apple App Store review will reject the submission (Guideline 5.1.1 — Data Use and Sharing)
- 🚫 Twilio TCR campaign may reject again on re-review
- 🚫 HIPAA Notice of Privacy Practices requirement is unfulfilled
- 🚫 Twilio BAA won't activate

Pairing this with the Terms page is the single highest-leverage thing on the launch list. Both pages live → 90% of launch friction disappears.
