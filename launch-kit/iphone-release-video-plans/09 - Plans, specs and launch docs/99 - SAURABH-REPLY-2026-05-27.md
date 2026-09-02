# Reply to Saurabh — Twilio ticket #27179042 — 2026-05-27 evening

**Send to:** Saurabh Singh (Twilio Support) — reply on the existing ticket thread
**From:** ebarish@miltonhealthgroup.com
**Subject:** Re: [Twilio] A2P 10DLC Campaign FAILED — resubmission with corrected business profile + authorization letter
**Attachments:** 2 screenshots (see "Attachments" section at the bottom of this doc)

---

## Body — paste this verbatim into your reply

Hi Saurabh,

Thank you for the guidance. I attempted to update the use case via the Console as you instructed, but I'm hitting platform limitations that prevent me from doing so. Specifically:

**1. Messaging Service compliance page (One Console):**
The campaign is visible as read-only. Campaign use case displays as `LOW_VOLUME`. There is a "View campaign details" button (read-only) and a "Manage in Trust Hub" link. There is no field, dropdown, or other edit control on this page to change the use case. *(Screenshot 1 attached.)*

URL: `https://1console.twilio.com/account/AC3ad114d4769975de61f426a49e52a2de/us1/messaging/messaging-services/MG5841b1dd280260d8d5107a2467b1a3d2/compliance`

**2. "Manage in Trust Hub" → Trust Hub > Compliance Registrations:**
Clicking the "Manage in Trust Hub" link routes me to the Compliance Registrations list. The list contains only my SHAKEN/STIR voice registration ("app milton" / `BU2e39fec3b210973b8fea346689a2f12d`). **The A2P 10DLC Campaign does not appear at all on this page**, even after clearing all filters. There is no row to edit. *(Screenshot 2 attached.)*

URL: `https://1console.twilio.com/account/AC3ad114d4769975de61f426a49e52a2de/us1/trusthub/compliance-registrations`

**3. Legacy A2P 10DLC Console pages return 404:**
Both `/develop/sms/regulatory-compliance/messaging/a2p-10dlc/campaigns` and `/develop/sms/regulatory-compliance/messaging/a2p-10dlc/brands` return "Sorry, we couldn't find the page you're looking for." These pages appear to have been retired.

The A2P 10DLC Campaign clearly exists in your backend — it is referenced in the Messaging Service compliance view with its description and current `LOW_VOLUME` use case, and your team has reviewed it through this ticket. However, **there is no editable surface in either Console (classic or One Console) that exposes the campaign's use case field for modification.**

Could you either:

a. **Update the use case from `LOW_VOLUME` to `2FA (Two-Factor Authentication)` on your end** via internal Twilio Trust & Safety tooling, OR
b. **Provide the exact menu path / URL where you expect this campaign to be editable**, so I can verify whether this is a Console UI bug specific to my account or expected behavior?

For your other two asks: those were already delivered in my email of 5/26/2026 18:20 ET. Restating for clarity:

- **App opt-in process & screenshots:** Already sent. Full step-by-step description, plus two screenshots showing the Create Account form (with inline SMS consent text below the phone field) and the Two-Factor Authentication OTP entry screen. Happy to resend if you need them again.
- **Privacy policy updated:** Already sent. https://miltonrecovery.com/milton-nation-privacy now explicitly states: *"Mobile numbers and SMS opt-in consent data are never shared with third parties or affiliates for marketing purposes."*

Once the use case is corrected to `2FA`, I'm ready to resubmit the Campaign immediately.

Thank you,
Ezra Barishansky
ebarish@miltonhealthgroup.com

---

## Attachments

You need to attach two screenshots. Two ways to get them:

**Easiest — take fresh ones yourself (15 seconds each):**

1. **Screenshot 1** — open this URL in your own Chrome, scroll until the "10DLC" panel is visible with "Campaign use case: LOW_VOLUME" and the two buttons, then `Cmd+Shift+4` and drag a box around it:
   `https://1console.twilio.com/account/AC3ad114d4769975de61f426a49e52a2de/us1/messaging/messaging-services/MG5841b1dd280260d8d5107a2467b1a3d2/compliance`

2. **Screenshot 2** — open this URL, then `Cmd+Shift+4`:
   `https://1console.twilio.com/account/AC3ad114d4769975de61f426a49e52a2de/us1/trusthub/compliance-registrations`

**Alternative:** the screenshots I already captured from your Chrome are visible in this Claude chat — right-click → "Save Image As" if you want to reuse them.

---

## Why this email is the right move

- Saurabh asked you to do something you physically can't do. Pretending otherwise wastes another round-trip.
- Three independent pieces of evidence (current page is read-only / Trust Hub list doesn't contain campaign / legacy pages 404) make it impossible for him to send you back to the same instruction.
- You give him a clean either/or: do it on your end, OR show me the URL. Doesn't let him punt vaguely again.
- Don't apologize, don't beg. State the facts, give the ask, stop typing.
