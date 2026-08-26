# Akash reply 2026-06-11 — escalation demand

**To:** existing ticket #27179042 thread (reply to Akash's 6/10 11:53 PM PDT / 6/11 2:53 AM ET message)
**Subject:** keep auto-generated reply subject
**Attachments:** 3 screenshots (instructions below) + this reply

---

## Body — paste verbatim

Hi Akash,

Per your request, I've attached three screenshots from my Twilio Console:

1. **Screenshot 1** — Messaging Service `MG5841b1dd280260d8d5107a2467b1a3d2` ("Low Volume Mixed A2P Messaging Service"), Compliance tab, showing the 2FA Campaign in "Failed" status.

2. **Screenshot 2** — Messaging Service `MG58c4c25a365e158067a5875b6488bad8` ("Milton Recovery Marketing & Alumni Invites"), Compliance tab, showing the Marketing Campaign in "Failed" status.

3. **Screenshot 3** — Trust Hub > Compliance Registrations page, showing that **no A2P 10DLC Campaigns appear in the unified registrations list** (only my SHAKEN/STIR voice registration `BU2e39fec3b210973b8fea346689a2f12d` is listed there).

For context: the Twilio One Console does not surface an aggregate list of A2P 10DLC Campaigns. Each Campaign is only viewable from inside its parent Messaging Service's Compliance tab, which is what I've captured. Neither of those views exposes any vetter rationale beyond the binary "Failed" status — which is exactly the gap I've been asking your team to bridge.

To restate the actual ask, since I've now sent it on 5/31, 6/8, and 6/10 across three messages on this ticket and we are still not closer to a resolution:

**I need the TCR vetter's free-text rationale for each rejection error code on each Campaign:**

- **2FA Campaign** (`QE2c6890da8086d771620e9b13fadeba0b` on `MG5841...`) — error codes 30909 (CTA verification), 30908 (Privacy Policy verification), 30882 (Terms and Conditions).
- **Marketing Campaign** (`QE2c6890da8086d771620e9b13fadeba0b` on `MG58c4...`) — error codes 30882, 30909, 30908, plus 30886 (Invalid campaign description).

These are TCR vetter notes that are not visible to me in the Console or via the public REST API. They are visible to Twilio's Trust Hub Compliance team in your internal tooling.

**Given the 12-day cycle of clarifying questions and no progress toward the vetter notes, I'd like to formally request escalation of this ticket to a senior Trust Hub Compliance engineer or your Trust & Safety vetting team — whoever has read access to the TCR vetter rationale notes for failed A2P 10DLC Campaigns.** This Campaign approval is the last item gating the public launch of an iOS app for a substance use disorder recovery community, and a continued sequence of basic clarifying questions from your end is not a path to resolution.

For convenience, I'll re-attach a summary of what's already on the ticket so the escalation contact has everything in one place:

- Twilio Account SID: `AC3ad114d4769975de61f426a49e52a2de`
- Brand SID: `BN4bb2811c5d19f19ae546b65b4c296cc6` (approved)
- 2FA Campaign Resource SID: `QE2c6890da8086d771620e9b13fadeba0b` on Messaging Service `MG5841b1dd280260d8d5107a2467b1a3d2`
- Marketing Campaign Resource SID: `QE2c6890da8086d771620e9b13fadeba0b` on Messaging Service `MG58c4c25a365e158067a5875b6488bad8`
- Both Campaign records can be pulled by your team via:
  ```
  GET https://messaging.twilio.com/v1/Services/MG5841b1dd280260d8d5107a2467b1a3d2/Compliance/Usa2p
  GET https://messaging.twilio.com/v1/Services/MG58c4c25a365e158067a5875b6488bad8/Compliance/Usa2p
  ```
- Privacy policy live at https://miltonrecovery.com/milton-nation-privacy/ — HTTP 200, contains every standard TCR-required disclosure including the CTIA "mobile information not shared with third parties for marketing or promotional purposes" clause.
- Terms of Use live at https://miltonrecovery.com/app-terms-of-use/ — HTTP 200, contains a dedicated "SMS Messaging Program — Opt-Out and Help" section with Reply STOP, Reply HELP, message frequency, and carrier disclaimer added 2026-06-10.

Please assign and CC me on the handoff. Happy to jump on a call with the engineer who picks this up.

Thank you,
Ezra Barishansky
ebarish@miltonhealthgroup.com

---

## How to take the 3 screenshots (instructions for Ezra)

These should take ~5 minutes total. Sign in to Twilio first.

### Sign in
1. Open Chrome → `https://console.twilio.com/`
2. Sign in with your normal Twilio credentials

### Screenshot 1 — 2FA Campaign compliance page
1. Navigate to: `https://1console.twilio.com/account/AC3ad114d4769975de61f426a49e52a2de/us1/messaging/messaging-services/MG5841b1dd280260d8d5107a2467b1a3d2/compliance`
2. Wait for page to fully load
3. Scroll down so the "10DLC" panel is visible with "Campaign status: Failed" and the "Campaign use case: 2FA" text both showing
4. Cmd+Shift+4 → drag a box around the 10DLC panel
5. Screenshot saves to Desktop
6. Rename: `twilio-2fa-campaign-failed.png`

### Screenshot 2 — Marketing Campaign compliance page
1. Navigate to: `https://1console.twilio.com/account/AC3ad114d4769975de61f426a49e52a2de/us1/messaging/messaging-services/MG58c4c25a365e158067a5875b6488bad8/compliance`
2. Same scroll/screenshot procedure
3. Rename: `twilio-marketing-campaign-failed.png`

### Screenshot 3 — Trust Hub Compliance Registrations (no A2P visible)
1. Navigate to: `https://1console.twilio.com/account/AC3ad114d4769975de61f426a49e52a2de/us1/trusthub/compliance-registrations`
2. Wait for page to fully load
3. Cmd+Shift+4 → drag a box around the registrations table (the part that shows only "app milton / BU... SHAKEN/STIR / Approved" with no A2P 10DLC rows)
4. Rename: `twilio-trust-hub-no-a2p.png`

### Send the email
1. Open Outlook → reply to the Twilio Support 2:53 AM email
2. Drag all 3 PNGs from Desktop into the email body
3. Paste the email body above
4. Send

---

## Why this email is different from the prior two

- Opens with full cooperation (the 3 screenshots he asked for) so we can't be accused of dodging the basic request
- Uses the screenshots themselves as the closing argument for escalation — they prove the Console doesn't have what we need
- Makes the explicit escalation ask with a specific destination ("senior Trust Hub Compliance engineer or your Trust & Safety vetting team")
- Reframes the timeline: "12-day cycle" puts pressure without sounding hostile
- Names the business risk: "iOS app for a substance use disorder recovery community" makes the consumer impact concrete
- Consolidates all known facts into one paragraph so the escalation engineer has zero context to gather