# If Apple Rejects — Recovery Playbook

Apple rejects ~30-40% of first submissions for health-category apps. **Don't panic.** Most rejections are fixable in <2 hours and you can resubmit with an "Expedited Review" request the same day.

---

## How to read a rejection

You'll get an email titled "Your app submission has been reviewed" linking to **Resolution Center** in App Store Connect. The reviewer cites a specific guideline number (e.g., "5.1.1" or "2.1"). Look up the guideline at https://developer.apple.com/app-store/review/guidelines/ — that's your spec.

---

## Most likely rejection reasons + responses

### Rejection 4.0 — "App contains placeholder or low-quality content"

> "Your app's screenshots include placeholder text like 'Lorem ipsum'..."

**Response template**:
```
Hi App Review,

Thank you for the feedback. The screenshots have been refreshed with production content reflecting the actual user experience. No placeholder text remains. Please find the updated screenshots in this resubmission.

If there's a specific screen that still appears to contain placeholder content, please let me know which one and I'll address it directly.

Best,
Ezra Barishansky
```
**Action**: Replace screenshots in App Store Connect → resubmit.

---

### Rejection 5.1.1 — "Insufficient privacy disclosure"

> "Your app collects Health data but the privacy policy does not explicitly cover collection of sobriety dates and treatment information..."

**Response template**:
```
Hi App Review,

We've updated the privacy policy at https://miltonrecovery.com/app-privacy-policy/ to include explicit disclosure of:
• Sobriety date collection and use
• Recovery program type collection
• Treatment-related health information processed during community moderation
• HIPAA-aware data handling and Business Associate Agreements with Supabase and Twilio

The updated policy is now live. The App Privacy questionnaire in App Store Connect has also been reviewed and includes Health & Fitness + Sensitive Info categories with full purpose disclosure.

Best,
Ezra Barishansky
```
**Action**: Update privacy policy text, push to https://miltonrecovery.com/app-privacy-policy/, resubmit. Don't change the App Store Connect privacy questionnaire — those answers are correct.

---

### Rejection 5.1.1 (v2) — "Sign-in required for content review"

> "We were unable to evaluate the app's full functionality because we couldn't sign in. The phone number / code provided didn't work."

**Response template**:
```
Hi App Review,

Apologies for the inconvenience. The demo bypass requires both:
• Phone number EXACTLY: +15550001234 (no spaces, with the +1 country code)
• Code EXACTLY: 000000 (six zeros)

I've verified the demo bypass is active on the backend. To rule out any account state issue, the demo account "Alex Demo" has been reset to a clean state.

Could you re-test? If you continue to see issues, please share:
1. The exact phone format you're entering
2. Any error messages displayed
3. A timestamp of the sign-in attempt (so I can correlate to backend logs)

Best,
Ezra Barishansky
```
**Action**: Verify DEMO_BYPASS_ENABLED=true on Supabase, resubmit. If issue persists, inspect the verify-sms-otp logs around the timestamp the reviewer reports.

---

### Rejection 1.4 — "Medical claims require regulatory clearance"

> "Your app makes medical claims about substance use disorder treatment that require FDA or other regulatory clearance..."

This is unlikely but if it happens:

**Response template**:
```
Hi App Review,

Milton Nation does not provide medical treatment, diagnose conditions, or replace clinical care. The app is a peer-support and care-team-communication tool for verified alumni of Milton Recovery Centers, a licensed substance use disorder treatment facility.

Specifically:
• The "Sobriety Tracker" simply records a self-reported date the user provides — it makes no medical claim.
• The "Daily Reflection" feature shows curated motivational quotes — not medical advice.
• The "I'm Struggling" feature surfaces public crisis resources (988, SAMHSA) — these are publicly listed services, not medical interventions.
• The 1:1 chat with care team is between alumni and staff at the originating treatment facility — Milton Recovery Centers itself is the licensed provider, not the app.

The app's role is purely communication infrastructure for an existing treatment relationship. No medical claims are made. We have language to this effect in our Terms of Service at https://miltonrecovery.com/app-terms-conditions/.

If specific copy in the app should be reworded to make this clearer, please point me to the screen and I'll update it immediately.

Best,
Ezra Barishansky
```
**Action**: Audit every screen for any text that could be read as a medical claim. Soften copy where ambiguous. Resubmit.

---

### Rejection 2.1 — "We were unable to install your app"

> "We couldn't install your build on iPad / iPhone / etc."

**Response template**:
```
Hi App Review,

Thank you for flagging. The app supports iPhone only (LSRequiresIPhoneOS=true, iPad UI not implemented for v1). The app is locked to portrait orientation on iPhone and portrait/portrait-upside-down on iPad to handle iPad usage gracefully if installed.

If the failure was on iPad with a "no compatible build" error, that is expected — we're targeting iPhone for v1 and will add iPad support in a future release.

If the failure was on iPhone, please share the device model and iOS version so I can investigate.

Best,
Ezra Barishansky
```
**Action**: If iPad-only issue, mark the app as "iPhone Only" in App Store Connect → Pricing & Availability. If iPhone issue, check that the build's deployment target matches the test device (iOS 18.0+).

---

### Rejection 4.1 — "App or its metadata appears similar to another app"

Unlikely but if it happens:

**Response template**:
```
Hi App Review,

Milton Nation is the official alumni app for Milton Recovery Centers, a real licensed treatment facility operating in Florida and Ohio (https://miltonrecovery.com). The app is not a copy of another product — it's a custom-built alumni community for our specific facility's users.

To clarify the relationship:
• Milton Health Group LLC is the developer (the legal entity)
• Milton Recovery Centers is the operating treatment program
• "Milton Nation" is the brand name for the alumni community

If the reviewer believes the app resembles another, could you share which one? I can highlight the specific differentiators.

Best,
Ezra Barishansky
```

---

### Rejection 1.1.4 — "Inappropriate content for children"

> "Recovery / substance use content is not appropriate for the app's age rating..."

**Response template**:
```
Hi App Review,

The Age Rating questionnaire was completed with "Frequent/Intense" for Drug/Alcohol Use References, resulting in a 17+ rating. The app is intended for adult alumni of substance use disorder treatment.

If the rating displayed in your tooling shows lower than 17+, please let me know — that may be a data sync issue on my end and I'll update.

The content the app displays is:
• User-generated posts moderated server-side for crisis content
• Curated daily reflection quotes (no graphic content)
• Public crisis resource phone numbers (988, SAMHSA)

All content is appropriate for a 17+ recovery audience.

Best,
Ezra Barishansky
```
**Action**: Verify Age Rating in App Store Connect → App Information → Age Rating. Should show 17+.

---

### Generic rejection ("Guideline 2.5.4" or similar metadata issue)

> "Your app metadata contains keywords that do not represent your app..."

**Response template**:
```
Hi App Review,

Thank you for the review. I've updated the keywords in App Store Connect to remove any terms that could be perceived as not directly representing the app's functionality. The new keyword list focuses entirely on the app's actual purpose:

recovery,sobriety,alumni,milton,addiction,support,community,counseling,12 step,peer,sober,mental

If a specific keyword should be removed, please let me know.

Best,
Ezra Barishansky
```

---

## How to file the response

1. App Store Connect → your app → top → **Resolution Center**
2. Reply to the rejection thread with the appropriate template above (customize for the specifics).
3. Click **Submit Reply**.
4. If you also made code changes: archive a new build, upload, and select it in the version page.
5. After replying, top-right → **Add for Review** → **Submit**.

## Expedited Review

If you're in a hurry (e.g., a press launch deadline):

1. https://developer.apple.com/contact/app-store/expedited/
2. Pick "Time Sensitive Issue"
3. Explain the deadline (one paragraph)

Apple grants ~50% of expedited requests for legitimate reasons.

---

## Don't do these things

- ❌ Don't argue with the reviewer in the reply. Polite + factual = fast turnaround.
- ❌ Don't resubmit the same build with no change after a rejection. Always change at least one thing (a typo fix, a clearer note) so the next reviewer sees you addressed feedback.
- ❌ Don't escalate to App Review Board until at least 2 round-trip rejections.
- ❌ Don't release to public the day before a holiday. Apple ramps down review staff. Submit Mon-Wed for fastest turnaround.
