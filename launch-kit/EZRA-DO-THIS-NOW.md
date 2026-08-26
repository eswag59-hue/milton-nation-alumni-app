# Ezra — do this now (30 minutes, one sitting)

Everything below is verified against the live app and the live database as of
**25 Aug 2026, 17:19 UTC**. Nothing here is a guess. Where I say "this will
happen," I checked.

**What you're producing:** 12 clean iPhone screenshots of the real app. Those
are the raw material for the launch video, the Canva posts, the email, the
newsletter, and the new App Store listing. Until I have real pixels, everything
downstream is me inventing UI — which is exactly what you've been rejecting, and
you were right to.

**Time:** ~30 minutes. **You need:** your iPhone. That's it.

---

## Part 0 — Before you touch anything (2 min)

### 0.1 Update the app

Open the **App Store** → tap your **profile picture** (top right) → scroll to
**Milton Nation Alumni** → tap **Update** if it's there.

Why this matters: the live version is **1.0.1, released today at 9:58am ET**.
The screenshots currently on your App Store listing were captured from an
*older* binary — that's why they show "— Unknown" under the daily quote and the
colour-swatch bar under the logo. Both of those are already fixed in the shipped
code. If you're on the current build, your new screenshots come out clean. If
you're on a stale one, we reproduce the same flaws we're trying to fix.

### 0.2 Turn on Do Not Disturb

Swipe down from the top-right corner → tap the **crescent moon**.

A notification banner sliding into frame ruins a shot, and you won't notice
until I'm compositing it three hours from now.

### 0.3 Check your battery and clock

Ideally: battery above 80%, no red battery icon. Don't obsess — I can clean the
status bar in post — but a full battery and a round-ish time look better if I
end up keeping the real one.

---

## Part 1 — Sign in (5 min)

### 1.1 Open the app

If you're already signed in as anyone, sign out first:
**Profile tab** (bottom right) → **Settings** (gear, top right) → scroll to the
bottom → **Sign Out**.

### 1.2 Enter these exact credentials

| Field | Value |
|---|---|
| Email | `appreviewer@miltonrecovery.com` |
| Password | *(in the chat message — deliberately not written into the repo)* |

The password is in the chat message alongside this document. It's kept out of
the repository on purpose: git history is permanent and shared, and this
account signs in to the production app.

**Read the email twice.** It is `miltonrecovery.com` — **not**
`miltonrecoverycenters.com`. The app's own Profile screen displays the *longer*
one, because the `profiles` table and the `auth.users` table disagree on this
account. I gave you the wrong one earlier from reading the Profile screen; the
sign-in form only accepts the shorter one. That single character difference is
what was failing before.

*(Separate cleanup item, not for today: those two columns should be reconciled.)*

### 1.3 The verification code is `000000`

Six zeros. Type it in.

**No text message will ever arrive.** Don't wait for one. The phone number on
this account is `+1 555 000 1234`, a reserved test number that no carrier
routes. Sign-in works through a demo bypass instead, which I confirmed is live —
the server logged a successful bypass on this exact account at **17:19:39 today**:

```
[verify-sms-otp] Demo bypass used { isTestAccount: true, phoneMatch: false }
```

That's not me hoping it works. That's the server saying it did, an hour ago.

### 1.4 ⚠️ The very first thing you'll see — get this right

A modal appears immediately: **"Welcome Back!"** → *"Are you still on track?"*

### Tap **"Yes, still going strong!"**

**Do NOT tap "I need to reset my date."** That button writes a new sobriety date
to the database and destroys the 3-year streak I staged for these screenshots.
There's no undo, and we'd have to start over.

This modal fires on *every* login, so you'll see it again each time you sign in.
Same answer every time.

### 1.5 What you should be looking at

You'll land on **Home**, signed in as **Alex Demo**, showing:

- **1,096 days** (3 years) of recovery
- **156 weeks**
- **530 points**
- **4 posts**

If you see 13 days, or the name "Ez barish test," stop and tell me — it means the
staging didn't take and every screenshot after that is wasted.

**You will not see an Admin tab.** This account's role is `alumni`, so you get
the member experience and nothing else. That's deliberate: it means the
**"Back to Admin" pill can't appear** — the debug button visible in your current
App Store screenshots is impossible on this login. You don't have to avoid
anything. Just use the app.

---

## Part 2 — Take the 12 screenshots (15 min)

**How to take one:** press **Volume Up + Side button** at the same time, then
let go. Quick tap — hold them and you'll get the power-off slider.

**After each shot, the app shows a "Screenshot Detected" alert.** That's the
HIPAA audit system doing its job. Tap **OK** and keep going — the alert fires
*after* the capture, so your screenshot is already clean. It's logged, which is
correct and expected on a demo account.

Go in this order. Numbers are for naming them back to me.

### Home tab

1. **Home, top** — the streak number and the daily reflection card, as it opens.
2. **Home, scrolled** — scroll down one full swipe, capture what's below.

### Community tab

3. **Feed, top** — the community feed as it first appears.
4. **Feed, scrolled** — one swipe down, so I get a different set of posts.
5. **A post open** — tap into any post with comments on it.
6. **The composer** — tap the **+ / new post** button and capture the empty
   compose sheet. Don't post anything.

### Meetings tab

7. **Meetings list** — the schedule as it appears.
8. **A meeting open** — tap into any single meeting.

### Chat tab

9. **Chat list** — your conversations.
10. **A conversation open** — tap into one with actual messages in it.

### Profile tab

11. **Profile, top** — the 1,096 days, the points, the badges.
12. **Settings** — tap the gear, top right.

### Two bonus shots if you have the patience

13. The **"Welcome Back!"** modal from step 1.4 (sign out and back in to get it).
    It shows the app checking in on someone, which is the emotional core of the
    whole product and a genuinely strong marketing frame.
14. The **login screen itself**, signed out. Useful for the opening beat of the
    video.

---

## Part 3 — Send them to me (3 min)

Easiest path, no computer needed:

1. **Photos** app → **Recents**
2. **Select** (top right) → tap all 12 (they'll be the last 12)
3. **Share** → send them to yourself however you like, or drop them straight
   into this chat from your phone

If you'd rather use the Mac: select them in Photos → **AirDrop** → your Mac →
they land in Downloads → drag into the chat.

**Name them by number if it's easy** (`01`, `02`, …). If not, don't worry about
it — I can tell the screens apart. Don't let naming stop you from sending them.

---

## Part 4 — Reconnect Higgsfield (2 min)

Higgsfield has dropped four separate times in this session. That pattern is an
expiring auth token, not the toggle — flipping it off and on won't hold it.

1. In Claude Code, type `/mcp`
2. Find **higgsfield** in the list
3. If it shows disconnected or errored, select it and **re-authenticate** —
   sign in again rather than just toggling
4. Tell me it's on, and I'll verify before I run anything through it

I'm not going to run the image pipeline against a connection I haven't confirmed
myself. When you caught me shipping a hand-coded CSS frame and calling it
Higgsfield, that was a fair hit. I'd rather check first than get caught again.

---

## What I do the moment your screenshots land

1. Run every screen through the Higgsfield look you approved — the one you said
   you *"literally like all of these"* about — so the app pixels stay real and
   only the environment around them is generated.
2. Cut the flagship launch video from those frames, and show you the first clip
   for approval before I build past it.
3. Build the Canva posts, the email header, the newsletter images, and the
   replacement App Store screenshot set off the same frames, so the whole
   package looks like one campaign instead of five.

---

## Two things that are NOT possible today, so you don't waste a trip

### Screen recording will come out black

The app blacks out the screen during any recording or mirroring — that's the
PHI protection, and on a therapy app it's the right call. I've written the
exemption (`MarketingCapture.swift`: recording is allowed *only* while a
PHI-free demo account is signed in; every real member stays fully protected,
with tests that prove it), but it's on my branch and **not in the 1.0.1 binary
on your phone**.

So: **screenshots today. Recordings after we ship that change**, via TestFlight.
Don't try to record — you'll get a black rectangle and think something's broken.

If you want moving footage sooner, tell me and I'll get the exemption merged and
a TestFlight build out first. That's a real fork in the road and it's your call
which order we do it in.

### The onboarding walkthrough videos need the other logins

The per-role videos (super admin, admin, therapist, case manager, counselor)
need staff accounts, and they need screen recording, which is blocked for the
same reason. Those come after the TestFlight build. The launch marketing —
which is iOS-only, as you specified — doesn't depend on them, so it isn't blocked.

---

## If something goes wrong

| What you see | What it means | What to do |
|---|---|---|
| "Invalid email or password" | Almost certainly the email — `miltonrecovery.com`, not `miltonrecoverycenters.com` | Retype it character by character |
| "Too many failed attempts" | Old lockout still cached from before | Force-quit the app (swipe up, flick it away), reopen. I fixed the underlying bug — it used to lock permanently after 5 lifetime typos — but that fix ships with the next build |
| No text message arrives | Correct and expected | Type `000000`. No SMS is coming, ever |
| Code `000000` rejected | The server-side bypass flag flipped off | Stop and tell me. I can see it in the logs and will say so within a minute |
| Profile shows 13 days | Staging didn't apply | Stop and tell me — don't shoot, I'll re-stage in about 30 seconds |
| A black screen while recording | The PHI protection, working correctly | Expected. See above — recording is out of scope today |

---

## Part 5 — Scroll recordings (5 minutes, only when you want the long scroll)

You asked the film to "scroll through the whole home screen." Right now it can't
— not properly. The screenshots you sent are single-viewport stills: 1320×2868,
which is exactly the phone's screen. There is no content below the fold in them
to scroll *to*. Panning a still just drags its own tab bar up into frame, which
reads as two tab bars stacked.

So in the current cut each screen moves a little — the content pans inside the
phone while the status bar and tab bar stay pinned at true size — but it is a
short move, not a full scroll. That's the honest ceiling on still screenshots.

To get a real full-length scroll I need the content that lives below the fold.
Five screen recordings, about 45 seconds total:

1. Open **Control Centre** → tap the **record** button (⏺).
2. Open the app on **Home**. Wait one second without touching it.
3. Scroll slowly to the bottom of the page — slow and even, roughly three
   seconds top to bottom. Do not flick; a flick blurs every frame.
4. Wait one second at the bottom, then stop.
5. Repeat for **Community**, **Meetings**, **Chat**, **Profile**.

Send the five files. I stitch each recording into one tall image of the full
page, and then the scroll in the film is real footage of your app, at full
length, at whatever pace the edit wants.

**One more, if you can:** on **Meetings**, tap **Nearby** and record scrolling
that list too. The nearby AA/NA screen in the current cut is rendered from the
app's own shipped SwiftUI — the real card layout, the real AA-blue / NA-green
fellowship badges, the real distance pills, the real Directions button — but the
meetings listed in it are stand-ins. A recording replaces them with whatever
BMLT actually returns near you, and that beat stops being a reconstruction.
