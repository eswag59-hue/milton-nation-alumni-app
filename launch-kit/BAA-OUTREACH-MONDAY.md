# Twilio HIPAA BAA — Monday 6/1 outreach kit

**Status:** BAA is now defense-in-depth, NOT launch-blocking, after the OTP brand strip (commit `5e9b5ff`, deployed 2026-05-31). Pursue these three channels in parallel Monday morning. Expected time: 30 minutes total.

Pick whichever path responds first; once one moves, drop the others or fold them into the same thread.

---

## Action 1 — Phone call (do this first, fastest signal)

**Call:** 1-877-468-9456 (Twilio Sales)

**Script (read literally if you want):**

> Hi, this is Ezra Barishansky calling on behalf of Milton Health Group LLC. Twilio Account SID `AC3ad114d4769975de61f426a49e52a2de`. I need to be connected to a healthcare or HIPAA solutions engineer.
>
> Context: we run a recovery alumni iOS app. We have an open support ticket — number 27179042 — that started about a HIPAA BAA execution. The A2P 10DLC campaign portion of that ticket is now resolved on our end via direct API call. The remaining ask is the BAA itself.
>
> We have a signed authorization letter on file from our parent entity, EIN 93-2880131. We are ready to sign whatever standard BAA you provide today. What is your fastest path?

**What you want from the call:**
- Name + direct email of the healthcare AE/SE who will own this
- Realistic timeline (days vs weeks)
- Whether they need to upsell you to a paid tier first (be prepared for this — current account balance is $23.15)
- Whether there's a standard BAA PDF you can just sign immediately, or whether it requires a back-and-forth redline

**Red flags:** If they say "submit a request and someone will get back to you within 5 business days" — escalate by name to a manager. Don't accept queue-routing.

---

## Action 2 — Email to healthcare BAA inbox

**To:** healthcare-baa@twilio.com
**CC:** (after the phone call, CC the AE you spoke with so the two threads converge)
**Subject:** BAA execution request — Milton Health Group LLC — Ticket #27179042

**Body — paste verbatim:**

Hi Twilio Healthcare Compliance,

I'm requesting execution of a HIPAA Business Associate Agreement for the following account:

- **Entity:** Milton Health Group LLC (Delaware LLC, EIN 93-2880131)
- **Twilio Account SID:** `AC3ad114d4769975de61f426a49e52a2de`
- **Primary contact:** Ezra Barishansky, `ebarish@miltonhealthgroup.com`
- **Open ticket:** #27179042
- **Authorization letter:** signed by Michael Schwartz, MHG co-owner, on file with ticket (attached again here for convenience)

We operate a substance-use-disorder recovery alumni iOS app. Our Twilio usage today is Programmable Messaging (A2P 10DLC, use case 2FA, Campaign Sid `QE2c6890da8086d771620e9b13fadeba0b` currently in vetting). Our outbound SMS bodies have been deliberately brand-anonymous so that Twilio is not handling Protected Health Information as part of the OTP flow. We're requesting a BAA as defense-in-depth and to enable future expansion into branded messaging.

We are ready to execute Twilio's standard BAA immediately on receipt. No redlines anticipated.

Please advise on next steps and timeline.

Thank you,
Ezra Barishansky
ebarish@miltonhealthgroup.com
(your phone)

**Attach:** `launch-kit/legal/MHG-AUTHORIZATION-SIGNED.pdf`

---

## Action 3 — Reply on existing ticket #27179042 (to Akash)

This is a short ticket update — primary value is consolidating the BAA ask alongside the now-resolved Campaign work, and giving Akash an opportunity to route internally.

**Subject:** Re: [Twilio] A2P 10DLC Campaign FAILED — resubmission with corrected business profile + authorization letter

**Body — paste verbatim:**

Hi Akash,

Quick update and one remaining ask:

**Campaign resolved:** I was able to delete the failed A2P 10DLC campaign and submit a new one with the corrected use case (`2FA`), corrected message_flow matching the actual app opt-in screen, and the privacy/terms URLs the prior submission was missing. New Campaign SID: `QE2c6890da8086d771620e9b13fadeba0b`, status `IN_PROGRESS`, brand `BN4bb2811c5d19f19ae546b65b4c296cc6`. This was done via the messaging.twilio.com/v1 REST API because every Console UI path I tried was non-functional for editing or recreating the campaign through the new Trust Hub flow. No further action needed from Twilio on the campaign — TCR vetting is in flight.

**Remaining ask — HIPAA BAA execution.** This was part of the original scope on this ticket and is still open. Could you please route the BAA request to your healthcare/compliance team and CC me on the handoff? Authorization letter from Milton Health Group LLC (EIN 93-2880131) signed by Michael Schwartz is on file with this ticket. We're ready to execute Twilio's standard BAA on receipt — no redlines anticipated. I've also emailed `healthcare-baa@twilio.com` directly in parallel.

Thank you,
Ezra Barishansky
ebarish@miltonhealthgroup.com

---

## After Monday

**If phone call goes well:** the AE owns it. Forward Action 2 and Action 3 to them as context, drop the queue routing.

**If no progress by Friday 6/5:** escalate. Ask the AE or Akash for a manager name. The wedding-week excuse buys you exactly zero patience from carriers; the launch is now on a critical path so manage Twilio's response time accordingly.

**If they say "we don't do BAAs at your spend tier":**
- Option A — upgrade to Twilio Verify product (built-in BAA support, no per-customer negotiation; ~30 lines of code change in `send-sms-otp/index.ts`)
- Option B — switch SMS vendor (Sinch markets explicitly to healthcare; AWS End User Messaging is now HIPAA-eligible under the standard AWS BAA)

---

## Reminder: launch is NOT blocked on this

OTP messages are now brand-anonymous (commit `5e9b5ff`). No PHI flows through Twilio for the launch-critical signup + login flows. The BAA is a "do this in parallel" item, not "wait for this before launching."

Supabase HIPAA add-on activation on launch day still covers the BAA-required parts of the stack (database + auth + storage).
