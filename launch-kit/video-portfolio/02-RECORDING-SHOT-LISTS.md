# Milton Nation — Screen Recording Shot Lists (click-by-click)

Every clip you need for the whole video slate, with exact taps. Follow top to bottom; check clips off as you record. Clips map to the `Visual` column in `03-VIDEO-SCRIPTS.md`.

---

## Part 0 — Setup (do this once, ~10 minutes)

### ⚠️ Why you can't just record your iPhone

The app **intentionally blocks screen capture on real devices** — a HIPAA feature (`ScreenshotProtection.swift`). The moment iOS starts recording (Control Center recording, AirPlay, or QuickTime-over-USB), the app covers itself with a black "Screen Recording Blocked" screen. **This applies to all builds.** Don't fight it — it's protecting your users, and it's a great fact to brag about in the ads.

**The workaround is the iOS Simulator on your Mac.** macOS records its own screen, so the simulated iPhone never knows — no black screen, pixel-perfect footage, and (in DEBUG) 100% mock data, so zero PHI risk. This is how the pros do it anyway.

### Capture Path A — DEBUG + mock data (use this for ~90% of clips)

1. Open `Milton Nation Alumni App.xcodeproj` in Xcode.
2. Device selector (top bar) → **iPhone 16 Pro** simulator.
3. Press **⌘R**. DEBUG is the default — the app runs on built-in mock data (fake people: Alex Demo, Dana Case, Dr. Robin Nova). No internet needed, nothing real on screen.
4. **Mock logins** (any password, any 6-digit code, e.g. `000000`):

| Login as | Email |
|---|---|
| Alumni ("Alex Demo", ~4-year streak) | any email, e.g. `alex@demo.com` |
| Florida Admin | `admin@milton.com` |
| Super Admin | `super@milton.com` |
| Therapist ("Dr. Robin Nova") | `therapist@milton.com` |
| Case Manager ("Dana Case") | `case@milton.com` |
| Counselor ("Casey Guide") | `counselor@milton.com` |

*(The three staff logins are new — added on this branch. Pull the latest `claude/app-launch-video-portfolio-p00gsx` before recording, or merge the PR.)*

### Capture Path B — Release config + real seeded demo data (only if a mock screen looks empty)

Mock data is curated but finite. If a screen you need looks empty in DEBUG (e.g. pending approvals, Ohio content, telehealth sessions), switch to the real backend's **seeded demo accounts**:

1. Xcode → **Product → Scheme → Edit Scheme… → Run → Build Configuration → Release** → run in the same simulator.
2. Sign in with the Build-16 demo accounts — password `Milton2026!`, code `000000` (works while `DEMO_BYPASS_ENABLED` is still on; flip it back on temporarily if it's been disabled): `appreviewer@miltonrecovery.com` (FL alumni, ~90 days), `new.chapter.oh@miltondemo.seed` (OH alumni), `admin@miltonrecovery.com` (FL admin), `admin@miltonjefferson.com` (OH admin), `super-demo@miltonrecovery.com`, `case-manager-demo@miltonrecovery.com`, `therapist-demo@miltonrecovery.com`.
3. If demo content was already wiped, re-seed with `launch-kit/PHASE-4-RESEED-DEMO-CONTENT.sql`, record, then wipe again with `launch-kit/CLEANUP-DEMO-CONTENT.sql`. **Set Build Configuration back to Debug when done.**

### Make it look like an ad, not a dev box

Run these in Terminal after the simulator boots (Apple's classic 9:41, full bars, no carrier):

```bash
xcrun simctl status_bar booted override --time "9:41" --batteryState charged --batteryLevel 100 --cellularBars 4 --wifiBars 3 --operatorName ""
```

To undo later: `xcrun simctl status_bar booted clear`

### Recording

- **Best:** `xcrun simctl io booted recordVideo --codec h264 "MN-IOS-ALUM-02-home.mov"` → do the taps → **Ctrl-C** to stop. Native device resolution, no window chrome.
- Also fine: Simulator menu **File → Record Screen** (⌘R), or **⌘⇧5** and drag over the phone.
- **Dark mode variants:** Simulator menu Features → Toggle Appearance (**⌘⇧A**) — or better, use the in-app control (Profile → Settings → Appearance → Dark) so the re-theme itself is footage.
- Keep the pointer slow and deliberate. Pause ~1.5s on anything the VO talks about. Overshoot each clip a few seconds — editors trim, they can't extend.
- Portrait only. One flow per file, named exactly as below.

### House rules for every take

- Demo data only — never a real account, never your personal phone number on screen.
- The greeting shows a lowercased first name ("Welcome back, alex") — that's by design; fine on video.
- Don't linger on the Invite Alumni info line (it says "SMS" but sends email — a known copy nit).
- Skip: Contacts screen and Edit Journey sheet (unreachable in this build), the radius "control" (there isn't one — it's fixed at 10 miles).
- The **SobrietyCheckModal appears after every alumni login and cannot be swiped away** — either make it the shot (it's beautiful) or calmly tap "Yes, still going strong!" before your real shot.

---

## Part 1 — ALUMNI clips (log in as `alex@demo.com`, Path A)

**ALUM-01 · Login** — from a fresh launch: tap **Email** → type `alex@demo.com` → tap **Password** → type anything → tap **Login** → on "Two-Factor Authentication," type `000000` → tap **Verify**. Capture the logo + tagline "Driven by purpose. Committed to care." for 2s before typing.

**ALUM-01b · Sobriety check (the emotional opener)** — the "Welcome Back!" modal appears right after login: hold on "Are you still on track?" + the day count → tap **"Yes, still going strong!"**. Also record one take tapping **"I need to reset my date"** to show the compassionate reset copy ("There's no shame in starting over…") → then **Cancel**.

**ALUM-02 · Home top** — slow-scroll Home from the top: greeting → **sobriety card** (huge day number, weeks/months/years row). Hold 3s on the number.

**ALUM-03 · Reflection + badges + news** — continue scrolling: **Daily Reflection** card (hold), **Points & Badges**, **Updates & News** → tap an announcement row to expand → collapse.

**ALUM-04 · Community** — Community tab: scroll 3–4 posts → tap chip **🎉 Wins** → tap a **heart** (capture the count tick) → tap the **💬 bubble** on a post to expand comments → type "So proud of you 🙌" → send. Then tap **+ Post** → pick **🙏 Gratitude** → type "90 days today. Grateful for this community." → tap **Submit Post** → hold on the success alert → watch it land at the top of the feed.

**ALUM-05 · Chat** — Chat tab: show "Your Care Team" list → open **Dana Case** → scroll messages → type "Thanks for checking in 🙏" → send (capture the teal bubble landing). Keep the red **"Need immediate help? Call 988"** footer in frame for a beat.

**ALUM-06 · Meetings** — Meetings tab, **Milton** segment: scroll cards → tap a meeting → detail sheet (hold on date/address) → tap **RSVP for In-Person** → "You're RSVP'd!" → **Done**. Then tap **Nearby** segment: allow location → map with pins → scroll the AA/NA cards → tap one → **Directions** (cancel the dialog).

**ALUM-07 · I'm Struggling (film with respect — slow, no fast cuts)** — Home → scroll to the bottom → tap **"I'm struggling today"** → hold on "You're Not Alone" + the 988 / SAMHSA / Crisis Text rows (do NOT tap-through to the dialer) → toggle **"Notify your care team"** → "Team Notified" → OK → tap **"Enter Struggle Mode"** → tap Home, Community, Meetings tabs to show the locked screen ("You're in Struggle Mode") → tap **"Chat with Your Care Team"** → back → **"Exit Struggle Mode"** → **Exit**.

**ALUM-08 · Profile & badges** — Profile tab: avatar/name/@username → **Points & Badges** grid → tap an earned badge (detail sheet: "Earned") → close → "How to Earn Badges" card → **My Posts**.

**ALUM-09 · Settings + dark mode** — Profile → **Settings**: toggle **"Require Face ID to Open"** → Appearance → tap **Dark** (hold while the whole app re-themes — great beat) → tap **Light** back, or keep Dark and re-record ALUM-02/04 for dark-mode variants.

**ALUM-10 · Register + pending (for O-1 and A-videos)** — log out → **Register**: fill the form slowly enough to read (fake data!), show the 🌴/🌻 **"Your Facility"** selector, tick the consent checkbox, tap **Register** → "Registration Submitted" → capture the **"Application Under Review"** pending screen (logo, the three steps, "usually happens within 24 hours").

**ALUM-11 (Path B, Ohio alumni) · My Sessions** — as `new.chapter.oh@miltondemo.seed`: Meetings tab → **My Sessions** segment → **"Request a session"** → pick provider/type/time → **Request** → "Request sent" alert. (Telehealth is Ohio-only.)

---

## Part 2 — STAFF clips (therapist / case manager / counselor)

Record the full set once as `therapist@milton.com`, then re-record clips 01+02 as `case@milton.com` and `counselor@milton.com` so each role's onboarding video opens with its own login. Staff tabs: **Clients · Care Tools · (Schedule) · Community · Profile**.

**STAFF-01 · Staff login** — same login flow; capture landing on **"My Clients"** with the caseload count.

**STAFF-02 · Caseload → secure chat** — Clients tab: rows with last-message previews + unread badges → tap **Alex Demo** → the care-team conversation → send "How are you feeling after group yesterday?" — capture send.

**STAFF-03 · Care Tools** — Care Tools tab: hold on the header (role badge + facility pill) + stats row → expand **Sobriety Tracking** (color-coded day counts; search "alex") → collapse → expand **Content Flags** (filter chips All/Pending/Escalated…; hold on a flag card's risk badge — summaries are redacted by design, say so in VO) → **Community Moderation** briefly.

**STAFF-04 · Care Team Alerts** — Care Tools → **"Care Team Alerts"** card → alert card ("Requested care team support") → tap **"Open chat"** → send "I'm here. Want to talk?" (If no alert exists in mock: trigger one first — as alumni, I'm Struggling → "Notify your care team" — or use Path B.)

**STAFF-05 · Schedule console (telehealth)** — log in as `super@milton.com` (telehealth always on for super admins; in prod it's Ohio-only) → **"Session Requests & Schedule"** → REQUESTS TO CONFIRM / YOUR AGENDA / PAST → **"Schedule a session"** → pick client, type, duration → show the **"Video — Microsoft Teams"** link field → **Schedule**.

---

## Part 3 — ADMIN clips (log in as `admin@milton.com`)

Admins get no tab bar — straight into the dashboard.

**ADMIN-01 · Dashboard hero** — capture landing: logo header with **User View** + **Logout**, "Admin Dashboard" + "Welcome back, …" + role badge + 🌴 facility pill → the 4 stat cards → slow-scroll the section grid (9 sections).

**ADMIN-02 · Approve a member** — expand **Pending Approvals** → applicant card (PENDING pill, program, days sober) → tap **🌴 Florida** on "ASSIGN TO FACILITY" → tap **Approve** → capture the list updating. (Empty in mock? Register a fresh account as in ALUM-10 first, or Path B which has 3 seeded applicants.)

**ADMIN-03 · Invite** — expand **Invite Alumni** → type a name + `newalum@example.com` → tap **Send Invite** → success row. (Frame the fields, not the info caption.)

**ADMIN-04 · Moderation + flags** — expand **Community Moderation** → approve a pending post. Expand **Content Flags** → filter **Pending** → open a flag → "Review Flag" sheet → **Mark Reviewed**. If an EMERGENCY banner is present, hold on it — respectfully.

**ADMIN-05 · Announcement → alumni home (the magic cut)** — expand **Announcements** → **+ New** → Title: "Alumni BBQ — Saturday 2pm" · Body: "Bring your people. Food's on us." → **Save**. Then tap **User View** → Home → **Updates & News** shows it live → tap the floating **"Back to Admin"** pill. One unbroken take if you can — it's the best admin shot we have.

**ADMIN-06 · Meetings management** — expand **Meeting Management** (or Meetings via User View): toolbar **+** → "New Meeting" sheet: title, type, facility visibility, recurrence toggle → **Save** → the new card in the list.

**ADMIN-07 · Chat monitoring + sobriety tracking** — expand **Chat Monitoring** (hold briefly) and **Sobriety Tracking** (search, color-coded counts, RESET flags). B-roll for the "accountability" beats.

---

## Part 4 — SUPER ADMIN clips (log in as `super@milton.com`)

**SUPER-01 · Two states, one login** — right after Verify, the **"Select Facility"** sheet auto-appears (🌴 Florida / 🌻 Ohio cards) → tap **Florida** → dashboard loads → tap the **🌴 pill** in the header → tap **Ohio** → capture the whole dashboard re-scoping. This is THE super-admin money shot.

**SUPER-02 · User management** — expand **User Management** → scroll members (role badges) → tap a member → **"Member Details"** sheet (CONTACT / RECOVERY / ACCOUNT) → **Promote User** → hold on the "Promote to Admin / Promote to Super Admin" alert → **Cancel** (don't actually promote in Path B!).

**SUPER-03 · Audit log** — expand **Audit Log** → slow-scroll entries. (VO: "every privileged action, logged.")

**SUPER-04 · Cross-facility announcement** — as ADMIN-05, but note in VO it reaches both facilities. Also grab **Staff Assignments**, **Gamification**, **Emergency Access** expands as b-roll.

---

## Part 5 — Stills (screenshots) while you're in there

Screenshots from the simulator: **⌘S** saves a PNG to the Desktop at full resolution. Grab light + dark of each: login screen, Home top (streak card), Daily Reflection, Community feed (Wins filtered), create-post sheet, chat thread (988 footer visible), Meetings Milton + Nearby map, I'm Struggling modal, Struggle Mode locked screen, badge grid + badge detail, pending-approval screen, admin dashboard hero, pending-approvals card, announcements, facility picker, audit log. These feed static ads, App Store shots (6.9" + 6.1" come from iPhone 16 Pro Max + iPhone 16 sims), thumbnails, and Higgsfield image-to-video shots.

---

## Part 6 — Android 🚨 read this

**There is no Android app in this codebase — Milton Nation is iOS/SwiftUI only.** So there is no Android screen to record today, and we should never fake one (mock Android chrome around iOS footage reads as deceptive, and Google requires real screenshots for a Play listing anyway).

The Android portfolio strategy until an Android build exists:

1. Every script in `03-VIDEO-SCRIPTS.md` is platform-neutral except the end-card. Produce everything now with the **App Store** end-card.
2. For Android-audience placements, use the alternate end-card: **"iOS today · Android coming soon"** with an email/SMS notify-me line — that's an honest ad and it builds a warm Android waitlist.
3. The announcement videos (A-1, A-2) barely show device chrome — they work for both audiences as-is.
4. The moment an Android build exists, this same shot list transfers 1:1 (record via Android Studio emulator + `adb` or scrcpy; the flows and scripts stay identical) — swap end-cards, re-export, done.

If an Android build DOES exist somewhere outside this repo — tell Claude where, and this section gets replaced with a real Android capture path.
