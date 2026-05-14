# Twilio BAA — Send This Email Today

Status: ❌ **Not signed yet.** Hard blocker for public launch.

This is what you do RIGHT NOW. Copy the email below, paste into your mail client, send. Done in 2 minutes. Reply from Twilio's privacy team typically comes within 3–5 business days.

---

## Send-ready email

**To:** `privacy@twilio.com`
**CC:** (optional) `support@twilio.com`
**Subject:** `BAA Request — Milton Recovery Centers — Account [your SID]`

**Body:**

```
Hi Twilio Privacy Team,

We're launching a HIPAA-aware mobile application (Milton Nation Alumni
App, currently in App Store review) and need to execute a Business
Associate Agreement (BAA) with Twilio before our public release.

Our use case:
- Programmable Messaging (SMS) for phone-based OTP authentication
- US-only delivery, transactional only (no marketing)
- User base: alumni of Milton Recovery Centers, a substance use disorder
  treatment provider in Florida and Ohio
- Protected Health Information (PHI) is associated with the phone numbers
  we SMS, so a BAA is required for HIPAA compliance

Account details:
- Company: Milton Recovery Centers / Milton Health Group
- Twilio Account SID: AC... [PASTE YOUR ACCOUNT SID HERE FROM THE TWILIO CONSOLE]
- Twilio products in use today: Programmable Messaging (SMS)
- Anticipated monthly volume at launch: ~500–2,000 SMS
- Primary contact: Ezra Barishansky
- Email: ezra@miltonrecovery.com
- Phone: +1 (201) 747-7727
- Company address: [PASTE YOUR REGISTERED BUSINESS ADDRESS]

Target public launch: within the next 2–4 weeks (pending Apple App Store
review approval). Please send the BAA over for execution at your earliest
convenience.

If there are any other compliance prerequisites (HIPAA eligibility review,
account tier upgrade, A2P 10DLC brand verification, etc.) please let me
know what's required to unlock signing.

Thanks,
Ezra Barishansky
Milton Recovery Centers
+1 (201) 747-7727
```

---

## What you need to fill in before sending

| Placeholder | Where to find it |
|---|---|
| `AC... your account SID` | Twilio Console → top-right dropdown → Account info (32-char string starting with `AC`) |
| Registered business address | Whatever address is on file with Milton's incorporation paperwork |

That's it. Two fields. Send.

---

## What happens after you send

| Day | Twilio side | You |
|---|---|---|
| 0 (today) | Receives request, opens ticket | Sent. Wait. |
| 1–3 | Privacy team reviews, may ask for: account upgrade if on Trial, A2P 10DLC brand registration | Answer their questions |
| 3–5 | Sends DocuSign BAA template | Sign DocuSign |
| 5–7 | Twilio General Counsel countersigns | Done |
| 7–10 | Account flagged "HIPAA-eligible" in their backend | You're cleared for public launch |

**Total timeline: ~1–2 weeks.** Runs in parallel with Apple Review.

---

## Three things they'll probably ask you to do

### 1. Upgrade from Trial to paid account (if applicable)
- BAA only available on paid accounts
- Console → Billing → add a payment method
- Cost: ~$1 to upgrade + ~$0.0083 per SMS sent

### 2. Register A2P 10DLC (US carrier requirement, separate from BAA)
- All US-bound SMS from long-code numbers must have brand+campaign registered with US carriers
- Without it: carriers silently drop messages (no error returned). This may be why your test SMS today didn't arrive.
- Console → Messaging → Regulatory Compliance → A2P 10DLC
- Register Brand (Milton Recovery Centers) → Register Campaign (Account Verification / OTP)
- Cost: ~$4 one-time brand fee + ~$15 monthly campaign fee
- Approval time: 3–7 days for the brand, instant for the campaign once brand is approved

### 3. Sign the BAA template they email you

---

## Once you've sent the email — tell me

I'll add a reminder to follow up if Twilio doesn't respond within 5 business days. We can also start the A2P 10DLC registration in parallel — you don't have to wait for the BAA to begin that (and you may need it to fix today's SMS delivery issue regardless of HIPAA).
