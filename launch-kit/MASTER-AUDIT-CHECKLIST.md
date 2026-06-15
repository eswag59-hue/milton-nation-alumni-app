# Master Pre-Launch Audit — Build 12

**Purpose:** Walk through every page, button, email, SMS, push notification, and account flow in Milton Nation before submitting to Apple Review.

**Estimated time:** 3–4 hours for a complete pass.

**Rule:** Anything you find broken → tell Claude. He fixes. You re-archive (10 min). Re-test that surface. Then move on.

**When to run:** AFTER Build 12 is on your iPhone via TestFlight, BEFORE clicking "Submit for Review" in App Store Connect.

---

## SEQUENCING — read this first

1. **Archive Build 12 in Xcode** (Product → Archive → Distribute → App Store Connect → Upload). This puts the build on TestFlight ONLY — it does NOT submit to Apple for App Store review.
2. **Install Build 12 on your iPhone via TestFlight.**
3. **Work through this checklist top to bottom.**
4. **Mark each item ✅ Pass / ❌ Fail / ⚠️ Polish-only.**
5. **For every ❌:** tell Claude immediately — he fixes, you re-archive + re-upload (takes 10 min), continue audit.
6. **When 0 ❌ remain:** sign off Section I, then click "Submit for Review" in App Store Connect.

---

## PRE-FLIGHT (10 min)

### What you need set up

- [ ] **Primary iPhone** with Build 12 installed via TestFlight
- [ ] **Second device** (iPad, second iPhone, or browser if web-admin works) for admin testing
- [ ] **Your real phone number** for SMS surfaces (only testable after 2FA campaign approved)
- [ ] **A second real phone number** (friend, family) for invite or peer-test
- [ ] **Notes app open** for logging bugs as you find them

### Account credentials cheat sheet

All accounts below have `is_test_account: true` so `OTP 000000` bypasses SMS.

| Account | Email | Password | OTP | Use for |
|---|---|---|---|---|
| Alex Demo (alumni FL) | `appreviewer@miltonrecovery.com` | `Milton2026!` | `000000` | Most testing — Florida alumni with 90 days sobriety |
| FL admin | `admin@miltonrecovery.com` | `Milton2026!` | `000000` | Admin panel, FL facility |
| OH admin | `admin@miltonjefferson.com` | `Milton2026!` | `000000` | Admin panel, OH facility |
| Super admin | `super-demo@miltonrecovery.com` | `Milton2026!` | `000000` | Cross-facility, user management |
| Case manager | `case-manager-demo@miltonrecovery.com` | `Milton2026!` | `000000` | Care team flows |
| Therapist | `therapist-demo@miltonrecovery.com` | `Milton2026!` | `000000` | Care team flows |

---

# SECTION A — Alumni (regular user) flows

Sign in as **Alex Demo** on primary iPhone.

## A1 — First-launch & onboarding

- [ ] App icon visible on home screen, looks correct (Milton wordmark + brand color)
- [ ] Tap icon → app opens within 3 seconds
- [ ] Splash screen appears briefly, doesn't linger
- [ ] Login screen renders with no broken layouts
- [ ] iOS prompts for notifications permission on first launch — tap **Allow**
- [ ] Verify in iPhone Settings → Notifications → Milton Nation → **Allow Notifications: ON**

## A2 — Sign-in flow

- [ ] Email field accepts valid email
- [ ] Email field rejects clearly invalid format
- [ ] Password field hides text
- [ ] Tap Sign In with wrong password → clean error: "Invalid email or password"
- [ ] Tap Sign In with correct credentials → advances to OTP screen
- [ ] OTP screen shows "Enter the 6-digit code sent to your phone via SMS"
- [ ] Enter wrong code → error, can retry
- [ ] Enter `000000` → advances to home feed
- [ ] No console error, no crash
- [ ] Forgot Password link works → email-reset flow visible

## A3 — Home feed (Community)

- [ ] Home tab loads on app open
- [ ] Pull-to-refresh works → spinner appears → posts re-fetch
- [ ] Infinite scroll: scroll to bottom → next page loads
- [ ] Empty state (if no posts): friendly message, no broken UI
- [ ] Post card shows: author name, profile photo (or initials), timestamp, content, like count, comment count
- [ ] Tap author name → opens their profile
- [ ] Tap heart → like count increments (verify by refreshing — must persist)
- [ ] Tap heart again → unlike, count decrements
- [ ] Tap comment icon or comment count → opens post detail
- [ ] Post detail screen: shows full post + all comments
- [ ] Type a comment → tap Send → comment appears

## A4 — Create post (clean content)

- [ ] Tap + (New Post) → CreatePostSheet appears
- [ ] Category picker shows: Wins, Struggles, Support, Gratitude, General
- [ ] Type "Hello from Build 12" → tap Post
- [ ] Loading state appears briefly
- [ ] Post appears at top of feed within 3 seconds
- [ ] Status = auto-approved or pending (per content safety threshold)

## A5 — Create post with photo

- [ ] Tap + → New Post → add photo via Camera (allow permission)
- [ ] Camera capture works → photo previews in sheet
- [ ] Replace via Library → works
- [ ] Tap Post → uploads, appears with image
- [ ] Image loads at correct size, no distortion
- [ ] Tap image in feed → fullscreen view (if implemented)

## A6 — Crisis content detection (THE big test)

For each of the 6 categories, post the high-risk phrase. Expected behavior: crisis sheet appears IMMEDIATELY before submit, post is held + flagged.

- [ ] **Self-harm**: `I want to end my life` → crisis sheet appears
- [ ] **Drugs**: `I shot heroin today` → crisis sheet appears
- [ ] **Alcohol**: `I had a drink, I'm drunk` → crisis sheet appears
- [ ] **Violence**: `I want to hurt someone` → crisis sheet appears
- [ ] **Eating disorder**: `I made myself throw up` → crisis sheet appears
- [ ] **DV**: `He hit me again` → crisis sheet appears
- [ ] **Time-immediacy elevation**: `Going to use tonight` → escalates to crisis (medium → high)
- [ ] **Negation downgrade**: `I haven't relapsed in 5 years` → auto-approves (NO crisis sheet)
- [ ] **Help-seeking**: `I need help, please call 988` → posts normally, crisis sheet still shown for safety
- [ ] After dismissing crisis sheet, post status is `flagged_for_crisis`
- [ ] Repeat crisis post — sheet appears EVERY time (not just first)

## A7 — Crisis resources sheet content

Open the crisis sheet (post crisis content). Verify it shows:

- [ ] **988 Suicide & Crisis Lifeline** with call + text options
- [ ] **Crisis Text Line** with HOME → 741741
- [ ] **SAMHSA helpline** 1-800-662-4357
- [ ] **Milton Recovery FL** (844) 406-4325 — tap to dial opens iOS dialer with correct number
- [ ] **Milton Jefferson OH** (740) 715-4673 — tap to dial works
- [ ] **911** option

## A8 — Like / unlike

- [ ] Tap heart on another post → fills + count up
- [ ] Tap again → empty + count down
- [ ] Force quit + reopen → state persists

## A9 — Comments

- [ ] Open post detail
- [ ] Type clean comment → tap Send → appears
- [ ] Type crisis comment (`I want to die`) → crisis sheet appears
- [ ] Long-press own comment → menu (Edit / Delete)
- [ ] Long-press someone else's comment → menu (Report)
- [ ] Delete own comment → confirmation → removed from list
- [ ] Comment count on post card decrements

## A10 — Profile (own)

- [ ] Tap Profile tab
- [ ] Displays: profile photo (or initials), full name, username, facility (FL/OH), role badge if any
- [ ] Sobriety counter: shows days since sobriety_date
- [ ] Counter math is correct: today's date − sobriety_date = days clean
- [ ] Edit Profile → can change name, bio
- [ ] Change profile photo via Camera → uploads → displays
- [ ] Change profile photo via Library → uploads → displays
- [ ] Remove photo → reverts to initials
- [ ] Cancel edit → no changes saved
- [ ] Badges section: shows earned badges (Alex Demo has sample badges)
- [ ] Tap badge → detail view with description

## A11 — Profile (other users)

- [ ] Tap an author's name in feed
- [ ] Their profile loads
- [ ] Shows: name, photo, sobriety days, badges
- [ ] Does NOT show: phone, email, treatment program details (only own profile + admin can see)
- [ ] FL alumni cannot see OH alumni profile (facility isolation — test with second device signed in as OH)

## A12 — My Posts list

- [ ] Profile or menu → My Posts
- [ ] Shows all posts you've created (including flagged ones)
- [ ] Status badge on each: Approved / Pending / Flagged
- [ ] Tap post → opens post detail
- [ ] Edit own post (if implemented) → works
- [ ] Delete own post → confirmation → removed from feed
- [ ] Deleted posts removed from My Posts list

## A13 — Chat with care team

- [ ] Tap Chat tab
- [ ] Shows assigned care team conversations (Alex Demo has 1+ assigned)
- [ ] Tap conversation → opens chat
- [ ] Message history loads (paginated)
- [ ] Scroll to top → older messages load
- [ ] Type message → tap Send → appears immediately
- [ ] Read receipt updates when recipient reads (verify with second device as care team)
- [ ] Send photo → uploads, displays in chat
- [ ] Tap photo in chat → fullscreen
- [ ] Send voice note (if implemented) → records → sends → plays back
- [ ] Force-quit + reopen → chat history intact
- [ ] Crisis content in chat: `I'm thinking about killing myself` → crisis sheet appears
- [ ] Care team receives URGENT push (test with second device)

## A14 — Meetings

- [ ] Tap Meetings tab
- [ ] List loads (real BMTL data or seed data)
- [ ] Each row shows: name, day, time, distance, format
- [ ] Search by name → filters
- [ ] Filter by day → works
- [ ] Filter by time → works
- [ ] Filter by format (AA / NA / SMART) → works
- [ ] Clear filters → resets
- [ ] Grant location permission → Nearby tab works
- [ ] Distance values are reasonable for your location
- [ ] Tap meeting → details: address, phone, day/time, format
- [ ] Tap address → opens Apple Maps with pin
- [ ] Tap phone → opens dialer
- [ ] Mark "I'm attending" → checked
- [ ] Mark 5 meetings attended (if Meeting Goer badge implemented) → badge earned

## A15 — Crisis flow / "I'm Struggling" button

- [ ] Big visible button somewhere on home or profile
- [ ] Tap → Crisis Resources Sheet (same content as A7)
- [ ] "Focus mode" or "Stay with me" (if implemented) → locks app to chat-only
- [ ] Exit focus mode via explicit button (not gesture)

## A16 — Push notifications received

For each, verify the push fires in the right context. **Background the app first so push appears as banner.**

- [ ] **New comment on your post** — second device comments → primary receives push within 10 sec
- [ ] **Care team message** — care team sends you a message → primary receives push
- [ ] **Account approved** — admin approves a pending user → that user receives push
- [ ] **Milestone badge earned** — at sobriety milestone date → push with "🎉 You earned the X-day badge"
- [ ] **Crisis alert** (admin/care team only) — alumni posts crisis content → admin device receives URGENT push
- [ ] Tap "New comment" push → app deep-links to that post
- [ ] Tap "Care team message" push → app deep-links to that chat
- [ ] Tap "Account approved" push → app opens home feed
- [ ] All notifications display correct title + body, no template variables ({{name}}, etc.)

## A17 — Settings — Profile section

- [ ] Settings tab opens
- [ ] All sections visible: Profile, Notifications, Privacy, Account, About
- [ ] Profile section shows name, email, phone, facility
- [ ] Tap email → cannot change here (managed via account flow)
- [ ] About section: shows version 1.0 (12)

## A18 — Settings — Notifications

- [ ] Toggle each notification type on/off (community, chat, crisis, badges, daily)
- [ ] Changes persist across app restarts (verify)
- [ ] Push delivery respects toggles (turn off "community" → don't get comment pushes)

## A19 — Settings — Privacy / Security

- [ ] **Face ID / Touch ID toggle** — enable
- [ ] Background app for 30 sec → reopen → biometric prompt
- [ ] Disable Face ID → reopen doesn't prompt
- [ ] **Screenshot protection** — on a chat or sensitive screen, app switcher shows blurred/branded view (NOT actual content)
- [ ] **Screenshot detection** — take screenshot on chat screen → app should detect (toast warning if implemented)

## A20 — Settings — Privacy + Terms links

- [ ] Tap **Privacy Policy** → opens `https://miltonrecovery.com/milton-nation-privacy/` in Safari
- [ ] Page loads (200 OK, not 404)
- [ ] Page contains SMS Program clause and other CTIA disclosures
- [ ] Tap **Terms of Service** → opens `https://miltonrecovery.com/app-terms-of-use/`
- [ ] Page loads correctly
- [ ] Page contains "SMS Messaging Program — Opt-Out and Help" section

## A21 — Settings — Support contact

- [ ] Tap Support → opens email composer with `support@miltonrecovery.com` (or whichever)
- [ ] Subject pre-filled with "App version 1.0 (12)" or similar

## A22 — Settings — Phone number change

**Only testable after 2FA campaign approved.** Skip until then.

- [ ] Tap Change Phone Number
- [ ] Enter new real phone number → SMS arrives at NEW number within 30 sec
- [ ] Enter OTP from new number's SMS → number updated
- [ ] Old number can no longer log in

## A23 — Settings — Sign out

- [ ] Tap Sign Out
- [ ] Confirmation: "Are you sure?"
- [ ] Confirm → returns to login screen
- [ ] All app data cleared (re-sign-in needed)
- [ ] Re-sign-in → all profile data + posts + chats restored

## A24 — Settings — Delete Account

⚠️ Use a test account for this. Don't delete `appreviewer@miltonrecovery.com`.

- [ ] Tap Delete Account
- [ ] Strong confirmation dialog (typed confirmation if required)
- [ ] Confirm → account scheduled for deletion
- [ ] Sign out automatically
- [ ] Try sign in → message: "Account scheduled for deletion, restore within 30 days"
- [ ] Tap Restore → account restored, you can sign in
- [ ] OR (test in dev env only) → after 30 days → permanent deletion → account gone

## A25 — Settings — Export Data

- [ ] Tap Export Data (if implemented)
- [ ] Generates JSON or PDF with all your posts, profile, badges
- [ ] Save to Files / share

---

# SECTION B — FL admin flows

Sign in on SECOND device as **`admin@miltonrecovery.com`**.

## B1 — Admin sign-in

- [ ] Email + password + OTP `000000` → land on admin dashboard (different from alumni home)
- [ ] Dashboard shows: facility (Florida), pending count, flag count

## B2 — Pending Approvals

- [ ] Navigate to Pending Approvals
- [ ] If any pending users exist → list them
- [ ] Tap row → see full profile (name, phone, email, sobriety date, treatment program)
- [ ] Tap Approve → confirmation
- [ ] User receives push notification "You're Approved! 🎉"
- [ ] User can now sign in
- [ ] Tap Reject on another → confirmation → user sees rejection screen + support contact
- [ ] Audit log captures both approve + reject

## B3 — Content Flags queue

- [ ] Navigate to Content Flags / Moderation
- [ ] All flags visible
- [ ] Filter: All / Pending / Reviewed / Dismissed / Escalated — works
- [ ] Sort by date — works
- [ ] Sort by risk level — works
- [ ] Tap flag → details view

## B4 — Flag detail view

- [ ] Shows REDACTED summary (NOT raw post text — verify privacy)
- [ ] Shows: category, risk level, timestamp
- [ ] Shows user info: name, facility (but not other PHI)
- [ ] Three buttons: Review / Escalate / Dismiss

## B5 — Review flag

- [ ] Tap Review → opens review sheet
- [ ] Add optional note
- [ ] Mark Reviewed → flag moves to Reviewed list
- [ ] Audit log captures action

## B6 — Escalate flag

- [ ] Tap Escalate
- [ ] Flag marked high priority
- [ ] Super admin / care team receives push
- [ ] Care team can directly chat the user

## B7 — Dismiss flag

- [ ] Tap Dismiss → marked dismissed
- [ ] Note: dismissals reversible (can re-open)

## B8 — Facility isolation

- [ ] As FL admin, in any list (alumni, flags, posts), confirm ZERO Ohio entries
- [ ] Try deep-link to OH endpoint (if possible via URL) → blocked

## B9 — Broadcast Announcement (if implemented)

- [ ] Admin → Announcements
- [ ] Compose new broadcast
- [ ] Send → appears on FL alumni home feeds (verify via primary device)
- [ ] OH alumni do NOT see FL broadcast (verify by signing into OH alumni account)

## B10 — Admin profile / chat with alumni

- [ ] As admin, open a flagged alumni's chat
- [ ] Send message — alumni receives push + sees in chat

---

# SECTION C — OH admin flows

Sign in as **`admin@miltonjefferson.com`**.

## C1 — OH admin sees only OH data

- [ ] Sign in → land on dashboard
- [ ] Pending Approvals: only OH alumni (zero FL)
- [ ] Content Flags: only OH (zero FL)
- [ ] Cannot see FL admin's announcements

## C2 — OH admin actions

- [ ] Approve an OH alumni → works, push fires
- [ ] Review an OH flag → works
- [ ] Try (impossibly) to escalate to FL care team → not in dropdown

---

# SECTION D — Super admin flows

Sign in as **`super-demo@miltonrecovery.com`**.

## D1 — Super admin sees both facilities

- [ ] Dashboard shows both FL + OH counts
- [ ] Content Flags: FL + OH visible
- [ ] Pending Approvals: FL + OH visible

## D2 — Cross-facility broadcast

- [ ] Compose broadcast → choose audience (FL / OH / Both)
- [ ] Send to Both → appears in BOTH FL + OH alumni feeds

## D3 — User Management

- [ ] Search any user by name, phone, email
- [ ] View any user's full profile (FL or OH)
- [ ] Suspend user → choose 24hr / 7d / permanent
- [ ] Suspended user cannot log in (verify on primary device)
- [ ] Unsuspend → user can log in again
- [ ] Reset password for user (if implemented)

## D4 — Audit Log access

- [ ] Super admin can view audit_logs table content via app or Supabase
- [ ] Filter by user, action, date range

---

# SECTION E — Care team (Case Manager + Therapist + Counselor)

## E1 — Case manager sign-in

Sign in as **`case-manager-demo@miltonrecovery.com`**.

- [ ] Land on case-manager home (different from alumni)
- [ ] See list of ASSIGNED alumni (not all alumni)
- [ ] Each row: name, last activity, days sober
- [ ] Tap alumni → see their profile + chat thread

## E2 — Crisis alert reception

- [ ] Have Alex Demo post crisis content (from primary device)
- [ ] Case manager device receives URGENT push within 30 sec
- [ ] Tap push → opens directly to that alumni's chat or flag detail
- [ ] Can chat alumni directly from there

## E3 — Therapist sign-in

Sign in as **`therapist-demo@miltonrecovery.com`**.

- [ ] Similar to case manager
- [ ] Therapy-specific permissions (if any)

## E4 — Counselor sign-in (if separate from therapist)

- [ ] Same checks as case manager

---

# SECTION F — Emails (Resend)

## F1 — Welcome email

Sign up a brand-new alumni (use second real phone if available, or modify your own).

- [ ] Welcome email arrives within 60 seconds
- [ ] From: `Milton Nation <noreply@miltonrecovery.com>`
- [ ] Subject: `Welcome to Milton Nation`
- [ ] Body title: "Welcome to Milton Nation"
- [ ] Body says: "Your application has been received and is being reviewed."
- [ ] 3 step process listed
- [ ] 988 crisis resource visible
- [ ] Footer: Support / Privacy / Terms links — no Milton Recovery Centers branding, no FL/OH phone numbers
- [ ] Click Privacy link → opens correct page
- [ ] Click Terms link → opens correct page
- [ ] Click Support link → opens email composer
- [ ] Renders correctly on iPhone Mail
- [ ] Renders correctly on Gmail web
- [ ] Renders correctly on Outlook (if applicable)

## F2 — Password reset email (if implemented)

- [ ] Forgot Password → enter email
- [ ] Reset email arrives within 60 sec
- [ ] Link works → password reset page
- [ ] Set new password → can sign in with new

## F3 — Account approved email (if implemented)

- [ ] Admin approves alumni
- [ ] Alumni receives email "You're approved" (separate from push)
- [ ] Email is brand-anonymous

---

# SECTION G — SMS (Twilio)

⚠️ **Most SMS surfaces require the 2FA campaign to be APPROVED.** Until TCR clears it, real SMS won't deliver. Use demo accounts with `000000` for everything else.

## G1 — Demo bypass (works always)

- [ ] Sign in as Alex Demo with `000000` → bypass works, no real SMS
- [ ] No charge on Twilio balance

## G2 — Signup OTP (real SMS)

**Skip until TCR approves campaign.**

- [ ] Sign up with your real phone number
- [ ] SMS arrives within 30 sec
- [ ] Body verbatim: `Your verification code is XXXXXX. It expires in 5 minutes. Do not share this code. Reply STOP to opt out, HELP for help.`
- [ ] No "Milton Nation" prefix
- [ ] Sender is your Twilio number (+17179713757)
- [ ] OTP works to complete signup

## G3 — Login OTP (real SMS)

**Skip until TCR approves campaign.**

- [ ] Sign out, sign back in with real phone account
- [ ] SMS arrives within 30 sec
- [ ] Same body format
- [ ] OTP works

## G4 — Phone number change (real SMS)

**Skip until TCR approves campaign.**

- [ ] Settings → Change Phone Number → enter new real number
- [ ] SMS arrives at NEW number
- [ ] OTP works → number updated in profile

## G5 — STOP keyword

**Skip until TCR approves campaign.**

- [ ] After receiving an OTP, reply STOP
- [ ] Receive auto-response confirming opt-out
- [ ] Try to login → no SMS arrives (you're opted out)
- [ ] Twilio Console shows you on the suppression list

## G6 — Admin invite SMS (KILLED — verify NOT used)

The Marketing campaign was deprecated. send-invite-sms function is dormant.

- [ ] Admin panel does NOT show "Send Invite SMS" button (or it shows "Use email instead")
- [ ] If admin somehow fires it → SMS doesn't deliver (because no approved campaign on Marketing service)

---

# SECTION H — Push Notifications

⚠️ All push tests REQUIRE: device tokens registered (Build 12 fixes this), APNs configured, send-push-notification Edge Function deployed.

## H1 — Permission flow

- [ ] First launch prompts for notifications → tap Allow
- [ ] Settings → Notifications → Milton Nation → all options ON
- [ ] Re-deny → app keeps working

## H2 — Comment push

- [ ] Background app on primary
- [ ] From second device, comment on primary's post
- [ ] Banner arrives within 10 sec
- [ ] Title: name of commenter
- [ ] Body: comment preview or "New comment on your post"
- [ ] Sound + badge ✓
- [ ] Tap banner → opens to that post

## H3 — Care team message push

- [ ] Background app on primary (Alex Demo)
- [ ] From case manager device, send message
- [ ] Banner arrives → opens to chat

## H4 — Account approval push

- [ ] Create a pending signup
- [ ] Admin approves
- [ ] New user receives push "You're Approved! 🎉"

## H5 — Crisis push (admin/care team)

- [ ] Primary posts crisis content
- [ ] Admin device receives URGENT push within 30 sec
- [ ] Push title: "URGENT" or similar
- [ ] Tap → opens admin moderation queue

## H6 — Milestone push

- [ ] Adjust sobriety date so today = milestone (30, 60, 90 days)
- [ ] Force milestone calculation (force quit + reopen)
- [ ] Push arrives: "🎉 You earned the X-day badge"
- [ ] Badge appears on profile

## H7 — Delivery in all 3 app states

- [ ] App foregrounded: in-app banner ✓
- [ ] App backgrounded: banner notification ✓
- [ ] App closed (killed): lock-screen notification ✓

## H8 — Notification settings respected

- [ ] Settings → toggle off "Community" notifications
- [ ] From second device, comment on your post
- [ ] No push arrives ✓
- [ ] Toggle back on → push arrives next time

---

# SECTION I — Edge cases + accessibility

## I1 — Offline mode

- [ ] Enable airplane mode
- [ ] Open app → loads from cache
- [ ] Banner: "You're offline"
- [ ] Tap feed → cached posts visible
- [ ] Compose post → tap Submit → queued OR clear error
- [ ] Disable airplane mode → queued post sends (if implemented)
- [ ] App syncs

## I2 — Backgrounding & screenshot protection

- [ ] On a chat screen, swipe up to home
- [ ] Swipe through app switcher
- [ ] Milton Nation card should show blurred or branded (NOT chat content)
- [ ] Take screenshot in chat → app may show toast warning (if implemented)
- [ ] Screenshot logged to audit_logs

## I3 — Face ID / app lock

- [ ] Settings → enable Face ID
- [ ] Background for 30+ sec → reopen → Face ID prompt
- [ ] Fail Face ID 3 times → fallback to password
- [ ] App lock timeout (5 min) → on return, sign-in required

## I4 — Crash recovery

- [ ] Force-quit during post creation
- [ ] Reopen → draft restored (if implemented) OR clean state
- [ ] No data corruption

## I5 — Network errors

- [ ] Toggle airplane mode mid-request
- [ ] Clean error: "Couldn't post. Please check your connection and try again."
- [ ] Retry button works

## I6 — Slow network

- [ ] Settings → Developer → Network Link Conditioner → 3G
- [ ] App still usable
- [ ] Loading states appear correctly
- [ ] No timeouts before 30 sec

## I7 — Old iOS compatibility

- [ ] Test on lowest supported iOS (per project requirement)
- [ ] All features work, no deprecated API crashes

## I8 — Dynamic Type

- [ ] Settings → Display → Larger Text → max
- [ ] All text scales
- [ ] No truncation, no overlapping UI
- [ ] Critical buttons still tappable

## I9 — Dark Mode

- [ ] Toggle system Dark mode
- [ ] App respects → switches automatically
- [ ] All text readable
- [ ] No invisible white-on-white or black-on-black

## I10 — VoiceOver

- [ ] Enable VoiceOver
- [ ] Navigate every primary screen
- [ ] All buttons have labels
- [ ] All images have alt text
- [ ] Reading order is logical

## I11 — Device sizes

- [ ] iPhone SE (smallest) → no clipping
- [ ] iPhone Pro Max → no awkward spacing
- [ ] iPad (if supported) → either iPad layout OR graceful iPhone-portrait fallback

---

# SECTION J — Performance

## J1 — Launch times

- [ ] Cold launch (app killed): < 3 sec to interactive
- [ ] Hot launch (background): < 1 sec
- [ ] Splash doesn't linger

## J2 — Scroll performance

- [ ] Community feed scrolls smoothly (60fps)
- [ ] No jank loading images
- [ ] Long list (100+ items) doesn't slow down

## J3 — Image upload

- [ ] Single photo: < 5 sec to upload (good network)
- [ ] Multiple photos: parallel uploads work

## J4 — Battery & heat

- [ ] 30 min heavy use → device not noticeably hot
- [ ] Battery drain comparable to similar social apps

---

# SECTION K — Website integration

## K1 — Privacy policy page

- [ ] Open `https://miltonrecovery.com/milton-nation-privacy/` in Safari
- [ ] Loads HTTP 200
- [ ] Title: includes "Milton Nation Privacy"
- [ ] Contains: SMS Program disclosure, "Mobile numbers and SMS opt-in consent data are never shared", Reply STOP, Reply HELP, message frequency, carrier disclaimer
- [ ] All links work
- [ ] No broken images

## K2 — Terms of Use page

- [ ] Open `https://miltonrecovery.com/app-terms-of-use/` in Safari
- [ ] Loads HTTP 200
- [ ] Contains: "SMS Messaging Program — Opt-Out and Help" section
- [ ] Contains: Reply STOP, Reply HELP, message frequency, carrier disclaimer, third-party non-disclosure clause

## K3 — Support page (if exists)

- [ ] Open `https://miltonrecovery.com/app-support` in Safari
- [ ] Loads
- [ ] Has support email, phone, FAQ

## K4 — Main brand site

- [ ] Open `https://miltonrecovery.com/`
- [ ] Loads correctly
- [ ] No mentions of Milton Nation that conflict with app branding

---

# SECTION L — Audit log verification (Supabase query)

After completing Sections A–K, query Supabase to confirm logging is happening.

- [ ] Open Supabase Dashboard → Table Editor → `audit_logs`
- [ ] Filter by today's date
- [ ] Verify entries for: every login, every admin action (approve, reject, escalate, dismiss), every flag creation
- [ ] Check `emergency_access_log` for any admin views of flagged content
- [ ] Every entry has actor user_id, timestamp, action, detail

---

# SECTION M — Final sign-off

When all of A through L are checked:

- [ ] **0 ❌ Showstoppers** open
- [ ] All ⚠️ Polish items logged for v1.1
- [ ] Tested on at least 2 different iPhones (yours + one second device)
- [ ] Tested all 6 role types
- [ ] Welcome email delivers and renders correctly
- [ ] All 6 push notification types delivered (depends on Build 12 device_tokens fix)
- [ ] Privacy + Terms pages live and correct
- [ ] Test passed for FL alumni AND OH alumni AND admins of both facilities

### Sign-off

| | |
|---|---|
| **Tested by** | Ezra Barishansky |
| **Date completed** | _________________ |
| **Build** | 1.0 (12) |
| **Decision** | ☐ Ready to submit to Apple Review · ☐ Re-archive needed (bugs to fix) |
| **Showstopper bugs found** | Count: ____ |
| **P1 bugs found** | Count: ____ |
| **Polish items for v1.1** | Count: ____ |

---

## Sequence after sign-off

If ✅ Ready to submit:
1. App Store Connect → Milton Nation → App Store tab → Edit Version
2. Add this build to the App Store Connect Version
3. Update App Review Notes with reviewer credentials
4. Set Version Release to "Manually release this version"
5. Submit for Review
6. Wait 24–48 hr for Apple email

If ❌ Re-archive needed:
1. Tell Claude every bug
2. Claude patches source + commits + pushes
3. You re-archive (Xcode → Product → Archive → Distribute → Upload)
4. Install new Build via TestFlight
5. Re-run only the sections where bugs were found
6. Repeat until 0 ❌
