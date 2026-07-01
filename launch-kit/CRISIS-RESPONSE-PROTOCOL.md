# Crisis-Response Protocol — Milton Nation (DEFAULT DRAFT for clinical review)

**Status:** DRAFT for the Clinical Director to review, adjust, and sign. This is a sensible default written by the build team — **not** final clinical guidance. Everything marked **[SET BY CLINICAL]** must be decided by qualified clinical staff. **The app cannot onboard real patients until this is completed and signed (Section 6).**

---

## 1. What this app is (and isn't) — the safety framing
Milton Nation is a **peer-support + resource-navigation** app for recovery alumni. It is **NOT** an emergency service, a crisis hotline, or a 24/7-monitored clinical system. This must be stated to users **in-app** (onboarding + the crisis sheet):

> *"Milton Nation is a peer-support community, not an emergency service, and is not monitored 24/7. If you are in danger or crisis right now, call or text **988** (Suicide & Crisis Lifeline) or **911**."*

## 2. What the app already does automatically
- Scans posts/messages for crisis content → holds the post and creates a **content flag** (`content_flags`, risk level low/medium/high).
- Shows the in-app **crisis resources sheet** (988, Crisis Text Line 741741, SAMHSA, Milton FL/OH lines, 911).
- On flag: sends a **push to all admins + super-admins** and drops it in the **Content Flags admin queue**.
- "I'm Struggling" button surfaces resources + can notify the care team.

**This protocol defines what the HUMANS do next.**

## 3. Who responds (the human chain) — **[SET BY CLINICAL]**
| Role | Responsibility |
|---|---|
| **Primary responder** | **[SET: e.g., the alumnus's assigned case manager]** — reviews the flag, reaches out to the member. |
| **Backup responder** | **[SET: e.g., on-call therapist / facility admin]** — covers if primary is unavailable. |
| **Clinical escalation** | **[SET: Clinical Director or designee]** — decision-maker for imminent-risk situations. |
| **Facility routing** | FL flags → FL care team; OH flags → OH care team (the app already separates by facility). |

## 4. Response times + coverage hours — **[SET BY CLINICAL]**
- **Coverage hours:** **[SET: e.g., Mon–Fri 9:00am–5:00pm ET]**. The app is **NOT** monitored outside these hours.
- **Acknowledge a HIGH-risk flag within:** **[SET: e.g., 1 hour during coverage hours]**.
- **Acknowledge a medium/low flag within:** **[SET: e.g., 1 business day]**.
- **After-hours / no coverage:** the in-app crisis sheet (988/911) is the safety net; a human follows up **[SET: next business morning]**. The after-hours disclaimer in Section 1 must be visible so no one believes a human is watching in real time.

## 5. Escalation ladder — **[SET BY CLINICAL]**
1. **Low / medium risk:** responder checks in with the member via in-app care-team chat within the SLA; documents the contact.
2. **High risk (not imminent):** responder contacts the member directly **[SET: call / secure message]** and loops in clinical escalation.
3. **Imminent danger** (stated intent + means/plan, or "going to use/hurt myself tonight"): **[SET clinical action — e.g., attempt direct contact; if unreachable and risk is imminent, contact the member's emergency contact and/or initiate a welfare check via 911 per clinical judgment].** Clinical Director (or designee) owns this call.

## 6. Documentation + sign-off
- Every crisis response is logged: the app records the flag in `content_flags` and access in `emergency_access_log` / `audit_logs`; the responder documents clinical follow-up **[SET: in the member's treatment record]**.
- **Review cadence:** revisit this protocol **[SET: quarterly]**.

> **Clinical sign-off (required before launch):**
> I have reviewed and approved this crisis-response protocol.
> Name: ______________________  Title: ______________________
> Signature: ______________________  Date: ____________

## 7. Build-team to-do once clinical fills this in
- Add the after-hours/not-24-7 disclaimer to onboarding + the crisis sheet (Section 1 wording) — **Claude can implement in ~15 min once approved.**
- Confirm the crisis resource phone numbers in-app are current (988, SAMHSA 1-800-662-4357, Milton FL (844) 406-4325, Milton OH (740) 715-4673).
- Verify the flag → correct-facility care-team routing matches the roles set in Section 3.
