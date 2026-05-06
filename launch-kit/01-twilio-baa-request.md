# Twilio BAA Request Email

Send this to **healthcare-baa@twilio.com** (or open a request via the Twilio Console → Help → Compliance).

---

## Subject

`BAA request — Healthcare/Recovery iOS app sending SMS OTP (Account SID: <YOUR_TWILIO_ACCOUNT_SID>)`

---

## Body

Hi Twilio Compliance team,

I'm writing to request a Business Associate Agreement (BAA) for our Twilio account in support of a HIPAA-aware iOS application.

### Account details
- **Twilio Account SID**: `<paste your Account SID here — find it at https://console.twilio.com/>`
- **Business name**: Milton Health Group LLC
- **Business address**: `<your registered LLC address>`
- **Primary contact**: Ezra Barishansky, ezra@miltonrecoverycenters.com, `<your phone>`

### Use case
We operate **Milton Nation Alumni**, a private, invite-only iOS app for verified alumni of Milton Recovery Centers (substance use disorder treatment). Twilio is used **only** for:

1. **Phone verification (SMS OTP)** during sign-in. The SMS body contains a 6-digit code and a STOP-to-opt-out instruction. No PHI is included in the message body, but the recipient phone number is itself PHI under HIPAA because it's tied to a verified treatment alumni.
2. **Invite SMS** sent by admins to new alumni post-discharge. Body contains a generic invite link only — no PHI.

A2P 10DLC Brand was registered and approved on `<approval date>`. Campaign registration is in progress.

### What we need
A signed BAA covering our use of Twilio Programmable Messaging (SMS) and the associated phone number/A2P resources tied to Account SID above.

### Compliance posture
- All Twilio API credentials are stored as encrypted secrets in our backend (Supabase Edge Functions), never in client code.
- All SMS bodies are reviewed for PHI exclusion before deployment.
- We log audit events for every SMS sent, including timestamps and recipient masking.
- We never include names, dates of birth, treatment details, or any other PHI in SMS content.

Please let me know what additional information you need to process this BAA. We're aiming to launch the app within the next 30 days and would appreciate prioritized turnaround if possible.

Thanks,
**Ezra Barishansky**
Milton Health Group LLC
ezra@miltonrecoverycenters.com

---

## What to expect after sending

1. Twilio replies in 1–5 business days with a digital BAA via DocuSign.
2. You countersign.
3. They activate the BAA on your account — no code or config changes needed.
4. Save a PDF copy of the signed BAA in your compliance folder (e.g., Google Drive → "Milton Health Group LLC / Compliance / BAAs / Twilio").

## Status check

You can verify the BAA is active by going to:
**Twilio Console → Settings → Compliance → Business Associate Agreement**

It should show a "Signed" status with the effective date.
