# App Store Submission Packet — Milton Nation (Build 13)

Everything to paste into App Store Connect. Listing **copy** lives in `04-app-store-connect-content.md`; this file is the **App Privacy questionnaire answers** + **reviewer notes** + the **pre-submit gate**.

---

## 1. App Privacy ("nutrition label") — questionnaire answers

In ASC → App Privacy → "Get Started." For each type below: **Collected = Yes**, **Linked to the user = Yes**, **Used for tracking = No** (the app does NOT track across other companies' apps/sites; no third-party ad SDKs). Purpose = **App Functionality** unless noted.

| Data type | Collected | Linked | Purpose |
|---|---|---|---|
| **Name** | Yes | Yes | App Functionality (profile, community identity) |
| **Email Address** | Yes | Yes | App Functionality, Account management |
| **Phone Number** | Yes | Yes | App Functionality (SMS verification via Twilio Verify) |
| **User Content** — posts, comments, photos, messages | Yes | Yes | App Functionality |
| **Health & Fitness** — sobriety/recovery data (sensitive) | Yes | Yes | App Functionality |
| **User ID** | Yes | Yes | App Functionality |
| **Crash Data / Diagnostics** | Yes | Yes | App Functionality (in-app crash reporting) |
| **Product Interaction / Usage Data** | Yes | Yes | App Functionality, Analytics (first-party only) |

- **Tracking:** select **"No, we do not track."**
- **Health data note:** recovery/sobriety content is sensitive — confirm the Privacy Policy (live at https://miltonrecovery.com/milton-nation-privacy/) discloses its collection, use, and that it is NOT sold/shared with third parties.

## 2. App Review Information (reviewer notes — paste verbatim)

> **Demo account (full access, no SMS needed):**
> Email: `appreviewer@miltonrecovery.com`
> Password: `Milton2026!`
> When prompted for the 6-digit SMS code, enter **`000000`** (a reviewer bypass; no real SMS is sent).
>
> **About the app:** Milton Nation is a private peer-support community for alumni of Milton Health Group's recovery programs. It includes a moderated community feed, meetings, care-team messaging, and crisis-support resources.
>
> **User-generated content & safety (Guideline 1.2):** All posts pass automated content filtering before publishing. Users can **report** any post or comment and **block** other users (in-app). Admins moderate via a flags queue. Terms of Use: https://miltonrecovery.com/app-terms-of-use/ · Privacy: https://miltonrecovery.com/milton-nation-privacy/.
>
> **Sign-in:** email/password + SMS one-time code (Twilio Verify). The demo bypass above avoids needing a real phone.

## 3. Other ASC fields
- **Category:** Health & Fitness.
- **Age rating:** complete the questionnaire — expect **17+** (medical/treatment info + unrestricted user-generated content).
- **Export compliance:** already declared in-app (`ITSAppUsesNonExemptEncryption = NO`) — no prompt expected.
- **Support URL / Marketing URL:** confirm live before submit.
- **Screenshots:** upload your fresh Build 26 screenshots (Alex Demo account) — 6.9" + 6.1".

---

## ⛔ Pre-submit gate — do NOT click "Submit for Review" until ALL true
- [x] **Report + Block shipped** (Apple 1.2) — ✅ live since Build 16, verified.
- [x] Full test suite passed on Build 26 (create-post, crisis, report/block, delete, isolation, staff view, multi-photo) — ✅ 0 showstoppers.
- [ ] Fresh screenshots uploaded.
- [ ] App Privacy questionnaire completed (section 1).
- [ ] Reviewer notes + demo account entered (section 2).
- [ ] Build 26 processed + selected.

*(Twilio Verify SMS, live Privacy/Terms URLs, account delete + data export, and RLS are already verified ✅.)*
