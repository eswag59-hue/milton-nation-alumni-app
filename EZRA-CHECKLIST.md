# Ezra's click-by-click — from right now to patients on the app

**State when you left:** Build 15 archived, launch-blockers just fixed.
**State now:** Everything I could do alone is DONE. All fixes + polish are merged, tested (249/249), deployed to the backend, and **Build 16 is archived in Xcode Organizer waiting for one click**. Build 15 is superseded — upload 16, ignore 15.

---

## 1️⃣ Upload Build 16 (~5 min)
1. Xcode → Window → **Organizer** → select **Milton Nation Alumni App 1.0 (16)** (top).
2. **Distribute App → App Store Connect → Upload → Next → Automatically manage signing → Upload.**
3. Wait for "Upload Successful." TestFlight processes ~5–15 min (no compliance prompt — baked in).
4. Phone → TestFlight → **Install Build 16.**

## 2️⃣ Test Build 16 with Claude (~2–3 hr, the big one)
Open a session and say "run the Build 16 test" — the checklist covers:
- Report / Block / Unblock / consent checkbox
- **A4 create-post** and **A6 crisis detection** (the two gates)
- Facility isolation (FL admin can't see OH data)
- Admin dashboard shows real/empty data (no "Jordan Test", no fake crisis line)
- Delete account → can't log back in; Download My Data includes posts/comments/messages
- "Notify care team" → a staff device actually gets the push
- Crisis disclaimers visible in the Struggling modal + resources sheet
- Then the rest of MASTER-AUDIT-CHECKLIST.md (sections B–M)

## 3️⃣ Screenshots (~15 min, after 2️⃣ passes)
Log in as **Alex Demo** (`appreviewer@miltonrecovery.com` / `Milton2026!` / `000000`) and capture:
1. Home (sobriety tracker + daily reflection) · 2. Community feed · 3. Create Post · 4. "I'm Struggling" resources sheet · 5. Meetings · 6. Care-team chat · 7. Profile (badges)
Drop them in iCloud → `05_Projects/Milton/AppStoreScreenshots/` (replace the April set).

## 4️⃣ Submit to Apple (~30 min)
1. appstoreconnect.apple.com → Milton Nation Alumni → version **1.0** page.
2. Upload screenshots; paste listing copy from `launch-kit/04-app-store-connect-content.md`.
3. **App Privacy** answers + **reviewer notes + demo account**: both verbatim in `launch-kit/APP-STORE-SUBMISSION-PACKET.md`.
4. Select **Build 16** → **Submit for Review** (only at 0 showstoppers from step 2️⃣).
5. Apple: 24–48h. If rejected → `launch-kit/07-rejection-recovery-playbook.md` + Claude.

## 5️⃣ While waiting on Apple — the human gates
- **Clinical director** (email already sent): chase the two signatures — HIPAA memo §9 + crisis protocol §6 (she fills the [SET] blanks). **True gate to real patients.**
- **Sign off the delete-scope** (2 min read): purge deletes name/email/phone/photo/posts/comments/messages/likes/tokens/badges/milestones/RSVPs; **keeps** de-identified audit logs + redacted safety flags. If that matches policy, say "delete scope approved" to Claude.

## 6️⃣ Go live (after Apple approves — NOT before)
1. Supabase dashboard → enable **HIPAA add-on** (pre-signed BAA, ~5 min).
2. Tell Claude **"go live"** → Claude flips `DEMO_BYPASS_ENABLED=false` (kills the 000000 backdoor).
3. Enter real meetings + announcements; create real FL/OH staff + admin accounts.
4. ~~Enable pg_cron~~ ✅ already done for you.

## 7️⃣ Patients (the actual goal)
1. **Pilot:** 10–20 alumni from ONE facility. Watch a week.
2. **Staff training** (30 min): approvals, flags queue, crisis alerts, announcements.
3. Fix what the pilot surfaces → roll out to both facilities.

---
### Claude's standing offers
Drive the Build-16 test · draft staff-training one-pager · draft pilot invite email · flip demo-bypass on "go live" · run `purge-accounts` dry-run · anything in LAUNCH-READINESS.md.
