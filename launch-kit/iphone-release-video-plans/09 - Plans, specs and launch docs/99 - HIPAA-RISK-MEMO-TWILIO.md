# HIPAA Risk Memo — Twilio as a Non-Business-Associate Vendor

**Prepared for:** Healthcare Counsel — Milton Health Group LLC
**Subject:** Documentation of vendor analysis for Twilio (SMS service provider)
**Date drafted:** 2026-05-31
**Status:** Draft for counsel review and signature
**Prepared by:** Engineering team, Milton Nation Alumni App
**Subject app:** Milton Nation iOS app, distributed via Apple App Store
**Subject account:** Twilio Account SID `AC3ad114d4769975de61f426a49e52a2de`

---

## 1. Purpose

This memo documents the rationale for treating Twilio (Programmable Messaging product) as a **non-Business-Associate vendor** for the Milton Nation iOS app, and therefore not pursuing a HIPAA Business Associate Agreement (BAA) with Twilio at this time. This memo is intended to be reviewed and signed by the engaged healthcare counsel, retained as part of the vendor risk assessment file, and produced on demand to regulators, auditors, or cyber insurance underwriters.

## 2. Architecture Summary (post-2026-05-31 changes)

The Milton Nation app uses Twilio's standard Programmable Messaging product for two outbound SMS flows:

### Flow A — Login OTP (always-on, signup + every login)
- **Trigger:** End-user enters their phone number in the iOS app and submits the signup or login form.
- **Twilio receives from Milton:** The recipient phone number and a static-format OTP message body.
- **SMS body verbatim:** `Your verification code is 123456. It expires in 5 minutes. Do not share this code. Reply STOP to opt out, HELP for help.`
- **Brand or treatment-program identifiers in body:** None. No mention of "Milton Recovery Centers," "Milton Nation," or any other identifier that would associate the recipient with a specific substance use disorder treatment program.
- **What Twilio learns:** That an unidentified party requested an SMS delivery to a given phone number containing a 6-digit code.

### Flow B — Admin Invite SMS (manually triggered by Milton Recovery Centers staff)
- **Trigger:** A Milton Recovery Centers administrator enters a prospective alumni's phone number and triggers a one-time invitation.
- **SMS body verbatim:** `[Hi {name},] you've been invited to a peer recovery community app. Stay connected, find meetings, and reach your care team — all in one place. Download for iOS: https://apps.apple.com/us/app/milton-nation. Reply STOP to opt out, HELP for help.`
- **Brand or treatment-program identifiers in body:** None. The text describes a generic "peer recovery community app" without naming Milton Recovery Centers, Milton Jefferson, or any treatment-program affiliation. The App Store URL contains the app's product name (Milton Nation) but does not, on its face, identify Milton Recovery Centers or treatment status.
- **What Twilio learns:** That an unidentified party requested an SMS delivery to a given phone number describing a "peer recovery community app."

## 3. HIPAA Analysis

### 3.1 Applicable definitions

- **Covered Entity (CE):** Milton Recovery Centers (and Milton Jefferson) — substance use disorder treatment providers subject to HIPAA and, separately, 42 CFR Part 2.
- **Business Associate (BA):** A person or entity that performs functions or activities on behalf of, or provides services to, a Covered Entity that involves the use or disclosure of Protected Health Information (PHI). 45 CFR 160.103.
- **Protected Health Information (PHI):** Individually identifiable health information transmitted or maintained in any form. 45 CFR 160.103. Includes the 18 identifiers listed at 45 CFR 164.514(b)(2)(i) when associated with health information.

### 3.2 Is the phone number alone PHI?

A phone number is one of the 18 HIPAA identifiers. However, an identifier in isolation, without any associated health information, is **not PHI** under HIPAA. HHS Office for Civil Rights has consistently held that PHI requires both (a) an identifier and (b) information that relates to physical or mental health, healthcare provision, or healthcare payment.

A phone number alone, transmitted to a vendor that has no context indicating the phone number belongs to a patient, is not PHI.

### 3.3 Does the SMS body convey PHI?

The OTP message body (`Your verification code is X...`) contains no health information whatsoever. It is structurally identical to OTPs sent by retail banking, e-commerce, and other non-healthcare providers. A reasonable observer reviewing this message would have no basis to infer the recipient's health status.

The invite message body (`you've been invited to a peer recovery community app...`) describes a product category ("peer recovery community app") without identifying the recipient as a patient of any specific treatment provider, without identifying the recipient as a person in recovery, and without disclosing any clinical fact. A reasonable observer would have multiple plausible interpretations (interested party, family member, recovery ally, casual user) and could not, from the message alone, conclude that the recipient is or was a Milton Recovery Centers patient.

### 3.4 Could Twilio reverse-engineer PHI from metadata?

Twilio knows: source account (Milton Health Group LLC), recipient phone number, message body, delivery timestamp. Twilio does NOT know: whether the recipient is a Milton Recovery Centers patient, whether the recipient has a substance use disorder, the recipient's treatment status, or any clinical fact about the recipient.

The mere fact that Milton Health Group LLC is the source account does not itself convert recipient phone numbers into PHI, for two reasons:

1. **Milton Health Group LLC operates multiple lines of business** — not all communications from MHG are to patients. The Milton Nation app is positioned as a peer recovery community, not a treatment-program communications channel. Inclusion in the recipient list does not, on its face, indicate patient status.

2. **Twilio's role is purely transmission.** Twilio does not store, query, segment, or otherwise act upon the recipient list in any way that would create a healthcare-data inference. Twilio's records show only message delivery telemetry.

Per the standard HHS analysis applied to telecommunications providers, transmission-only vendors handling generic message bodies do not become Business Associates of healthcare customers merely because the customer is a Covered Entity.

### 3.5 The Conduit Exception

The HIPAA Conduit Exception (45 CFR 160.103, OCR FAQ 1758) provides that mere conduits of information — postal services, telecommunications providers, ISPs — are not Business Associates even when the information they transmit is PHI, provided the conduit's access is "transient and incidental." However, **this analysis does not rely on the Conduit Exception** for two reasons:

1. Twilio does briefly store message content for delivery and may store delivery records, which exceeds the strict "transient and incidental" standard for the Conduit Exception.
2. We assert that the information Twilio transmits is **not PHI at all**, mooting the question of whether the Conduit Exception would otherwise apply.

The analysis above (Sections 3.2–3.4) establishes that no PHI is transmitted to Twilio, which is the dispositive issue.

## 4. Compensating Controls

To maintain the analysis above, Milton commits to the following engineering and operational controls:

1. **No branded SMS through Twilio's standard Programmable Messaging account.** The OTP and invite message bodies will remain free of "Milton Recovery," "Milton Jefferson," "Milton Health Group," "alumni community for Milton Recovery Centers," and any other identifier that would create a Covered-Entity nexus. This is enforced as a code-review checklist item and via the inline comment in the relevant Edge Functions (`supabase/functions/send-sms-otp/index.ts`, `supabase/functions/send-invite-sms/index.ts`).

2. **No PHI in SMS bodies, message metadata, custom message headers, or Twilio webhook callbacks.** Webhook payloads from Twilio (delivery receipts, inbound replies) are processed by Milton-controlled infrastructure (Supabase Edge Functions) and never include clinical content.

3. **Supabase HIPAA add-on activated at launch.** All actual PHI processing (user profiles, treatment programs, sobriety dates, care team chats, content safety flags, audit logs) is performed on Supabase infrastructure under Supabase's executed BAA via the HIPAA add-on. This is the load-bearing BAA for the application.

4. **Future branded SMS will not be sent through the current Twilio account architecture.** If Milton Nation ever needs to send branded promotional SMS that identifies Milton Recovery Centers, the implementation will require either (a) executing a Twilio BAA via Twilio Security/Enterprise Edition, or (b) migrating that specific flow to a vendor with an existing BAA. This decision will be re-reviewed with counsel before any such feature ships.

5. **Annual review.** The vendor risk assessment for Twilio is reviewed at minimum annually, and any material change to the SMS body content, message volume, or Twilio product surface area triggers a fresh review.

## 5. Conclusion

Under the architecture described in Section 2, Twilio does not create, receive, maintain, or transmit Protected Health Information on behalf of Milton Recovery Centers or any other Covered Entity within the Milton Health Group LLC family of entities. Twilio is not a Business Associate as defined at 45 CFR 160.103, and a Business Associate Agreement is not required between Milton Health Group LLC and Twilio for the use cases described in this memo.

This analysis depends on the compensating controls in Section 4 remaining in effect. Material deviation triggers re-review.

---

## Counsel sign-off

I have reviewed the architecture, the messages cited in Section 2, and the analysis in Section 3, and I concur with the conclusion in Section 5 for the use cases described.

| | |
|---|---|
| **Name** | _____________________________________ |
| **Role** | _____________________________________ |
| **Firm** | _____________________________________ |
| **Date** | _____________________________________ |
| **Signature** | _____________________________________ |

---

## Appendix A — References

- 45 CFR 160.103 — HIPAA definitions (Business Associate, Protected Health Information)
- 45 CFR 164.514(b)(2)(i) — Safe Harbor 18 identifiers
- HHS OCR FAQ 1758 — Conduit Exception
- HHS Guidance: "Are mobile applications subject to HIPAA?" (2016, updated 2022)
- Twilio HIPAA documentation: https://www.twilio.com/docs/iam/twilio-editions/hippa
- 42 CFR Part 2 — Confidentiality of Substance Use Disorder Patient Records (applies separately to Milton Recovery Centers' treatment records; not implicated by the Twilio architecture described above)

## Appendix B — Verbatim message bodies (engineering reference)

**OTP (deployed 2026-05-31, `send-sms-otp/index.ts`):**

```
Your verification code is {6-digit code}. It expires in 5 minutes. Do not share this code. Reply STOP to opt out, HELP for help.
```

**Invite (deployed 2026-05-31, `send-invite-sms/index.ts`):**

```
Hi {name}, you've been invited to a peer recovery community app. Stay connected, find meetings, and reach your care team — all in one place.

Download for iOS: https://apps.apple.com/us/app/milton-nation

Reply STOP to opt out, HELP for help.
```

(Greeting prefix is omitted if recipient name is unknown.)
