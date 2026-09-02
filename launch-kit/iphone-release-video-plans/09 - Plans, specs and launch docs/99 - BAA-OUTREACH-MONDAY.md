# Twilio HIPAA BAA — Monday 6/8 outreach kit

**Status:** BAA is now defense-in-depth, NOT launch-blocking, after the OTP brand strip (commit `5e9b5ff`, deployed 2026-05-31).

**CORRECTION 2026-05-31 23:20:** Per Twilio's actual documentation (`https://www.twilio.com/docs/iam/twilio-editions/hippa`), a HIPAA BAA with Twilio requires Security or Enterprise Edition (paid tier upgrades, typically $1k+/mo minimum commit). There is no direct BAA email — the path is "contact your account manager or Twilio Sales." `healthcare-baa@twilio.com` does NOT exist (verified by bounce 2026-05-31 23:05). The original advice to email that address was wrong. See "Action 1" below for the corrected approach.

Given the cost of upgrading to a HIPAA-eligible tier, and the fact that OTP messages are now brand-anonymous (no PHI flows through Twilio for the launch-critical flow), **you may want to skip pursuing the BAA entirely.** Revisit only if you ever want to send branded outbound SMS (e.g., the currently-deferred invite SMS).

---

## Action 1 — Phone call to Twilio Sales (ONLY remaining outbound path)

**Call:** 1-877-468-9456 (Twilio Sales)

This is now the FIRST question, not the LAST. The healthcare-baa@ direct inbox does not exist; BAA execution is gated behind a Sales conversation about upgrading to Security or Enterprise Edition.

**Script (read literally if you want):**

> Hi, this is Ezra Barishansky calling on behalf of Milton Health Group LLC. Twilio Account SID `AC3ad114d4769975de61f426a49e52a2de`.
>
> Context: we run a recovery alumni iOS app. We have an open support ticket — number 27179042. Our A2P 10DLC campaign is currently in vetting under use case 2FA. Per your documentation, a HIPAA BAA with Twilio requires Security or Enterprise Edition.
>
> Before I go further, I need to understand the cost: (1) what's the monthly minimum commit for the cheapest HIPAA-eligible tier on my account? (2) Is the BAA standard-form sign-and-execute, or does it require a back-and-forth redline? (3) What's the realistic timeline from upgrade to executed BAA — days, weeks, months?
>
> I'm not committing today — just gathering the data to make a build-vs-buy decision. Our outbound SMS is already brand-anonymous so we don't currently process PHI through Twilio, but we'd like to understand the option.

**What you want from the call:**
- Hard monthly cost for HIPAA-eligible tier (Security Edition? Enterprise?)
- Whether the standard BAA is sign-as-is or requires legal review on both sides
- Time-to-signature
- Whether Twilio Verify (their dedicated OTP product) has different BAA terms

**Likely outcome:** the number they quote is high enough that you skip this path and stay on standard Programmable Messaging with brand-anonymous OTPs. That's the right answer unless Milton scales into territory where branded SMS to identified patients becomes a real product need.

---

## Action 2 — Twilio Sales contact form (alternative to phone)

If you don't want to call: https://www.twilio.com/contact-sales — submit with the same talking points as the phone script. Less interactive, slower turnaround, but the same destination.

---

## Action 3 — Reply on existing ticket #27179042 (to Akash) ← SENT 2026-05-31

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
