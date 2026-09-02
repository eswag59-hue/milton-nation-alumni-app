# Akash reply — 2026-06-08, urgent (12-biz-hr ticket closure window)

**To:** existing ticket thread, reply on the 6/8 3:03 PM follow-up from Twilio Support (`support@twilio.zendesk.com`)
**Subject:** keep auto-generated reply subject ("Re: A2P 10DLC Campaign FAILED — resubmission with corrected business profile + authorization letter")
**From:** ebarish@miltonhealthgroup.com

---

## Body — paste verbatim

Hi Akash,

Apologies for the delay — I was out for my wedding last week. Picking this back up now.

Following your 5/31 (and again 6/2, 6/5, 6/8) requests, here are the two Campaign SIDs you asked about. I now have TWO campaigns in FAILED status — both submitted via API after the Console UI proved non-functional for editing, and both rejected by TCR with similar error patterns:

**Campaign 1 — 2FA / Login OTP**
- Messaging Service SID: `MG5841b1dd280260d8d5107a2467b1a3d2`
- Campaign SID: `QE2c6890da8086d771620e9b13fadeba0b`
- Use case: `2FA`
- Brand: `BN4bb2811c5d19f19ae546b65b4c296cc6` (approved)
- Status: **FAILED**
- Errors per `GET /v1/Services/MG5841.../Compliance/Usa2p`:
  - `30909` — Call to Action (CTA) verification
  - `30908` — Privacy policy verification
  - `30882` — Terms and Conditions

**Campaign 2 — MARKETING / Admin invites**
- Messaging Service SID: `MG58c4c25a365e158067a5875b6488bad8`
- Campaign SID: `QE2c6890da8086d771620e9b13fadeba0b` (same string, different MS namespace)
- Use case: `MARKETING`
- Brand: same `BN4bb2811c5d19f19ae546b65b4c296cc6`
- Status: **FAILED**
- Errors:
  - `30882` — Terms and Conditions
  - `30909` — CTA verification
  - `30908` — Privacy policy verification
  - `30886` — Invalid campaign description

**What I've already verified on my end:**

1. **Privacy policy is live and serves a 200 OK at `https://miltonrecovery.com/milton-nation-privacy/`.** The page contains all standard TCR-required disclosures: "Reply STOP / Reply HELP" instructions, "Message and data rates may apply," message frequency notice, carrier disclaimer, explicit non-disclosure of mobile numbers and SMS opt-in consent data to third parties for marketing or promotional purposes, and identification of the Milton Nation SMS program.

2. **Terms of service is live and serves a 200 OK at `https://miltonrecovery.com/app-terms-of-use/`.** It contains "Reply HELP," carrier disclaimer, message frequency notice, and SMS program identification.

3. **Both URLs follow a 301 redirect from the no-slash form to the trailing-slash form.** This may be what the vetter's scraper is failing on — please confirm whether your vetter follows 301 redirects when verifying URLs in `message_flow` text.

4. **The message_flow text I submitted for each campaign accurately describes the in-app consent flow** (Create Account form with inline SMS consent disclosure below the phone field) and the admin-initiated invite flow (written consent at discharge OR verbally captured in the alumni-management system).

**What I'm asking for from you:**

Could you please open both campaigns in your internal vetting console and share:

- The exact text the TCR vetter flagged for each error code (30909, 30908, 30882, 30886) — the raw vetter notes, not the generic error description.
- Whether the vetter actually accessed `https://miltonrecovery.com/milton-nation-privacy/` and `https://miltonrecovery.com/app-terms-of-use/` and what HTTP response code or content they observed.
- For error 30886 on the marketing campaign — what specifically about the description ("One-time SMS invitations sent by Milton Recovery Centers admins to prospective alumni…") was flagged.

Without the specific vetter notes I'm guessing what to change. The generic error descriptions all return URLs that point to `https://www.twilio.com/docs/api/errors/30NNN`, which describe the error class but not what the vetter actually saw on my submission.

Once I have the specific notes, I can correct and resubmit both campaigns via the API within the same business day. SMS delivery is the last launch-blocker for this iOS app — I'd like to move quickly.

Note: the BAA portion of the original scope is no longer active. We've moved to brand-anonymous OTP message bodies, so no PHI flows through Twilio under the current architecture. Please don't route the BAA item to your healthcare team.

Thank you,
Ezra Barishansky
ebarish@miltonhealthgroup.com

---

## Why this email is the right move

- Akash has sent three follow-ups (6/2 / 6/5 / 6/8) explicitly asking for SIDs. The first thing he sees should be the SIDs.
- Naming the wedding once costs nothing and frames the delay as personal-not-disengagement; vendors respond better to humans.
- The error codes + URL evidence forces Akash to actually open the vetter's notes rather than send another canned response.
- The four "what I'm asking for from you" bullets give him a precise checklist — he can't answer "yes" without producing the data we need.
- Removing the BAA ask narrows the ticket to one thing (campaign fix), reducing his ability to punt.
