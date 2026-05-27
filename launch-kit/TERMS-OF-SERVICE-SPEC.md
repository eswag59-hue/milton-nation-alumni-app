# Terms of Service — Page Spec for Milton Recovery Centers Tech Team

**Hand this entire document to your web team.**

## Background

The Milton Nation Alumni App (iOS, currently in TestFlight, headed to App Store Connect) needs a Terms of Service page on **miltonrecovery.com** to satisfy two specific requirements:

1. **Twilio A2P 10DLC Campaign Registration** — The Campaign Registry (TCR) requires a publicly-reachable Terms URL when registering SMS senders for US carriers. Without it, every OTP SMS is silently rejected. *(We are currently using the Privacy URL as a placeholder; this is a known temporary fix.)*
2. **Apple App Store Review** — While not strictly required (the privacy URL alone usually passes), reviewers consider Terms a sign of legitimacy.

---

## Where the page should live

**Primary URL (target):** `https://miltonrecovery.com/terms`

**Acceptable alternates (any of these would work):**
- `https://miltonrecovery.com/terms-of-service`
- `https://miltonrecovery.com/terms-of-use`
- `https://miltonrecovery.com/legal/terms`

After publishing, **the URL must return HTTP 200** when fetched. Verify with:
```
curl -I https://miltonrecovery.com/terms
```

The Privacy page (already live at `/privacy`) should link to this new page in its footer, and the new Terms page should link back to `/privacy`.

---

## Required sections (in this order)

### 1. Header
- Page title: **"Terms of Service"** (H1)
- Effective date: e.g. **"Effective: May 18, 2026"** (just below title)
- Link back to homepage

### 2. Eligibility
> The Milton Nation Alumni App and this Site are intended solely for verified alumni of Milton Recovery Centers (Florida and Ohio facilities) who have completed or are currently enrolled in a treatment program. You must be at least 18 years of age. By creating an account, you represent that you meet these requirements.

### 3. Account Responsibilities
> You are responsible for maintaining the confidentiality of your account credentials (email, password, and the phone number you register for two-factor authentication). You must notify us immediately at media@miltonhealthgroup.com if you suspect any unauthorized access.

### 4. Acceptable Use
> You agree not to:
> - Post content that promotes substance use or relapse
> - Harass, threaten, or impersonate other users
> - Share another alumni's identifying information
> - Use the platform to solicit, sell, or advertise services
> - Attempt to bypass content moderation or security controls
> Violations may result in account suspension or termination.

### 5. Content Moderation and Crisis Detection
> User-generated content (posts, comments, chat messages) is subject to automated and human review. Content flagged as indicating crisis, self-harm, or substance-use relapse risk is escalated to Milton Recovery Centers staff and may trigger outreach from your care team. By using the platform, you consent to this monitoring.

### 6. SMS Messaging (REQUIRED FOR TCR — DO NOT OMIT)
This section is the one TCR specifically wants. Use this language verbatim, adjusting the phone numbers only:

> ### SMS Verification (Two-Factor Authentication)
>
> **Program name:** Milton Nation
>
> **Description:** When you sign in to the Milton Nation iOS app, we send a six-digit verification code by SMS to the phone number on your account. This code is required as the second factor of authentication.
>
> **Message frequency:** One SMS per login attempt. Typically 1-10 messages per month per user.
>
> **Message and data rates:** Standard message and data rates may apply, per your mobile carrier's plan.
>
> **Support:** For SMS-related help, contact <a href="mailto:media@miltonhealthgroup.com">media@miltonhealthgroup.com</a> or call **(844) 406-4325** (Florida) / **(740) 715-4673** (Ohio).
>
> **Opt-out:** You may opt out at any time by replying **STOP** to any verification message. Opting out will disable your ability to log in to the app until you re-enroll your phone number via the in-app Settings → Phone Number flow.
>
> **Help:** Reply **HELP** to any verification message for assistance, or contact <a href="mailto:media@miltonhealthgroup.com">media@miltonhealthgroup.com</a>.

⚠️ **Bold formatting matters.** TCR will reject if STOP and HELP are not visually emphasized. Use `<strong>STOP</strong>` and `<strong>HELP</strong>` in the HTML.

### 7. Push Notifications
> The app may send push notifications for: account approval status, new comments on your posts, post-moderation decisions, and care-team messages. You can disable these in iOS Settings → Notifications → Milton Nation.

### 8. Privacy & Data Handling
> Our handling of personal information, including Protected Health Information (PHI), is described in our <a href="/privacy">Privacy Policy</a>. By using the app, you consent to that handling.

### 9. Not a Medical Service / Crisis Disclaimer
> The Milton Nation Alumni App is a recovery-community support tool. It is **not** a substitute for professional medical care, mental health treatment, or emergency services. If you are in crisis, please call or text **988** (Suicide & Crisis Lifeline) or dial **911** for immediate emergencies.

### 10. HIPAA Notice
> Milton Recovery Centers is a covered entity under the Health Insurance Portability and Accountability Act (HIPAA). Limited Protected Health Information (PHI) that you provide in the app — such as sobriety dates, recovery program enrollment, and chat with your care team — is handled under our HIPAA Notice of Privacy Practices. Vendors who process your data (Supabase, Twilio) have signed Business Associate Agreements (BAAs) with Milton Recovery Centers.

### 11. Account Termination
> You may delete your account at any time via the in-app **Settings → Delete Account** flow. Deletion is permanent after a 30-day grace period during which you can restore. Milton Recovery Centers may suspend or terminate accounts for violations of these Terms or applicable law.

### 12. Limitation of Liability
> The app is provided "AS IS" without warranties of any kind. To the maximum extent permitted by law, Milton Recovery Centers is not liable for indirect, incidental, or consequential damages arising from your use of the app.

### 13. Governing Law
> These Terms are governed by the laws of the State of Florida, USA, without regard to its conflict of law principles. Any dispute will be resolved in the state or federal courts located in Miami-Dade County, Florida.

### 14. Changes to These Terms
> We may update these Terms occasionally. Material changes will be communicated in-app or via email at least 30 days before they take effect. Continued use after changes constitutes acceptance.

### 15. Contact
> Milton Recovery Centers
> Email: <a href="mailto:media@miltonhealthgroup.com">media@miltonhealthgroup.com</a>
> Florida: (844) 406-4325 (24/7)
> Ohio: (740) 715-4673 (24/7)

---

## Visual / formatting requirements

| Item | Requirement |
|---|---|
| **Page accessibility** | Public URL, no login required, no robots.txt block |
| **Mobile responsive** | Must render readable on phone (TCR may check on mobile) |
| **SSL** | HTTPS required (already covered by miltonrecovery.com cert) |
| **Body text** | Black on white. No dark mode for this page. |
| **STOP / HELP** | Must be visually bold (HTML `<strong>` or CSS `font-weight: 700`) |
| **Footer cross-link** | Link to Privacy Policy + back to homepage |
| **Branding** | Match the existing miltonrecovery.com look. Logo + standard nav. |

---

## How to verify the page is ready

When the tech team thinks it's done, run these checks before reporting back:

```bash
# 1. Does the URL return HTTP 200?
curl -I https://miltonrecovery.com/terms
# Expected: HTTP/2 200 ... content-type: text/html

# 2. Is STOP / HELP visible in the rendered HTML?
curl -s https://miltonrecovery.com/terms | grep -i "STOP\|HELP"
# Expected: hits with <strong> wrappers

# 3. Does the page render on mobile?
# Open https://miltonrecovery.com/terms on a phone browser → readable? Tappable links?

# 4. Is the SMS section above the fold and clearly labeled?
# Open the page → use Cmd+F → search "STOP" → should find it within first ~50% of page
```

---

## After the page is live — what happens

1. **Reply to Ezra (Claude) with**: `"terms page live"`
2. Claude will:
   - Update the Twilio A2P 10DLC Campaign's Terms URL from the temporary `/privacy` placeholder → real `/terms`
   - Resubmit the campaign for TCR review
   - Notify you when SMS starts delivering (typically 1-3 days after URL update)

---

## Why we're doing this

Without this Terms page, the path to public launch is blocked at three points:
- 🚫 SMS OTP doesn't deliver (carriers filter unregistered A2P)
- 🚫 Apple may flag the App Store listing (privacy URL alone is borderline)
- 🚫 Twilio BAA won't activate (HIPAA review requires demonstrated compliance posture)

Once `/terms` is live, all three unblock simultaneously. This is one of the highest-leverage 30-minute tasks on the entire launch.

---

## Estimated effort for tech team

- Junior dev with a CMS / static site template: **2 hours**
- Senior dev: **30-45 minutes**
- Using a Terms-of-Service generator + light customization for #6 and #10: **15-20 minutes**

The SMS section (#6) is the hardest part to get right — everything else is standard ToS boilerplate. Once you have the language above, copy-paste exact wording for #6.
