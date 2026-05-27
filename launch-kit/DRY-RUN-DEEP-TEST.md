# Dry-Run Deep Test — Build 10 (Pre-Twilio)

**When to run:** RIGHT NOW, while waiting on Saurabh @ Twilio Trust & Safety
(ticket #27179042) to approve A2P 10DLC Campaign.

**Why this exists:** The full `DEEP-TEST-SEQUENCE.md` runs after Twilio
approval. But ~80% of its 17 surfaces don't depend on real SMS delivery.
Knock those out NOW on Build 10 TestFlight so when Twilio greenlights,
the remaining work is just the 4 SMS surfaces + a final pass — not 4–6
hours from scratch.

**Estimated time:** 2.5–3 hours single session, or split into two.

**Device:** Your real iPhone with Build 10 already installed via TestFlight.

---

## Pre-flight

- [ ] Confirm Build 10 installed: Settings → About should show `1.0 (10)`
- [ ] `DEMO_BYPASS_ENABLED = true` is set on Supabase Edge Function secrets
      (it is — set 2026-05-25 15:40 UTC)
- [ ] Have a second device or simulator for cross-user tests (chat, admin approve)
- [ ] Notes app open for the bug log (template at the bottom of this doc)

### Accounts to sign in with (NO REAL SMS — these all use demo bypass or email-only paths)

| Account | Role | Use for |
|---|---|---|
| `appreviewer@miltonrecovery.com` / `Milton2026!` + OTP `000000` | Alumni (FL, demo) | Primary alumni testing, all of Surfaces 2–7, 11–14 |
| `admin@miltonrecovery.com` / `Milton2026!` | FL admin | Surface 8 (Admin Panel) |
| `admin@miltonjefferson.com` / `Milton2026!` | OH admin | Surface 8 + facility isolation |
| `super-demo@miltonrecovery.com` / `Milton2026!` | Super admin | Surface 9 |
| `case-manager-demo@miltonrecovery.com` / `Milton2026!` | Case manager | Surface 10 |
| `therapist-demo@miltonrecovery.com` / `Milton2026!` | Therapist | Surface 10 |

---

## What to SKIP today (defer until Twilio approves)

| Skip | Why |
|---|---|
| Surface 1A (New User Signup — REAL phone) | Requires real SMS delivery |
| Surface 1C (Ohio signup — REAL phone) | Requires real SMS delivery |
| Surface 1F (Returning user login) | Requires real SMS OTP |
| Surface 1G (OTP rate limiting) | Requires real SMS |
| Surface 1H (OTP expiry) | Requires real SMS |
| Surface 1I (Multi-device login) | Requires real SMS |
| Surface 11B (Phone number change) | Requires real SMS to new number |
| Surface 15 (entire — Twilio SMS surfaces) | All 4 are SMS by definition |

Everything else is in scope.

---

## What to RUN today

For each surface below, open `DEEP-TEST-SEQUENCE.md` to the referenced
section and check off boxes there as you go. This doc is the checklist
of *which* sections to run.

### Surface 1: Auth & Onboarding — partial
- [ ] **1B** Admin Approves New Signup (use FL admin; approve any seeded pending or a manually created row)
- [ ] **1D** Rejection flow (admin rejects → user sees rejection)
- [ ] **1E** Demo Bypass Signup — sign up using `+15550001234`, OTP `000000`. Verify NO real SMS fires, profile auto-completes.

### Surface 2: Profile — all
- [ ] 2A, 2B, 2C, 2D, 2E

### Surface 3: Community Feed — all (this is the BIG one — content safety engine)
- [ ] 3A, 3B, 3C
- [ ] **3D** Medium-risk flagged content
- [ ] **3E** Crisis content — verify all 6 resources, all dial correctly
- [ ] **3F** Negation downgrade (false positive avoidance)
- [ ] **3G** Time-immediacy elevation (just-shipped feature in commit d904e8e — extra scrutiny)
- [ ] **3H** Each of 6 categories (self-harm, drugs, alcohol, violence, eating disorder, DV)
- [ ] **3I** Emergency help-seeking
- [ ] 3J, 3K, 3L, 3M, 3N

### Surface 4: Chat — all
- [ ] 4A, 4B, 4C, 4D, 4E (if voice notes implemented), 4F, 4G, 4H

### Surface 5: Meetings — all
- [ ] 5A, 5B, 5C, 5D, 5E

### Surface 6: Crisis Flow — all (validates the dial-out integrations)
- [ ] 6A, 6B (every single phone number — confirm dialer opens with correct digits), 6C

### Surface 7: Notifications — all (push, not SMS)
- [ ] 7A, 7B (all 3 app states × all 6 notification types = 18 cells)
- [ ] 7C, 7D
- [ ] ⚠️ If push doesn't fire at all → APNs .p8 key issue (see task #5 below)

### Surface 8: Admin Panel — all
- [ ] 8A through 8I
- [ ] Special attention to **8H facility isolation** (must work or it's an Apple HIPAA risk)

### Surface 9: Super Admin — all
- [ ] 9A, 9B, 9C

### Surface 10: Care Team — all
- [ ] 10A, 10B, 10C, 10D

### Surface 11: Settings — all except 11B
- [ ] 11A
- [ ] 11C, 11D, 11E, 11F, 11G, 11H, 11I

### Surface 12: Edge Cases & Resilience — all
- [ ] 12A through 12I
- [ ] 12B screenshot protection is an Apple HIPAA review item — verify

### Surface 13: Accessibility & Layout — all
- [ ] 13A, 13B, 13C, 13D, 13E

### Surface 14: Performance — all
- [ ] 14A, 14B, 14C, 14D

### Surface 16: Audit Trail
- [ ] 16A — query Supabase `audit_logs` after running tests; verify every
      admin action, sign-in, content flag, account event left a row

### Surface 17: Build & Distribution
- [ ] 17A — confirm Build 10 install works fresh on a wiped device if available

---

## Bug log template (use notes app)

```
[SURFACE-#] [Severity] One-line description
  Repro:
    1.
    2.
    3.
  Observed:
  Expected:
  Device: iPhone X, iOS Y
  Build: 10
```

**Severity tiers:**
- 🔴 Showstopper — blocks core flow, or HIPAA risk → MUST fix before Build 11 archive
- 🟡 P1 — works around possible, but degraded
- 🟢 Polish — visual / microcopy / minor UX → defer to 1.1

---

## Sign-off — when this dry-run is done

- [ ] All non-Twilio surfaces tested
- [ ] Bug log triaged
- [ ] 0 🔴 Showstoppers open
- [ ] All 🔴 found are either fixed in source (commit) or in progress
- [ ] 🟡 P1s logged in `launch-kit/KNOWN-ISSUES-BUILD-11.md` (create if needed)
- [ ] 🟢 Polish items logged in same file under "1.1 backlog"

**Once signed off → wait for Twilio approval → run Surface 15 (4 SMS surfaces) + Surface 1A/1C/1F/1G/1H/1I + Surface 11B → final UI review → archive Build 11 → resubmit Apple.**
