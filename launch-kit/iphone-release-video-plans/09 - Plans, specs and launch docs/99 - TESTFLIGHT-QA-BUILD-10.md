# TestFlight QA Checklist — Build 10

**30 minutes on a real iPhone before you submit.** Every previous build, TestFlight surfaced 2–4 bugs that weren't visible from code review.

Install Build 10 from TestFlight, then walk this list. Mark each ☐ → ☑ as you go.

---

## Setup (1 min)

- [ ] Build 10 installed on a real iPhone (not simulator)
- [ ] You're on cellular OR your home Wi-Fi (not corporate networks that block traffic)
- [ ] You have the demo phone `+15550001234` ready

---

## Login flow (3 min)

- [ ] Cold-launch app → Login screen shows
- [ ] Tap phone field → keyboard appears → screen auto-scrolls so the field stays visible
- [ ] Type `5550001234` → tap Send Code
- [ ] Code field appears → type `000000` → tap Verify
- [ ] Home screen loads within 2 seconds
- [ ] Sobriety days counter is non-zero
- [ ] Daily quote is visible (not a blank card)
- [ ] Bottom tab bar shows 5 tabs

---

## Community + Comment Likes (5 min) — NEW IN BUILD 9/10

- [ ] Tap Community tab → posts feed loads
- [ ] Scroll the feed — no white flashes, no broken images
- [ ] Tap the heart on a post → heart turns red, count increments by 1
- [ ] Pull-to-refresh → heart STAYS red after reload (server persisted it)
- [ ] Tap a post to open Post Detail screen
- [ ] In Post Detail → tap the heart on a *comment* → heart turns red, count increments
- [ ] Back to feed → expand comments under a different post → tap heart on a comment there → red
- [ ] Force-quit the app → reopen → log back in → verify the comment heart you liked is STILL red

---

## My Posts → Edit → Re-moderation (5 min) — NEW IN BUILD 9/10

- [ ] Profile tab → scroll to "My Posts" row → shows count chevron
- [ ] Tap "My Posts" → list of your posts loads
- [ ] Tap one of your posts → Post Detail opens
- [ ] Tap **ellipsis (•••) in toolbar** → menu shows Edit + Delete
- [ ] Tap Edit → sheet appears with current content pre-filled
- [ ] Change text to something benign → tap Save → see "Edit submitted for review"
- [ ] Tap Edit again → change text to **"I want to end it all"** → tap Save
- [ ] Expect: "Edit submitted. Our team will reach out shortly." message
- [ ] Open Supabase Dashboard → posts table → confirm that post's status = `flagged_for_crisis`
- [ ] Tap ellipsis → Delete → confirm → post disappears

---

## Struggling Modal + Care Team (3 min)

- [ ] Home tab → "I'm Struggling Today" button visible + prominent
- [ ] Tap it → modal opens
- [ ] Care Team section shows real names (Case Manager + Therapist)
- [ ] Tap Call on a care team member → phone dialer opens with real number
- [ ] Tap Cancel on dialer → back in modal
- [ ] Scroll modal → 988, Crisis Text Line, SAMHSA all show
- [ ] **Tap "Florida · (844) 406-4325"** → phone dialer opens with the FL number
- [ ] **Tap "Ohio · (740) 715-4673"** → phone dialer opens with the OH number
- [ ] Dismiss modal

---

## Meetings (2 min)

- [ ] Meetings tab → list loads with real Miami meetings
- [ ] Tap a meeting → detail screen with time/location
- [ ] "Add to Calendar" works (system prompts for calendar access, then adds)
- [ ] "Get Directions" works (opens Apple Maps OR Waze if installed)

---

## Chat (3 min)

- [ ] Chat tab → conversations list loads
- [ ] Tap a conversation → messages load, scrolled to bottom
- [ ] Type a message → send → message appears immediately
- [ ] Send a benign message → status normal
- [ ] Send "I want to kill myself" → support resources modal auto-appears, message still goes through but flagged

---

## Profile + Edits (3 min)

- [ ] Profile tab → your photo + name + sobriety days visible
- [ ] Tap photo → photo picker opens
- [ ] Pick a new photo → uploads → photo updates within 5s
- [ ] Background app → reopen → new photo persists
- [ ] Badges grid visible — tap a badge → detail sheet with description
- [ ] Settings → Notifications → toggle Community off → no crash

---

## Push notifications (3 min)

- [ ] Open Settings app → Milton → Notifications → confirm Allow Notifications is ON
- [ ] In-app, submit a benign post → confirm "Post submitted for review" alert
- [ ] (Admin side, separate device or logged in admin demo): approve the post
- [ ] First device receives push: "Post Approved"
- [ ] Tap the push → app opens to home (or the post)

---

## Edge cases (3 min)

- [ ] Airplane mode → open app → still shows last-seen content, no white-screen
- [ ] Airplane mode → try to post → error message is human-readable ("No connection. Try again.")
- [ ] Disable airplane mode → app reconnects
- [ ] Force-quit → reopen → still logged in (Keychain persists JWT)
- [ ] Rotate phone (unless portrait-locked) — verify content reflows or stays locked cleanly
- [ ] Background app for 5 min → return → no crash, no re-login

---

## Logout + delete (1 min)

- [ ] Profile → Logout → returns to Login screen
- [ ] Try logging back in with demo phone → works
- [ ] (Optional) Profile → Delete Account → confirm dialog warns about 30-day grace
  - DO NOT actually delete the demo account

---

## What to do if anything failed

- Note the exact step + what you saw
- Send Ezra the list
- He'll cut Build 11 with fixes and you re-run this same checklist

---

## When all ☑

Open `SUBMIT-BUILD-10.md` and proceed to Archive + Upload.
