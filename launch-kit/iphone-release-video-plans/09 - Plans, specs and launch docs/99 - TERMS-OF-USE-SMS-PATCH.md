# Patch for tech team — Terms of Use SMS section

**URL to update:** https://miltonrecovery.com/app-terms-of-use/
**Why:** Twilio's A2P 10DLC vetter (TCR) rejected our SMS campaign in part on error code 30882 (Terms and Conditions). The page is missing an explicit "Reply STOP" SMS opt-out clause that TCR scrapers look for. Adding the paragraph below will likely satisfy 30882 on resubmission.

---

## Email to send to tech team — paste verbatim

**To:** (tech team contact)
**Subject:** Quick T&C update for Milton Nation SMS campaign approval

Hi,

We need a small addition to the App Terms of Use page (`https://miltonrecovery.com/app-terms-of-use/`) to satisfy a Twilio SMS-program compliance check. The page already has most of what we need; it's missing an explicit "Reply STOP" SMS opt-out clause that the SMS vetting team is looking for.

Please add the section below as its own subsection (preferably titled "SMS Messaging Program — Opt-Out and Help") within the existing Terms of Use page. Position it adjacent to the existing SMS-related language, ideally near the top of the page or at minimum within the first half so the vetter's scraper finds it quickly.

---

**Section to add:**

**SMS Messaging Program — Opt-Out and Help**

By providing your mobile phone number to the Milton Nation app, you consent to receive transactional SMS messages from Milton Nation, including but not limited to one-time verification codes used for account login and two-factor authentication. You may also receive a one-time invitation SMS if you have separately consented through a written or verbal consent process with Milton Recovery Centers staff.

**Frequency:** Message frequency varies based on your use of the app. Typically you will receive one SMS verification code per login.

**Message and data rates:** Standard message and data rates may apply per your mobile carrier.

**To opt out:** Reply **STOP** to any Milton Nation SMS message at any time. You will receive a confirmation message acknowledging your opt-out, after which no further SMS messages will be sent to that number from this program. You may also resubscribe at any time by replying **START**.

**For help:** Reply **HELP** to any Milton Nation SMS message, or contact support at support@miltonrecovery.com.

**Carrier disclaimer:** Carriers including AT&T, T-Mobile, Verizon, U.S. Cellular, and others are not liable for delayed or undelivered messages.

**Privacy:** Mobile phone numbers and SMS opt-in consent data collected through this program are used solely for the purposes of delivering the messages you have requested. Such data will NOT be shared with third parties or affiliates for marketing or promotional purposes. For full details, see our Privacy Policy at `https://miltonrecovery.com/milton-nation-privacy/`.

---

Could you push this live today if possible? It's the last item gating our SMS campaign approval at Twilio, which in turn is the last item gating the App Store launch.

Thank you,
Ezra

---

## Why this paragraph (for our records, not for the tech team)

Twilio's CTIA/TCR vetting looks specifically for:

- "Reply STOP" — opt-out keyword
- "Reply HELP" — help keyword
- Message frequency disclosure
- Carrier disclaimer
- Privacy policy reference
- "Mobile information will not be shared..." — CTIA 2025 requirement
- Identification of the SMS program

This paragraph hits every one of those checkboxes in a single dense block that's easy for an automated scraper to parse, regardless of where it lands in the page hierarchy.
