# 🧪 Deep Test Sequence — Every Button, Every Profile, Every Case

**When to run:** AFTER Twilio Trust Hub + Campaign approval comes back, BEFORE Apple resubmission.
**Estimated time:** 4-6 hours total (recommended to spread across 2 sessions)
**Devices needed:** 1 real iPhone (Apple Reviewer device class — iPhone 12 or newer ideal), 1 second iPhone for cross-user tests (or simulator), iPad for iPad layout
**Helpers ideal:** 1-2 people to act as 2nd user (chat tests, etc.)
**Pass criteria:** Every checkbox green. Bugs sorted into Showstopper / P1 / Polish.

---

## ⚙️ Pre-Test Setup

Before starting:

- [ ] Twilio Campaign status: **Approved** (confirm in Twilio console)
- [ ] Twilio BAA signed and on file
- [ ] Build 11 installed via TestFlight on real iPhone
- [ ] `DEMO_BYPASS_ENABLED = true` for now (we test BOTH demo bypass AND real flow)
- [ ] Bring a real phone number you control + a second one if possible
- [ ] Have a separate Apple ID / device for "second user" tests
- [ ] Pencil + paper or notes app for bug log

### Test Account Cheat Sheet

| Account | Use for |
|---|---|
| `+15550001234` / OTP `000000` | Apple Reviewer demo (bypass) |
| YOUR real phone | Primary "alumni FL" persona |
| HELPER real phone | "alumni OH" or "second user" persona |
| `admin@miltonrecovery.com` / `Milton2026!` | FL admin |
| `admin@miltonjefferson.com` / `Milton2026!` | OH admin |
| `super-demo@miltonrecovery.com` / `Milton2026!` | Super admin |
| `case-manager-demo@miltonrecovery.com` / `Milton2026!` | Case manager |
| `therapist-demo@miltonrecovery.com` / `Milton2026!` | Therapist |

---

# 🟢 SURFACE 1: Authentication & Onboarding

## 1A — New User Signup (Florida alumni — REAL phone, REAL Twilio)

- [ ] **App launch — first time**: splash screen appears, then onboarding/welcome
- [ ] Tap "Sign Up" / "Create Account"
- [ ] **Phone entry validation**:
  - [ ] Try invalid format ("abc") → error
  - [ ] Try too short ("555") → error
  - [ ] Try without country code → either auto-formats or error
  - [ ] Enter valid number → "Continue" enables
- [ ] **Submit phone** → confirm:
  - [ ] Loading state appears
  - [ ] Twilio SMS arrives on real phone within 30 seconds
  - [ ] Message reads correctly: "Your Milton Nation verification code is XXXXXX. Code expires in 5 minutes."
  - [ ] SMS sender is Milton Nation Twilio number (not random)
- [ ] **OTP entry**:
  - [ ] Wrong code → error, can retry
  - [ ] Correct code → advances
- [ ] **Profile setup**:
  - [ ] Full name field — required validation
  - [ ] Email field — format validation
  - [ ] Facility selection: FL vs OH — required
  - [ ] Sobriety date picker — works, doesn't allow future dates
  - [ ] Treatment program selection (IOP/PHP/Detox/Residential/OP/Other)
  - [ ] Optional profile photo upload (camera + library both work)
  - [ ] Skip photo → continues
- [ ] **Submit profile** → "Awaiting admin approval" state
- [ ] **Welcome email arrives** at the email entered (check inbox)
  - [ ] From: `noreply@miltonrecovery.com`
  - [ ] Subject + body look on-brand
  - [ ] No broken images or links
- [ ] **Push notification permission prompt** appears → tap Allow
- [ ] App shows "Pending approval" screen, blocks main features

## 1B — Admin Approves the New Signup (use FL admin in a second session)

- [ ] Sign in as `admin@miltonrecovery.com`
- [ ] Navigate to admin → pending approvals
- [ ] See the new alumni in list
- [ ] Tap row → see full profile details
- [ ] Tap "Approve"
- [ ] Confirmation appears
- [ ] Push notification fires to new alumni's device ("Account approved")
- [ ] Email notification optional but check if it goes out

## 1C — New User Signup (Ohio alumni)

Repeat 1A but select Ohio facility.
- [ ] Ohio admin (`admin@miltonjefferson.com`) sees the approval, not FL admin
- [ ] Facility isolation works correctly

## 1D — New User Signup REJECTED by admin

- [ ] Create another test signup
- [ ] Admin taps "Reject" with reason "not a Milton alumni"
- [ ] New user sees rejection screen with message + support contact

## 1E — Demo Bypass Signup (Apple Reviewer path)

- [ ] Sign up using `+15550001234`
- [ ] **No real SMS sent** (Twilio call skipped)
- [ ] Enter `000000` as OTP → accepted
- [ ] Profile auto-completes or proceeds to profile setup
- [ ] Auto-approved (or skip approval queue if implemented)
- [ ] Full app access immediately

## 1F — Returning User Login

- [ ] Sign out
- [ ] App returns to sign-in screen
- [ ] Enter same phone → OTP arrives
- [ ] Wrong OTP → error, retry works
- [ ] Correct OTP → logs in
- [ ] Profile data persists (name, sobriety, etc.)
- [ ] Sobriety counter increments correctly (days since start date)
- [ ] Session token stored in Keychain (not visible to user but persists across app launches)

## 1G — OTP Rate Limiting

- [ ] Try to request OTP 6 times in 1 hour → 6th request blocked with rate-limit message
- [ ] Wait → can request again

## 1H — OTP Expiry

- [ ] Request OTP
- [ ] Wait 6 minutes
- [ ] Try the old OTP → "expired" error
- [ ] Request new → works

## 1I — Multi-Device Login

- [ ] Sign in on iPhone A → works
- [ ] Sign in same account on iPhone B → works
- [ ] Both devices receive push when account event happens
- [ ] Sign out on A → B remains signed in

---

# 🟢 SURFACE 2: Profile

## 2A — View Own Profile

- [ ] Profile tab loads
- [ ] All entered fields display correctly
- [ ] Sobriety counter accurate
- [ ] Badges section shows earned + unearned
- [ ] Photo displays correctly (or initial avatar)

## 2B — Edit Profile

- [ ] Tap "Edit"
- [ ] Change name → saves
- [ ] Change bio → saves
- [ ] Change photo (camera) → uploads, displays
- [ ] Change photo (library) → uploads, displays
- [ ] Remove photo → reverts to initials
- [ ] Cancel edit → no changes saved

## 2C — Sobriety Tracking

- [ ] Counter shows correct days
- [ ] Wait until midnight in test env → counter increments
- [ ] Edit sobriety date back → counter updates
- [ ] Setting date to TODAY → counter is 0

## 2D — Milestones & Badges

- [ ] At 30 days → "30 Day" badge auto-awarded
- [ ] Notification fires for new badge
- [ ] Badge appears on profile
- [ ] Tap badge → details view
- [ ] Long-press → share badge (if implemented)

## 2E — View Other Alumni Profile

- [ ] Tap another alumni's name in feed
- [ ] Profile loads
- [ ] Shows their public info (name, sobriety, badges)
- [ ] Does NOT show private info (phone, exact treatment program if hidden)
- [ ] Facility-isolated: FL alumni cannot see OH alumni private data

---

# 🟢 SURFACE 3: Community Feed

## 3A — Browse Feed

- [ ] Feed loads on app open
- [ ] Pull-to-refresh works → new content appears
- [ ] Infinite scroll → loads page 2, 3, etc.
- [ ] Empty state when no posts (rare)
- [ ] Posts show: author name, time, content, like count, comment count
- [ ] Photos load (no broken images)

## 3B — Create Post — Clean Content (auto-approves)

- [ ] Tap "+" / "New Post"
- [ ] Type "Grateful for my 90 days. Felt impossible 3 months ago."
- [ ] Select category (Gratitude)
- [ ] Tap Post
- [ ] Post appears in feed immediately
- [ ] Status: auto-approved (not held for review)
- [ ] No crisis sheet appears

## 3C — Create Post — Photo

- [ ] Tap "+" → add photo
- [ ] Camera capture works
- [ ] Library select works
- [ ] Multi-photo (up to 4) works
- [ ] Post with photo → appears with image

## 3D — Create Post — FLAGGED CONTENT (medium risk)

- [ ] Type: "I relapsed and I'm struggling"
- [ ] Tap Post
- [ ] Status: held for review (not auto-published)
- [ ] User sees: "Your post is being reviewed by our team"
- [ ] Admin receives push notification (test on admin device)
- [ ] Admin sees flagged content in moderation queue with REDACTED summary
- [ ] Admin can approve → post becomes visible
- [ ] Admin can dismiss → post deleted

## 3E — Create Post — CRISIS CONTENT (high risk)

- [ ] Type: "I want to kill myself"
- [ ] Tap Post
- [ ] **Crisis Resources Sheet appears immediately** (slides up modal)
- [ ] Sheet shows:
  - [ ] 988 Suicide Lifeline
  - [ ] Crisis Text Line
  - [ ] SAMHSA helpline
  - [ ] Milton FL (844) 406-4325 — TAP TO DIAL
  - [ ] Milton OH (740) 715-4673 — TAP TO DIAL
  - [ ] 911
- [ ] Tap each phone number → iOS dialer opens with correct number
- [ ] Post is held (not auto-published)
- [ ] Admin/care team receives **elevated push** within 30 seconds
- [ ] Push subject: "URGENT: User may need immediate help"
- [ ] Admin can review, escalate, or dismiss

## 3F — Negation Downgrade (false positive avoidance)

- [ ] Type: "I haven't relapsed in 5 years"
- [ ] Tap Post
- [ ] Post auto-approves (negation downgrades risk)
- [ ] No crisis sheet
- [ ] No admin push

## 3G — Time-Immediacy Elevation

- [ ] Type: "Going to use tonight"
- [ ] Post → triggers CRISIS (medium "going to use" + time marker "tonight" = high)
- [ ] Crisis sheet appears
- [ ] Admin push fires

## 3H — Each Category Test (cycle through all 6)

For each category, post a HIGH phrase and verify crisis flow fires:

- [ ] **Self-harm**: "I want to end my life"
- [ ] **Drugs**: "I shot heroin today"
- [ ] **Alcohol**: "I had a drink, I'm drunk"
- [ ] **Violence**: "I want to hurt someone"
- [ ] **Eating disorder**: "I made myself throw up"
- [ ] **Domestic violence**: "He hit me again"

## 3I — Emergency Help-Seeking (should NOT flag as harm)

- [ ] Type: "I need help, please call 988"
- [ ] Post posts normally (not flagged as harm)
- [ ] Crisis resources sheet appears (help-seeking detected)
- [ ] Admin gets a NOTICE (not URGENT) push

## 3J — Comment on Post

- [ ] Tap on a post
- [ ] Add comment "Hang in there"
- [ ] Comment appears
- [ ] Comment count increments
- [ ] Post author gets push notification
- [ ] Reply to comment (nested) works
- [ ] Long-press comment → menu (edit/delete own, report others)

## 3K — Like/Unlike

- [ ] Tap heart on post → like count +1
- [ ] Tap again → unlike, count -1
- [ ] Persists across app restart

## 3L — Report Post (user-initiated)

- [ ] Tap "..." on someone else's post → Report
- [ ] Select reason
- [ ] Submit → admin sees report

## 3M — Delete Own Post

- [ ] Tap "..." on own post → Delete
- [ ] Confirmation dialog
- [ ] Post removed from feed

## 3N — Facility Isolation in Feed

- [ ] FL alumni only sees FL posts (unless cross-facility allowed)
- [ ] OH alumni only sees OH posts
- [ ] Super admin sees both

---

# 🟢 SURFACE 4: Chat (1:1 with care team)

## 4A — Chat List

- [ ] Chat tab opens
- [ ] Shows assigned care team conversations
- [ ] Last message preview visible
- [ ] Unread badge accurate
- [ ] Order: most recent at top

## 4B — Open Conversation

- [ ] Tap a chat → opens
- [ ] Message history loads (paginated)
- [ ] Scroll to top → older messages load
- [ ] Latest message visible at bottom

## 4C — Send Text Message

- [ ] Type message → send
- [ ] Appears immediately
- [ ] Read receipt updates when recipient reads it
- [ ] Recipient gets push notification

## 4D — Send Photo

- [ ] Tap attachment → camera/library
- [ ] Photo uploads
- [ ] Photo displays in chat
- [ ] Recipient can tap to view fullscreen
- [ ] Photo persists on app restart

## 4E — Send Voice Note (if supported)

- [ ] Hold mic → record → release → sends
- [ ] Plays back correctly
- [ ] Waveform displays

## 4F — Receive Message

- [ ] Helper sends message
- [ ] App badge increments
- [ ] Push notification fires
- [ ] Tap push → opens to correct chat
- [ ] Message appears in real-time when chat is open

## 4G — Crisis Content in Chat

- [ ] Send: "I'm thinking about killing myself"
- [ ] Crisis sheet appears
- [ ] Message held for care team review
- [ ] Care team gets URGENT push

## 4H — Chat Persistence

- [ ] Kill app
- [ ] Re-open
- [ ] Chat history intact
- [ ] Drafts persist (if implemented)

---

# 🟢 SURFACE 5: Meetings

## 5A — Browse Meetings

- [ ] Meetings tab opens
- [ ] List loads (from BMTL API or mock)
- [ ] Each shows: name, day, time, distance, format

## 5B — Search & Filter

- [ ] Search by name → filters
- [ ] Filter by day of week → works
- [ ] Filter by time of day → works
- [ ] Filter by format (AA/NA/SMART) → works
- [ ] Clear filters → reset

## 5C — Nearby Meetings

- [ ] Grant location permission on first launch
- [ ] Nearby tab shows meetings sorted by distance
- [ ] Distance values are reasonable
- [ ] Distance updates if you move significantly

## 5D — Meeting Details

- [ ] Tap meeting → details
- [ ] Address visible
- [ ] Phone (if available)
- [ ] Tap address → opens Maps
- [ ] Tap phone → opens dialer
- [ ] "I'm attending" button → marks attended

## 5E — Attendance Badge

- [ ] Mark 5 meetings attended
- [ ] Earn "Meeting Goer" or similar badge
- [ ] Notification fires

---

# 🟢 SURFACE 6: Crisis Flow

## 6A — "I'm Struggling" button

- [ ] Big visible button on home/profile
- [ ] Tap → Crisis Resources Sheet
- [ ] Same 6 resources as 3E

## 6B — Each Number Dials Correctly

- [ ] 988 → opens dialer with 988
- [ ] Crisis Text → opens Messages with HOME to 741741
- [ ] SAMHSA 1-800-662-4357 → opens dialer
- [ ] Milton FL (844) 406-4325 → opens dialer
- [ ] Milton OH (740) 715-4673 → opens dialer
- [ ] 911 → opens dialer

## 6C — Focused Mode

- [ ] "Stay with me" / "Focus mode" → app locks to chat-only
- [ ] Other tabs disabled
- [ ] Can exit via explicit button (not gesture)

---

# 🟢 SURFACE 7: Notifications

## 7A — Permission Prompts

- [ ] First app launch → push permission prompt
- [ ] Deny → can still use app
- [ ] Settings → re-enable from iOS settings

## 7B — Push Delivery States

For each notification type, test in 3 app states:
- [ ] App foregrounded (in-app banner)
- [ ] App backgrounded (banner notification)
- [ ] App closed (lock-screen notification)

Notification types:
- [ ] New comment on your post
- [ ] Care team message
- [ ] Account approved
- [ ] Milestone badge earned
- [ ] Crisis alert (admin only)
- [ ] Daily reflection (if implemented)

## 7C — Deep Links

- [ ] Tap "New comment" push → opens to that post
- [ ] Tap "Care team message" → opens to that chat
- [ ] Tap "Account approved" → opens home
- [ ] Tap "Crisis alert" → opens admin queue

## 7D — Settings

- [ ] Settings → Notifications
- [ ] Toggle each type on/off
- [ ] Push delivery respects toggles

---

# 🟢 SURFACE 8: Admin Panel

## 8A — Admin Sign-In

- [ ] Sign in with `admin@miltonrecovery.com` / `Milton2026!`
- [ ] Admin dashboard loads (different from alumni home)

## 8B — Content Flags Queue

- [ ] All flags visible
- [ ] Filter: All / Pending / Reviewed / Dismissed / Escalated — works
- [ ] Sort: by date / by risk — works
- [ ] Tap flag → details

## 8C — Flag Detail View

- [ ] Shows redacted summary (NOT raw text)
- [ ] Shows category, risk level, timestamp
- [ ] Shows user info (name, facility — but not other PHI)
- [ ] Three actions: **Review** / **Escalate** / **Dismiss**

## 8D — Review Flag

- [ ] Tap Review → opens review sheet
- [ ] Add optional review note
- [ ] Mark Reviewed
- [ ] Flag moves to Reviewed list

## 8E — Escalate Flag

- [ ] Escalate → flag marked high priority
- [ ] Notification fires to super admin / care team
- [ ] Optional: care team can directly chat the user

## 8F — Dismiss Flag

- [ ] Dismiss → marked dismissed
- [ ] Note: dismissals are reversible

## 8G — Approve New Signups

- [ ] Pending approvals tab
- [ ] See list of new signups awaiting approval
- [ ] Approve / Reject works
- [ ] Push fires to user on approval

## 8H — Facility Isolation

- [ ] FL admin can ONLY see FL data
- [ ] FL admin cannot escalate or view OH flags
- [ ] Trying to access OH endpoint via deep link → blocked

## 8I — Broadcast Announcement (if implemented)

- [ ] Admin → Announcements
- [ ] Compose broadcast
- [ ] Send → appears on all FL alumni home feeds
- [ ] OH alumni do NOT see FL broadcast

---

# 🟢 SURFACE 9: Super Admin

## 9A — Super Admin Sign-In

- [ ] Sign in with `super-demo@miltonrecovery.com`
- [ ] See both facilities' data

## 9B — Cross-Facility

- [ ] View FL content flags AND OH content flags
- [ ] Compose cross-facility broadcast

## 9C — User Management

- [ ] Search any user (FL or OH)
- [ ] View user details
- [ ] Suspend user (24-hour, 7-day, permanent)
- [ ] Suspended user can't log in

---

# 🟢 SURFACE 10: Care Team (Case Manager + Therapist)

## 10A — Case Manager Sign-In

- [ ] Sign in with `case-manager-demo@miltonrecovery.com`
- [ ] Different home screen (assigned alumni list)

## 10B — Assigned Alumni

- [ ] See list of assigned alumni
- [ ] Each shows: name, last activity, sobriety days
- [ ] Tap alumni → view their profile + chat

## 10C — Crisis Alert Reception

- [ ] If an assigned alumni triggers a crisis flag
- [ ] Care team gets push notification
- [ ] Can open chat directly from push

## 10D — Therapist Sign-In

- [ ] Sign in with `therapist-demo@miltonrecovery.com`
- [ ] Similar but with therapy-specific permissions

---

# 🟢 SURFACE 11: Settings

## 11A — Settings Overview

- [ ] Settings tab opens
- [ ] All sections visible: Profile, Notifications, Privacy, Account, About

## 11B — Phone Number Change

- [ ] Tap "Change phone number"
- [ ] Enter new number → SMS sent to new number with OTP
- [ ] Enter OTP → number updated
- [ ] Old number can no longer log in
- [ ] (This is one of the 4 Twilio SMS surfaces!)

## 11C — Notifications Toggles

- [ ] All toggles work
- [ ] Changes persist across app launches

## 11D — Privacy / Biometrics

- [ ] Enable Face ID / Touch ID
- [ ] Kill app → re-open → prompts biometric
- [ ] Disable → no longer prompts

## 11E — Sign Out

- [ ] Sign out → returns to sign-in screen
- [ ] Session cleared
- [ ] Re-signing in restores all data

## 11F — Delete Account

- [ ] Tap Delete Account → confirmation dialog (typed confirmation if required)
- [ ] Delete → account scheduled for deletion
- [ ] Sign out
- [ ] Try sign in → "account scheduled for deletion, restore within 30 days"
- [ ] Tap restore → account restored
- [ ] OR wait 30 days → permanent deletion (test in dev env only)

## 11G — Privacy & Terms Links

- [ ] Tap Privacy Policy → opens https://miltonrecovery.com/milton-nation-privacy in Safari
- [ ] Tap Terms of Service → opens https://miltonrecovery.com/app-terms-of-use
- [ ] Both pages load correctly, no 404

## 11H — Support Contact

- [ ] Tap Support → opens email composer with `support@miltonrecovery.com` (or whichever)
- [ ] Subject pre-filled with app version

## 11I — App Version Display

- [ ] About → version shows "1.0 (11)"

---

# 🟢 SURFACE 12: Edge Cases & Resilience

## 12A — Offline Mode

- [ ] Airplane mode ON
- [ ] App still opens
- [ ] Banner shows "You're offline"
- [ ] Cached content (last feed, profile, chat history) still visible
- [ ] Compose post → queued, shows "will send when online"
- [ ] Turn airplane mode OFF
- [ ] Queued post sends
- [ ] Sync resumes

## 12B — Backgrounding & Foregrounding

- [ ] Open app, navigate to community
- [ ] Background app
- [ ] **Screenshot protection**: in app switcher, app shows blurred/branded image (not the actual screen)
- [ ] Foreground → returns to community
- [ ] Session intact

## 12C — Screenshot Detection

- [ ] On a sensitive screen (chat with PHI)
- [ ] Take a screenshot
- [ ] App should detect → log audit entry
- [ ] (Optional) Toast warning to user

## 12D — Face ID / Touch ID

- [ ] If enabled in 11D
- [ ] Background app > 30 sec → re-open requires biometric

## 12E — App Lock Timeout

- [ ] Background for 5 min → on return, sign-in required (if configured)

## 12F — Crash Recovery

- [ ] Force-quit app mid-action (e.g., while typing post)
- [ ] Re-open → draft restored (if implemented)
- [ ] No data corruption

## 12G — Network Errors

- [ ] Toggle airplane mode mid-request
- [ ] Error toast appears with clear message
- [ ] Retry button works

## 12H — Slow Network (Network Link Conditioner)

- [ ] Enable Network Link Conditioner → 3G
- [ ] App still usable
- [ ] Loading states appear properly
- [ ] No timeouts before 30 seconds

## 12I — Old iOS Compatibility

- [ ] Test on lowest supported iOS (e.g., iOS 17 if minimum)
- [ ] All features work
- [ ] No deprecated API crashes

---

# 🟢 SURFACE 13: Accessibility & Layout

## 13A — Dynamic Type

- [ ] Settings → Display → Larger Text → max
- [ ] All text scales
- [ ] No truncation, no overlap
- [ ] Test at smallest type too

## 13B — Dark Mode

- [ ] Toggle system Dark mode
- [ ] App respects → switches
- [ ] Colors readable in both modes
- [ ] No invisible text

## 13C — VoiceOver

- [ ] Enable VoiceOver
- [ ] Navigate every primary screen
- [ ] All buttons have labels
- [ ] All images have alt text
- [ ] Reading order is logical

## 13D — Device Sizes

- [ ] iPhone SE (smallest current) → no clipping
- [ ] iPhone Pro Max (largest) → no awkward spacing
- [ ] iPad → either supported layout OR app gracefully runs in iPhone-portrait mode

## 13E — One-Handed Use

- [ ] Reachability mode → still usable
- [ ] No critical buttons in top-corners only

---

# 🟢 SURFACE 14: Performance

## 14A — Launch Times

- [ ] **Cold launch** (app killed): < 3 seconds to interactive
- [ ] **Hot launch** (background): < 1 second
- [ ] Splash screen doesn't linger

## 14B — Scroll Performance

- [ ] Community feed scrolls at 60fps
- [ ] No jank loading images
- [ ] Long lists (100+ items) don't slow down

## 14C — Image Upload

- [ ] Single photo: < 5 sec to upload (good network)
- [ ] Multiple photos: parallel uploads work

## 14D — Battery & Heat

- [ ] 30-min heavy use → device doesn't get noticeably hot
- [ ] Battery drain comparable to similar social apps

---

# 🟢 SURFACE 15: Twilio Surfaces (4 places SMS must work)

### 15A — Signup OTP (covered in 1A)
✅ Verified in Surface 1

### 15B — Returning Login OTP (covered in 1F)
✅ Verified in Surface 1

### 15C — Admin Invite SMS

- [ ] Admin → Send Invite (if feature exists)
- [ ] Enter alumni phone number
- [ ] SMS arrives on that phone
- [ ] SMS includes app download link OR signup code
- [ ] Tapping link opens App Store or deep-link

### 15D — Phone Number Change (covered in 11B)
✅ Verified in Surface 11

---

# 🟢 SURFACE 16: Audit Trail

## 16A — Verify Audit Logs Capture Everything

In Supabase, query `audit_logs` table after running tests:

- [ ] Every login (success + failure)
- [ ] Every admin action (approve, escalate, dismiss)
- [ ] Every content flag
- [ ] Every emergency access (admin viewing flagged user data)
- [ ] Every account creation
- [ ] Every account deletion

---

# 🟢 SURFACE 17: Build & Distribution

## 17A — TestFlight Distribution

- [ ] Build 11 uploaded to TestFlight
- [ ] External testers (if any) get the build
- [ ] Build install works on first try
- [ ] Build 11 version shows "1.0 (11)" in Settings → About

---

# 📋 Bug Triage

For every issue found during this test, log in this format:

```
[SURFACE-#] [Severity] Description
  Repro: 1. Step 1, 2. Step 2, 3. Observed vs Expected
  Device: iPhone X, iOS Y
  Build: 11
```

**Severity tiers:**
- 🔴 **Showstopper** — blocks any user from completing core flow (sign-up, post, crisis), or HIPAA risk
- 🟡 **P1** — significant degradation, but user can work around (e.g., crash on rare action, missing feature)
- 🟢 **Polish** — visual nit, microcopy, minor UX (push to 1.1)

**Rule: 0 Showstoppers must remain before Apple submission.**

---

# ✅ Sign-Off

- [ ] All Showstoppers fixed
- [ ] All P1s either fixed or documented in known-issues for 1.1
- [ ] All ~17 surfaces tested
- [ ] Test team consensus: ready to submit
- [ ] Ezra signs off
- [ ] Tag git commit `rc-build-11-tested-{date}`
- [ ] Backup created

**Once signed off → Final UI review → Apple resubmission.**
