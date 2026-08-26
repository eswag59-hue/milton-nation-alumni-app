# Video Production Scope — Milton Nation Alumni App

**Purpose:** everything needed to brief, price, and manage an external video editor for the Milton Nation launch video package.

**How to use this file:**
- **Part 0–1** are for Ezra only. Read before you reply to him or pay anything.
- **Part 2–5** are the vendor-facing brief. Copy/paste those parts to him as-is.
- **Part 6–8** are pricing, timeline, and contract terms — Ezra only.

---

# PART 0 — Read this before you reply to him

Two things about this app change the shape of the whole job. Both need to be settled **before** he quotes, because they change what he's actually being paid to do.

## 0.1 🔴 He physically cannot record this app. Neither can you (yet).

The app blocks screen capture at the root view. `ScreenshotProtection.swift` attaches a `.screenshotProtected()` overlay to the entire app in `Milton_Nation_Alumni_AppApp.swift:302` — with **no DEBUG gate**, so it is active in *every* build, TestFlight included.

The moment a screen recording, AirPlay mirror, or QuickTime capture starts, the whole app turns into a black screen reading:

> 🔒 **Screen Recording Blocked**
> Milton Nation protects your health information from screen capture.

This is correct HIPAA behavior and should stay in the shipping app. But it means:

- Handing him a TestFlight build gets him **60 minutes of black video**.
- You screen-recording your own iPhone gets you **the same black video**.
- Every walkthrough video in this package is blocked until this is solved.

**Three ways out — pick one before he starts:**

| Option | How | Quality | Effort |
|---|---|---|---|
| **A. Capture build** (recommended) | Add a `MEDIA_CAPTURE` compile flag that skips `.screenshotProtected()`. Build to Simulator with mock data, record with `xcrun simctl io booted recordVideo`. Never ship that config. | Best — clean 60fps, exact device resolution, no glare/hands | ~30 min of dev work |
| **B. Second camera** | Physically film the phone screen with a real camera. | Poor — moiré, glare, reflections. Not "Apple-inspired." | Low |
| **C. Rebuild the UI in After Effects** | He recreates every screen as motion graphics from stills. | Excellent, most "premium" — but expensive and can drift from reality | High cost |

**Recommendation: Option A**, and it's mostly a one-line change. Say the word and I'll add the flag behind a build configuration that can never ship to the App Store. Option C is worth it *only* for the 60s hero video, where a real editor will want to rebuild the UI in AE anyway to get the cinematic feel you're asking for.

> ⚠️ Note: `simctl recordVideo` grabs the Simulator framebuffer below the level `UIScreen.isCaptured` reports, so it *may* already work without any code change. **Test that first — it could save the dev work.** Don't assume it; verify before promising him footage.

## 0.2 🔴 Do not give him app access. Not even the demo accounts.

He asked for "app/demo access." The answer is no, and this isn't paranoia:

- The demo logins in `EZRA-TEST-SCRIPT.md` (`super-demo@`, `admin@miltonrecovery.com`, etc.) authenticate against the **live production Supabase backend**. The seeded *content* is fake; the *access* is real.
- `super-demo@` sees **both facilities**, User Management, Emergency Access, and the Audit Log.
- The app is HIPAA-scoped. Handing production credentials to an unvetted overseas freelancer is the exact thing your BAA and audit trail exist to prevent. It would also be a genuinely bad line item to explain in an audit.

**What he gets instead:** finished screen recordings and stills that *you* produce (Option A above), using only seeded demo accounts, delivered as flat video files. He never touches the app, never gets a credential, never sees a real name.

That's not a downgrade — it's how most polished app promos are made. Editors work from supplied footage constantly.

## 0.3 The content rules that are not negotiable

Put these in writing to him. A talented editor with no healthcare context will absolutely violate them by accident.

1. **Zero real patient data.** Every name, face, streak, post, and message on screen must come from seeded demo accounts. No exceptions, no "just this one frame."
2. **No stock addiction imagery.** No pill bottles, needles, whiskey glasses, silhouettes crying in the dark, shattered mirrors, before/after faces, hands reaching out of water. This is the single most common failure mode for recovery marketing and it is stigmatizing.
3. **No outcome or treatment claims.** The app does not treat, cure, or prevent anything. Never "get sober," "stay clean," "beat addiction." It is a *support and connection tool* for people already in recovery.
4. **The crisis disclaimer is mandatory** in any video that shows the "I'm Struggling" flow — on screen, legible, held long enough to actually read: *"Milton Nation is a peer-support community, not an emergency service, and is not monitored 24/7. If you are in danger right now, call or text 988 or call 911."*
5. **No real alumni.** If a video needs a human face, it's a paid actor or illustration, with a signed release. Never a client, never a graduate, never a staff member without written consent.
6. **Tone:** warm, calm, hopeful, dignified. Adult and steady, not triumphant. Think Apple Health, not a gym ad.

---

# PART 1 — The package to send him

Assemble this into one shared folder (Drive/Dropbox) and send the link. Anything you can't produce yet, mark **TBD** rather than omitting — he needs to know it's coming so he can quote around it.

## 1.1 Brand assets ✅ (you already have all of these)

| Item | Where it lives |
|---|---|
| App icon (1024px PNG) | `Assets.xcassets/AppIcon.appiconset/AppIcon.png` |
| In-app logo — light | `Assets.xcassets/MiltonLogo.imageset/milton_logo.png` |
| In-app logo — dark | `Assets.xcassets/MiltonLogo.imageset/milton_logo_dark.png` |
| Vector wordmarks (SVG) | `~/Downloads/Milton-WarChest/00_BRAND/` — `Milton - Jefferson Recovery Wordmark - RGB.svg` + White variant |
| Brand sheet | `00_BRAND/BRAND_SHEET.png` |
| Color palettes | `00_BRAND/MILTON COLOR PALLATE.png`, `MILTON JEFF COLOR PALLATE.png` |
| Existing motion reference | `~/Downloads/Milton-WarChest/02_WEEK-1/renders/WK1_TUE_brand-wall-reel.mp4` |

⚠️ **Verify the logo you send is the fixed one.** An earlier export had the brand color swatches baked into the image and shipped as the in-app logo. It was cropped and fixed (2000×2000 → 2000×1320) for Build 13. Send the *cropped* version — if the file shows a row of color chips, it's the old one.

## 1.2 Exact brand colors (pulled from live app code — these are authoritative)

**Primary**
- `#007396` — Milton teal-blue (signature)
- `#165C7D` — deep teal
- `#0093B2` — bright cyan
- `#369DA0` — teal
- `#56B093` — green

**Accent / neutral**
- `#D4EB8E` — lime accent
- `#101820` — ink / near-black
- `#6B7280` — secondary gray
- `#F2F5F5` / `#E0E5E5` — light backgrounds

**Semantic**
- `#E74C3C` — alert red (crisis / error)
- `#E8A838` — amber (warning / highlight)

**Typography:** the app uses **SF Pro** (iOS system font) throughout — there is not a single custom font in the codebase. Tell him to title in SF Pro / SF Pro Display. It's free from Apple and it's *why* the app already looks Apple-native. Do not let him substitute Montserrat or Poppins.

## 1.3 Footage you must produce (⛔ the blocker — see Part 0.1)

Screen recordings, in this order of priority. Record at the highest resolution available, 60fps, in **both light and dark mode** where cheap to do.

**Alumni (record as `appreviewer@miltonrecovery.com` — "Alex Demo," 90-day streak, Florida):**
- [ ] Login → 2FA code → Home landing
- [ ] Home: sobriety card (~92 days), Daily Reflection, Points & Badges
- [ ] Community: feed scroll, category chips (All/Wins/Struggles/Support/Gratitude), like a post
- [ ] Create post: compose → category → photo attach → publish → appears at top
- [ ] Post detail + comments
- [ ] Meetings: Milton list, Nearby toggle, search, meeting detail, RSVP
- [ ] Chat: conversation list → open a care-team thread → send a message
- [ ] Profile: badges, tiers, edit sobriety date, milestones
- [ ] **"I'm Struggling"** → modal → resources → Struggle Mode (record this slowly and carefully)

**Super Admin (`super-demo@miltonrecovery.com`):**
- [ ] Dashboard landing — all 15 sections visible
- [ ] User Management → open a user → detail
- [ ] Staff Assignments
- [ ] Audit Log
- [ ] Emergency Access
- [ ] Gamification (badge/points editor)
- [ ] Cross-facility announcement (FL + OH)
- [ ] "User View" toggle → alumni experience → "Back to Admin"

**Admin (`admin@miltonrecovery.com` — Florida):**
- [ ] Dashboard landing — 9 sections, Florida-scoped
- [ ] Pending Approvals → approve one → reject one
- [ ] Content Flags → open a flag → review / escalate / dismiss
- [ ] Chat Monitoring → flagged message
- [ ] Community Moderation → approve/reject a post
- [ ] Announcements → create → appears
- [ ] Meeting Management → edit a meeting
- [ ] Invite Alumni (email flow)

**Clinical staff (`case-manager-demo@` and `therapist-demo@`):**
- [ ] Clients tab → caseload list → open conversation → messages
- [ ] Care Tools tab → sobriety monitoring, flags
- [ ] Schedule tab → agenda → "Schedule a session" → type/duration/Teams link *(Ohio-only feature — record from an Ohio account)*
- [ ] Care-team alert push arriving on the staff device

**Ohio isolation (nice-to-have, powerful for the admin walkthrough):**
- [ ] Same dashboard as `admin@miltonjefferson.com` showing *only* Ohio content

## 1.4 Copy and reference material to send

| Item | Where |
|---|---|
| App Store description + subtitle | `launch-kit/04-app-store-connect-content.md` |
| Voice/tone copy bank (all notification + alert text) | `launch-kit/09-copy-bank.md` |
| Existing promo brief (brand nuance, tone guardrails) | `PROMO-BRIEF.md` |
| App Store screenshots (layout reference) | iCloud → `05_Projects/Milton/AppStoreScreenshots/` |

⚠️ The existing App Store screenshot set was shot from the **admin account in User View** — it shows "Welcome back, admin," "0 Days of Recovery," and a floating "Back to Admin" pill. Send it as *layout reference only*, clearly labeled. Do not let it end up in a video.

## 1.5 Decisions only you can make — answer these before he quotes

- [ ] **Voiceover?** Professional VO, AI voice, or text-on-screen only? (Recommendation: **real human VO** for the 60s hero and the four walkthroughs. An AI voice on a recovery app reads as cheap and slightly cold. Text-only is fine for the shorts.)
- [ ] **Music licensing** — who buys it, and is the license commercial + perpetual? Get the license certificate as a deliverable.
- [ ] **Music mood** — send him 2–3 reference tracks. "Warm, restrained piano/ambient, builds gently, no drop."
- [ ] **Reference videos** — send 2–3 you actually like. This single item de-risks the job more than anything else in this document. Apple Health, Headspace, and Calm's product films are the right neighborhood.
- [ ] **App Store URL** — pending review. Mark TBD; he'll need it for end cards.
- [ ] **Where do the shorts run?** Instagram Reels, TikTok, YouTube Shorts, LinkedIn, or the facility's own site? Determines safe-area framing and whether captions are burned in.
- [ ] **Do the walkthroughs need to match the finished UI?** The app is pre-launch at Build 16. If UI changes after he delivers, re-cuts cost money. Consider locking the UI first.
- [ ] **Alumni-facing or staff-facing shorts, or both?**
- [ ] **Is the "I'm Struggling" video approved by clinical?** See Part 7.

---

# PART 2 — Scope of work *(vendor-facing — paste from here down)*

## Project summary

**Milton Nation** is the official iOS alumni app for Milton Recovery Centers (Florida) and Milton Jefferson (Ohio) — substance-use-disorder treatment centers under Milton Health Group LLC. The app supports people **after** treatment ends: sobriety tracking, a moderated peer community, secure messaging with their care team, a meeting finder, and crisis support.

It is a SwiftUI iOS app, built entirely in Apple's system design language (SF Pro, native components). The visual direction you proposed — clean UI animation, cinematic motion, Apple-inspired — is exactly right. The app already looks the part.

**Tone:** warm, calm, hopeful, dignified. Adult and steady. This is a healthcare product for people in recovery — never triumphant, never dramatic, never pitying.

**Audience:** three distinct ones —
1. **Alumni** (former patients) — the hero video and most shorts
2. **Clinical staff and admins** — the walkthroughs, used as training material
3. **Referral partners / the public** — announcement shorts

## Deliverables

### Tier 1 — Hero film

| # | Deliverable | Duration | Format |
|---|---|---|---|
| 1 | **"Milton Nation" hero promo** — the flagship. Covers the whole product. | 60s | 16:9 (1920×1080) |
| 1a | Vertical cutdown of #1 | 60s | 9:16 (1080×1920) |
| 1b | Square cutdown of #1 | 60s | 1:1 (1080×1080) |
| 1c | **30s** cutdown of #1 | 30s | 16:9 + 9:16 |
| 1d | **15s** cutdown of #1 | 15s | 9:16 |

### Tier 2 — Short-form (9:16 vertical, captions burned in, designed to work muted)

**Announcement / launch**
| # | Deliverable | Duration |
|---|---|---|
| 2 | "Milton Nation is here" — launch announcement | 15s |
| 3 | "Now on the App Store" — download CTA | 10–15s |
| 4 | Teaser / countdown — icon + tagline, minimal | 8–10s |

**Feature spotlights** — one feature each, no VO required, text-on-screen + music
| # | Deliverable | Duration |
|---|---|---|
| 5 | Sobriety tracker + milestone badges | 15s |
| 6 | Private community feed | 15s |
| 7 | Direct care-team chat | 15s |
| 8 | Meeting finder (Milton + nearby AA/NA/SMART) | 15s |
| 9 | Privacy & security — "built HIPAA-aware" | 15s |
| 10 | **Crisis support / "I'm Struggling"** — ⚠️ handle per the rules below | 20s |

**Audience-specific**
| # | Deliverable | Duration |
|---|---|---|
| 11 | For alumni — "Recovery doesn't end at discharge" | 20s |
| 12 | For clinical staff — "Your whole caseload, one place" | 15s |
| 13 | Vision piece — where the platform is heading (telehealth, expansion) | 20s |

### Tier 3 — Role walkthroughs (16:9, VO + on-screen callouts, chaptered)

These double as **staff training material**, so clarity beats cinema. Still polished, but the priority is that a new hire can follow it.

| # | Deliverable | Duration | Audience |
|---|---|---|---|
| 14 | **Alumni / member walkthrough** | 3–4 min | Patients & alumni |
| 15 | **Clinical staff walkthrough** (case manager / therapist / counselor) | 4–5 min | Care team |
| 16 | **Admin walkthrough** (facility-scoped) | 5–6 min | Facility admins |
| 17 | **Super Admin walkthrough** (full system) | 6–8 min | Ezra + system owners |

**Each walkthrough must also be delivered as chaptered section exports** — each dashboard section or feature as its own standalone 45–90s clip, self-contained with its own intro card. These become the in-app help center and onboarding emails later, and they're nearly free to produce at edit time. *Roughly 25–30 short clips across the four walkthroughs.* This is the highest-value item in the package and the easiest to forget to ask for.

### Tier 4 — Extras

| # | Deliverable | Duration | Format |
|---|---|---|---|
| 18 | **App Store preview video** — Apple-spec, portrait, actual UI only | 15–30s | Per current App Store Connect spec (portrait 1080×1920 / 886×1920 — verify against Apple's live requirements before rendering) |
| 19 | Animated logo sting — for heads/tails of all videos | 3–5s | 16:9 + 9:16 + alpha channel |
| 20 | Silent B-roll / UI motion pack — clean animated screens, no text | ~60s total | 4K, alpha where possible |
| 21 | End-card template (project file) | — | Editable |

## Technical specs — all deliverables

- **Resolution:** 4K master where possible; 1080p minimum
- **Frame rate:** match source; 30fps for App Store preview
- **Codec:** H.264 MP4 for delivery, ProRes 422 for masters
- **Audio:** −14 LUFS integrated for social, −16 LUFS for web; true peak ≤ −1 dBTP
- **Captions:** burned-in on all 9:16 shorts, **plus** a separate `.srt` for every video with VO
- **Safe areas:** keep text clear of the top 12% / bottom 20% on vertical (platform UI overlays)
- **Both light and dark mode** app footage where it's cheap to include
- **Source files:** Adobe Premiere / After Effects project files with assets, delivered at project close

## Content rules — mandatory

1. **No real patient data, ever.** All footage supplied is from seeded demo accounts. Do not add, invent, or mock up names, photos, or messages that could read as a real person.
2. **No stock addiction imagery.** No pill bottles, needles, alcohol, silhouettes in the dark, shattered glass, before/after faces, hands reaching out of water. This is stigmatizing and will be rejected.
3. **No treatment or outcome claims.** Never "get sober," "stay clean," "cure," "beat addiction." The app supports connection and self-tracking. Nothing more.
4. **Crisis disclaimer required** on any video showing the "I'm Struggling" feature — legible, on screen, held at least 3 seconds:
   > *Milton Nation is a peer-support community, not an emergency service, and is not monitored 24/7. If you are in danger right now, call or text 988 or call 911.*
5. **No real alumni, patients, or staff on camera.** Paid actors or illustration only, with signed releases.
6. **Brand naming:** the app is **"Milton Nation."** The parent treatment brand is **"Milton / Jefferson Recovery."** Lead with Milton Nation; use the parent brand only in a "by Milton Health Group" context. This distinction is deliberate and privacy-motivated — do not merge them.
7. **Typography:** SF Pro only (free from Apple). No substitutions.
8. **Music:** commercially licensed, perpetual. License certificate is a deliverable.

---

# PART 3 — Per-video briefs

## 3.1 — Video #1: The 60-second hero

**The one thing it must land:** *Recovery doesn't end at discharge — and neither does the support.*

**Draft script (60s):**

| Time | Visual | VO / On-screen |
|---|---|---|
| 0:00–0:05 | Black. Type fades up, slow. | VO: *"Treatment ends."* … beat … *"Recovery doesn't."* |
| 0:05–0:12 | App icon assembles. Wordmark. Phone rises into frame, subtle parallax. | VO: *"Milton Nation is the official alumni app for Milton Recovery Centers."* |
| 0:12–0:22 | Sobriety card. Counter animates up to 92 days. A milestone badge unlocks with a soft bloom. | VO: *"Track every day. Celebrate every milestone."* |
| 0:22–0:32 | Community feed scrolls. Category chips. A "Win" post. Hearts tick up. | VO: *"Share the wins — and the hard days — with people who've walked it."* |
| 0:32–0:40 | Care-team chat. Message composes and sends. | VO: *"Message your counselor, therapist, or case manager. Directly. Privately."* |
| 0:40–0:48 | Meetings list → nearby meetings → RSVP confirm. | VO: *"Find a meeting. Anywhere, any day."* |
| 0:48–0:55 | **Pace slows. Music drops back.** "I'm Struggling" button press → resources sheet. Warm, unhurried. | VO: *"And when it's a hard night — help is one tap away."* <br> On-screen: *Not an emergency service. Call or text 988, or 911.* |
| 0:55–1:00 | Logo lockup. App Store badge. | VO: *"Milton Nation. You're not alone."* |

**Notes for the editor:** the 0:48 crisis beat is the emotional center — it must feel like a hand on a shoulder, not a product feature. Slow the cuts, pull the music back, let it breathe. Everything before it earns it.

## 3.2 — Shorts (#2–#13)

Each is one idea, one feature, three cuts maximum. Built to work **muted** — burned-in captions, big type, motion that reads at thumbnail size. First frame must stop the scroll; no slow logo intros.

Pull all copy from `launch-kit/09-copy-bank.md` so the voice matches the app exactly. Some ready-made lines:

- *"Recovery doesn't end at discharge."*
- *"Stay connected to your community, your care team, and your progress."*
- *"You're not alone."*
- *"Mark your sobriety date. Watch your streak grow."*
- *"Your care team is just a tap away."*

**#10, the crisis short, needs the most care in the whole package.** It is not a feature demo. Suggested treatment: quiet, single sustained shot of the "I'm Struggling" press, resources appearing, one line of type — *"When it's a hard night, help is one tap away"* — then the disclaimer, held. No music swell. No fast cuts. If it feels like an ad, it's wrong. **Do not release this one without clinical sign-off** (see Part 7).

## 3.3 — Video #14: Alumni walkthrough (3–4 min)

Recorded as "Alex Demo," a Florida alumnus with a 90-day streak.

1. **Getting in** — register, consent checkbox, "pending approval," approval notification, first login, 2FA code
2. **Home** — sobriety card, daily reflection, points & badges
3. **Community** — feed, the four categories (Wins / Struggles / Support / Gratitude), liking, commenting
4. **Posting** — compose, pick a category, attach a photo, publish
5. **Safety** — reporting a post, blocking a user, unblocking from Settings → Privacy
6. **Meetings** — Milton meetings vs. Nearby, search, meeting detail, RSVP
7. **Chat** — messaging your care team
8. **Profile** — badges, tiers (Seedling → Legend), updating your sobriety date
9. **"I'm Struggling"** — resources, "Notify care team," Struggle Mode (locks every tab except Chat & Contacts)
10. **Settings** — notifications, Face ID, Download My Data, deleting your account

## 3.4 — Video #15: Clinical staff walkthrough (4–5 min)

For case managers, therapists, and counselors. Their app is a **different shell** from the alumni app — five tabs: Clients, Care Tools, Schedule, Community, Profile. No sobriety tracker; this is the clinician view.

1. **Your view is different** — what staff see vs. what members see, and why
2. **Clients tab** — your caseload. *An admin assigns alumni to you; they appear here automatically.*
3. **Messaging a client** — opening a thread, secure 1-on-1
4. **Care Tools tab** — sobriety monitoring, community moderation, chat monitoring, content flags, meetings, announcements
5. **Care-team alerts** — what happens when a member taps "Notify care team," and what the push says (⚠️ **it deliberately contains no member name** — that's a privacy control, explain it)
6. **Crisis flags** — what a flagged post/message looks like on your side and what you're expected to do
7. **Schedule tab (Ohio only)** — session requests, agenda, scheduling a session, session types (Individual Therapy, Group, Psychiatry, Case Management, Intake, Family, Check-In), attaching the Teams link
8. **What you can't do** — no user approvals, no invites, no user management. Those are admin-only, by design.

## 3.5 — Video #16: Admin walkthrough (5–6 min)

Facility-scoped admin. **The central concept: you see your facility, and only your facility.**

1. **Facility isolation** — a Florida admin sees Florida; an Ohio admin sees Ohio. Show it. This is the most important thing an admin must understand about the system.
2. **Pending Approvals** — reviewing an applicant, approving, rejecting
3. **Invite Alumni** — email invitation flow (SMS is off for v1)
4. **Community Moderation** — the review queue, approving and rejecting posts
5. **Content Flags** — user reports and crisis flags, reviewing / escalating / dismissing
6. **Chat Monitoring** — flagged messages and what they mean
7. **Sobriety Tracking** — monitoring member streaks
8. **Announcements** — writing one, who receives it
9. **Meeting Management** — creating and editing Milton meetings
10. **Content Management** — reflections and quotes
11. **Responsibilities recap** — what an admin is accountable for day to day, and the escalation path when a crisis flag appears

## 3.6 — Video #17: Super Admin walkthrough (6–8 min)

Full system access, both facilities, every section. **Frame it as accountability, not power** — the audit log is watching, and that's the point.

1. **What super admin means** — all 15 sections, both facilities, no isolation
2. Everything in the admin walkthrough (can be a chapter reference), then:
3. **User Management** — the full roster, opening a user, changing status
4. **Staff Assignments** — assigning alumni to a clinician's caseload
5. **Role promotion** — promoting a user, and what each role unlocks
6. **Gamification** — editing badges and point values
7. **Contact Numbers** — the crisis and support numbers members see
8. **Emergency Access** — ⚠️ **the highest-stakes feature in the app.** Time-limited access to a member's data. Cover: when it's justified, that every grant and revocation is permanently logged, and that it is a break-glass control, not a convenience
9. **Audit Log** — the full trail, who did what, and why it matters for HIPAA
10. **Cross-facility announcements** — reaching both FL and OH
11. **User View** — stepping into the member experience, and stepping back
12. **Responsibilities recap** — what only a super admin can do, and what should never be done casually

---

# PART 4 — Suggested phasing

He offered to work in stages. Take him up on it, and structure it so you can bail cheaply if quality disappoints.

| Stage | Contents | Why this order |
|---|---|---|
| **0** | You produce the footage (Part 0.1 + 1.3) | Nothing starts without it |
| **1** | Logo sting (#19) + **one** short (#5, sobriety tracker) | ~$100 of work that tells you whether he's actually good. **Do not skip this.** |
| **2** | The 60s hero (#1) + all its cutdowns | Highest value; sets the visual language everything else inherits |
| **3** | Remaining shorts (#2–13) | Fast once the language is set |
| **4** | Walkthroughs (#14–17) + chapter exports | Longest, most tedious, least dependent on taste |
| **5** | App Store preview (#18) + B-roll pack (#20) + source files | Cleanup |

Do not pay for stages 2–5 up front. Gate each on approving the last.

---

# PART 5 — Revisions and approval *(vendor-facing)*

- **2 rounds of revisions** included per deliverable. A "round" is one consolidated set of notes, not a running conversation.
- Approval gates: **script → storyboard/animatic → first cut → final.** Script approval before animation begins is not optional; animating an unapproved script is how budgets die.
- All videos with crisis or clinical content require sign-off from Milton's clinical director before release. Build that wait into the schedule.

---

# PART 6 — Budget guidance *(Ezra only)*

Ballpark for competent Fiverr-tier work, in USD. Rates vary enormously by seller — treat these as a sanity check on his quote, not a target.

| Item | Reasonable range |
|---|---|
| 60s hero + 4 cutdowns | $400 – $1,200 |
| 12 short-form videos | $40 – $100 each → **$500 – $1,200** |
| 4 walkthroughs (~20 min total, VO, chaptered) | $600 – $1,500 |
| ~25–30 chapter exports | $200 – $500 (should be cheap — same timeline) |
| App Store preview | $100 – $250 |
| Logo sting + B-roll pack | $150 – $400 |
| Professional VO (~25 min finished) | $200 – $600 |
| Music licensing | $50 – $200 |
| **Total** | **~$2,200 – $5,800** |

**If he quotes under ~$1,500 for all of it, that's a warning sign, not a win.** It usually means AI voice, template After Effects packs, and no source files. For a healthcare product where a stigmatizing frame is a real reputational risk, the cheapest bid is the expensive one.

**Negotiating leverage you actually have:** you're supplying all footage, all brand assets, all copy, and detailed scripts. That's a large fraction of the work removed from his plate — the quote should reflect it. Say so explicitly.

---

# PART 7 — Lock these terms before you pay

- [ ] **NDA signed** before he receives the footage folder. Non-negotiable — the footage shows PHI-shaped UI even with fake data.
- [ ] **Full commercial rights + copyright assignment** on delivery. Fiverr's default license is not always outright ownership. Get it in writing.
- [ ] **Source files** (Premiere / After Effects projects, with assets) as an explicit deliverable. Without them, every future edit goes back through him at his price, forever. This is the term freelancers most often quietly drop.
- [ ] **Music license certificate** delivered with the files, commercial + perpetual.
- [ ] **Actor releases** if any human appears on camera.
- [ ] **No public portfolio use without written permission.** A recovery-center client on his Fiverr showreel is a problem for Milton, not for him.
- [ ] **He never receives app credentials.** Ever. Footage only. (Part 0.2)
- [ ] **Clinical director sign-off** required before any crisis-related video (#10, hero beat at 0:48, walkthrough crisis chapters) is published.
- [ ] **Milestone payments**, gated on stage approvals (Part 4).
- [ ] **Confirm timeline in writing** — "accelerated" should mean specific dates, not a vibe.

---

# PART 8 — Reference: role and permission matrix

Useful for fact-checking the walkthroughs. Pulled from `Models/User.swift` and `ViewModels/AdminViewModel.swift`.

## Roles

| Role | Scope | Shell |
|---|---|---|
| `alumni` | Own facility | Member tabs: Home · Community · Meetings · Chat · Profile |
| `case_manager` | Assigned caseload | Staff tabs: Clients · Care Tools · Schedule* · Community · Profile |
| `therapist` | Assigned caseload | Same as case manager |
| `counselor` | Assigned caseload | Same as case manager |
| `admin` | **One facility** (FL or OH) | Admin dashboard, 9 sections |
| `super_admin` | **All facilities** | Admin dashboard, all 15 sections |

\* Schedule tab is **Ohio-only** at present; super admins always see it.

## Dashboard sections by role

| Section | Staff | Admin | Super Admin |
|---|:--:|:--:|:--:|
| Pending Approvals | — | ✅ | ✅ |
| Invite Alumni | — | ✅ | ✅ |
| Sobriety Tracking | ✅ | ✅ | ✅ |
| Community Moderation | ✅ | ✅ | ✅ |
| Meeting Management | ✅ | ✅ | ✅ |
| Chat Monitoring | ✅ | ✅ | ✅ |
| Announcements | ✅ | ✅ | ✅ |
| Content Flags | ✅ | ✅ | ✅ |
| Content Management | — | ✅ | ✅ |
| Staff Assignments | — | — | ✅ |
| Contact Numbers | — | — | ✅ |
| User Management | — | — | ✅ |
| Gamification | — | — | ✅ |
| Emergency Access | — | — | ✅ |
| Audit Log | — | — | ✅ |

## Demo accounts for recording

From `EZRA-TEST-SCRIPT.md`. Password `Milton2026!`, 2FA code `000000`.
**🔒 Internal only — these never leave your machine.**

| Role | Email |
|---|---|
| Alumni (FL) — hero account, 90-day streak | `appreviewer@miltonrecovery.com` |
| Alumni (FL) demo | `recovery.warrior@miltondemo.seed` · `grateful.heart@miltondemo.seed` |
| Alumni (OH) demo | `new.chapter.oh@miltondemo.seed` · `steel.city.strong@miltondemo.seed` |
| Super Admin | `super-demo@miltonrecovery.com` |
| Admin — Florida | `admin@miltonrecovery.com` |
| Admin — Ohio | `admin@miltonjefferson.com` |
| Case Manager | `case-manager-demo@miltonrecovery.com` |
| Therapist | `therapist-demo@miltonrecovery.com` |

---

*Generated from the live repo at Build 16. Feature set, roles, permissions, and copy verified against source. If the UI changes before filming, re-verify Part 8 and the walkthrough outlines.*
