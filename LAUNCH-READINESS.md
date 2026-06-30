# Launch Readiness — Milton Nation (single source of truth)

**Goal:** App Store live → 10 clients + staff + alumni onboarded and using it well, safely.
**Last updated:** 2026-06-22 · **Overall: ~58%** (build ahead; compliance-activation + crisis-ops are the lagging half).

Legend: ✅ done · 🟡 in progress · ❌ not started · ❓ needs confirm · 🔴 gate (blocks real patients)

---

## Scorecard

| Category | % | State |
|---|---|---|
| Twilio / SMS | 100 ✅ | Migrated to Verify, tested, cleaned up, closed. |
| Database security / RLS | 80 ✅ | RLS verified ON for every table + policies. Facility-isolation logic untested. |
| Technical / Build | 75 🟡 | Build 12 live; logo fixed; **report/block to build**; push untested; live audit incomplete. |
| HIPAA / Legal / Compliance | 55 🟡 | Privacy+Terms LIVE; signed authorization; specs done. **BAA not active**; consent gate missing; clinical sig pending. |
| App Store Submission | 52 🟡 | Copy/demo/runbook ready; export-compliance set. Needs clean screenshots, privacy label, report/block, submit. |
| Production Go-Live Config | 45 🟡 | Backend live; **DEMO_BYPASS still ON**; real data/accounts/monitoring TBD. |
| Onboarding & Operations | 32 ❌ | Email invite exists, untested; no staff training/pilot. |
| Crisis & Clinical Safety Workflow | 25 🔴 | App features exist; **human response protocol undefined.** Lowest + highest stakes. |
| Marketing / Comms | 38 🟡 | Promo brief handed off; brand kit + copy bank ready. |

---

## ✅ Done by Claude this session (verified)
- Twilio A2P → **Twilio Verify** migration (deployed, tested live, committed `b72317d`).
- Killed dead 2FA campaign, released number `+1 717-971-3757`, deleted 2FA messaging service.
- **Logo swatch-bar removed** — `milton_logo.png` + `_dark.png` cropped 2000×2000 → 2000×1320, verified clean. (Ships in Build 13.)
- Verified: RLS on all tables ✅ · Privacy + Terms URLs live (200) ✅ · account delete + export present ✅ · export-compliance key set in Release.xcconfig ✅.
- Refreshed audit checklist Section G for Verify; wrote `PROMO-BRIEF.md`.
- **`blocked_users` table created + RLS, applied to prod** (block-list backing for Apple 1.2).
- **Push-PHI fix:** removed the applicant's name from the new-member admin APNs push (`SupabaseAuthService`) — payloads now carry no member names. *(Note: the "I'm Struggling" notification is a local on-device notification to the user themselves — not a leak — left as-is.)*
- Wrote **`launch-kit/APP-STORE-SUBMISSION-PACKET.md`** (App Privacy answers + reviewer notes + pre-submit gate).

---

## Remaining work — by owner

### 🤖 Claude can build (no human needed) — IN QUEUE
1. **❌🔴 Report content + Block user** (Apple 1.2 — UGC apps rejected without these). DB is ready (`blocked_users` ✅). Remaining is **Swift only** — full turnkey spec at the bottom of this file. **Build WITH the test loop** (user-facing safety code — must be runtime-tested, not blind-committed to the launch branch).
2. **❌ Consent / EULA acceptance gate** at first login/registration (Apple UGC + HIPAA). Currently only a terms *link*, no acceptance.
3. **❓ Push payload PHI check** — confirm `send-push-notification` alert bodies contain no PHI (no post content / health detail / program name); genericize if needed.
4. **App Store metadata packet** — assemble privacy "nutrition label" answers + reviewer notes from existing specs.

### 🧑 Ezra — click-by-click (only you can do these)

**A. Re-archive Build 13** (after Claude finishes #1–#3 above)
1. Xcode → Product → Archive (Release).
2. Organizer → Distribute App → App Store Connect → Upload → Automatically manage signing → Upload.

**B. Re-shoot App Store screenshots** (off Build 13)
1. Sign in as **Alex Demo** (`appreviewer@miltonrecovery.com` / `000000`) — NOT admin, NOT user-view.
2. Capture: Home, Create Post, Sobriety tracker, "I'm Struggling" sheet, Meetings, Chat, Profile, Community.
3. Replace the April set in iCloud `…/AppStoreScreenshots/`.

**C. App Store Connect listing**
1. appstoreconnect.apple.com → Apps → Milton Nation.
2. Fill listing from `launch-kit/04-app-store-connect-content.md`; upload screenshots + icon.
3. App Privacy → complete the data-collection questionnaire (Claude will draft answers).
4. Add reviewer notes + demo account (`appreviewer` / `000000`).
5. Select Build 13 → **Submit for Review** — ONLY when audit = 0 showstoppers.

**D. Activate Supabase HIPAA add-on** 🔴 (the load-bearing BAA)
1. supabase.com/dashboard → project `hksxzuytcmqqwxmfjzdp` → Settings → Add-ons (or Organization → Billing).
2. Enable **HIPAA** add-on; complete/sign the BAA.

**E. Production go-live flips** (after Apple approves, BEFORE real patients) 🔴
1. Flip `DEMO_BYPASS_ENABLED=false` (Claude runs this on your word).
2. Seed real meetings, announcements, facility config; create real FL/OH staff + admin accounts.

**F. Run the device audit** — `launch-kit/MASTER-AUDIT-CHECKLIST.md` on Build 13 (Claude drives). Gating items: A4 create-post, A6 crisis detection.

### 🩺 Clinical director / Milton Health Group
1. **🔴 Sign Section 9** of `launch-kit/MEMO-FOR-CLINICAL-DIRECTOR.md` (HIPAA sign-off).
2. **🔴 Approve the crisis-response protocol** (skeleton below) + assign coverage staffing.
3. Confirm crisis resource phone numbers (988, SAMHSA, Milton FL/OH lines) are correct + monitored.

---

## 🔴 Crisis-Response Protocol — SKELETON (clinical to complete before any patient)

> The app detects crisis content and shows resources. This defines what **humans** do. Cannot launch to patients without this filled in and approved.

- **Trigger:** a post is flagged `flagged_for_crisis` OR a user taps "I'm Struggling."
- **Who is alerted:** ____ (care team role) via push + admin Content Flags queue.
- **Response SLA:** within ____ minutes during ____ hours.
- **After-hours / no-coverage:** in-app message must state hours + direct to 988/911. (Add disclaimer: "not monitored 24/7 / not emergency services.")
- **Escalation:** if imminent risk → ____ (call patient / emergency contact / 911 per clinical policy).
- **Documentation:** logged in `emergency_access_log` / `content_flags`; clinical follow-up by ____.
- **Owner / sign-off:** ____ (clinical director), date ____.

---

## Critical path to "patients on app"
**Code track (Claude + Ezra):** build report/block + consent → push verified → Build 13 → clean screenshots → device audit 0-showstoppers → submit → Apple review.
**Compliance/ops track (Ezra + clinical, parallel):** clinical sign-off → activate Supabase BAA → **crisis-response protocol approved** → staff training → pilot cohort.

**The true gate to a real patient (not the App Store checkmark):** ① Supabase BAA active · ② `DEMO_BYPASS` off · ③ human crisis-response protocol live. Do not onboard a patient until all three are true.

---

## 🛠 Turnkey build-spec — Report / Block / Consent (build WITH the test loop)

**DB:** `blocked_users(blocker_id, blocked_id)` ✅ applied to prod (RLS: own-rows only).

**Report** (reuse the existing flag → admin-queue pipeline; no new admin UI):
- Add `reportPost(postId:reason:)` / `reportComment(commentId:reason:)` to `ContentFilterService` → invoke `flag-content` with `{ feature: "user_report", riskLevel: "low_risk", categories: ["user_reported"], redactedSummary: "user_report:post:<uuid>" }`. Routes to the existing Content Flags admin queue.
- UI: `Menu`/`confirmationDialog` ("Report post", "Block user") in `PostCard` header (near the `Spacer()` ~line 76) + each `commentRow` + `PostDetailScreen`. Hide on the user's own content (`post.userId == currentUserId`).

**Block** (client-side filter — safest, no query surgery):
- Service: `blockUser(_:)`, `unblockUser(_:)`, `fetchBlockedUserIds() -> Set<UUID>`.
- Filter: in `fetchPosts` (after ~line 277) and `fetchComments` (after ~397), drop rows where `userId ∈ blockedIds`; same for `fetchConversations`/`fetchMessages`. Cache the set per session; refresh on block/unblock.
- UI: "Block user" action (same menus) + **Settings → Blocked Users** screen with Unblock.

**Consent gate** (low-risk):
- `LoginScreen` already has a `registrationForm`. Add a required "I agree to the Terms of Use & Privacy Policy" toggle (tappable links to the live URLs) gating the Register button.

**Ezra's part (the test):** on Build 13 — report reaches the admin queue · blocked user's posts/comments/messages disappear · unblock restores · consent doesn't lock anyone out. Then Apple 1.2 is satisfied.

