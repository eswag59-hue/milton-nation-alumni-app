# Copy Bank — Push notifications, alerts, and onboarding text

Reference for keeping voice consistent across the app. Use these exactly as written; only change the name + dynamic values.

---

## Push Notifications

### Account approved
- **Title**: `You're Approved! 🎉`
- **Body**: `Your Milton Nation account is now active. Welcome to the community!`

### New comment on your post
- **Title**: `New Comment`
- **Body**: `{commenterName} commented on your post`

### New post in feed
- **Title**: `New Post`
- **Body**: `{authorName} just posted in {category}`

### Care team message received
- **Title**: `{staffName}` (their name as the title)
- **Body**: First 100 chars of the message
- **Sound**: default

### Care team alert (when user toggles "Notify care team")
- **Title** (admin's device): `⚠️ Member Needs Support`
- **Body** (admin's device): `{userName} has requested care team support right now.`
- **Title** (user's device): `Help is on the way`
- **Body** (user's device): `Your care team has been notified and will reach out soon.`

### New member request (admin only)
- **Title**: `New Member Request`
- **Body**: `{fullName} has applied to join Milton Nation.`

### Sobriety milestone
- **Title**: `🏆 {N} Days Sober!`
- **Body**: `You just unlocked the {badgeName} badge. Keep going.`

### Meeting reminder
- **Title**: `Meeting in 30 minutes`
- **Body**: `{meetingTitle} starts at {time}. Tap to view details.`

### Daily reflection
- **Title**: `Daily Reflection`
- **Body**: First sentence of the day's quote, max 80 chars.

---

## In-app Alerts (every alert text the app shows)

### Sobriety reset confirmation
- **Title**: `Reset your sobriety date?`
- **Message**: `This will start your streak over from today. You'll lose your current streak. This action cannot be undone.`
- **Buttons**: `Cancel` | `Reset` (destructive)

### Account deletion (first prompt)
- **Title**: `Delete Account?`
- **Message**: `This will start a 30-day deletion process. Download your data first if you want a copy.`
- **Buttons**: `Cancel` | `Continue`

### Account deletion (final confirmation)
- **Title**: `Permanently Delete Account?`
- **Message**: `Your account, posts, and messages will be permanently deleted after 30 days. You will be logged out immediately.`
- **Buttons**: `Cancel` | `Delete My Account` (destructive)

### Screenshot detected
- **Title**: `Screenshot Detected`
- **Message**: `This app contains protected health information. Please be mindful of screenshots.`

### Device security failed (jailbreak / no biometrics)
- **Title**: `Security Check Failed`
- **Message**: `For your privacy, Milton Nation cannot run on this device. Please ensure your device has a passcode and is not jailbroken, then try again.`

### Network error (generic)
- **Title**: `No Internet Connection`
- **Message**: `Check your connection and try again.`

### Care team notified
- **Title**: `Team Notified`
- **Message**: `Your care team has been notified and will reach out to you soon.`

### Post published (auto-approved)
- **Title**: `Post Published!`
- **Message**: `Your post is live in the community feed.`

### Post pending review
- **Title**: `Post Submitted`
- **Message**: `Post submitted for review.`

### Post flagged for crisis
- **Title**: `Post Submitted`
- **Message**: `Your post has been submitted. A care team member will reach out to you.`

### Login lockout
- **Title**: `Too Many Attempts`
- **Message**: `Too many failed attempts. Try again in {N} minutes.`

### Pending approval
- **Title**: `Account Pending`
- **Message**: `Your application is pending review. We'll notify you once approved!`

---

## Onboarding (first-run experience)

### Welcome screen 1
**Headline**: `Welcome to Milton Nation`
**Body**: `The official alumni app for Milton Recovery Centers. Stay connected to your community, your care team, and your progress.`
**CTA**: `Get Started`

### Welcome screen 2
**Headline**: `Track your recovery`
**Body**: `Mark your sobriety date, earn milestone badges, and celebrate every day clean.`
**CTA**: `Next`

### Welcome screen 3
**Headline**: `You're not alone`
**Body**: `Connect with fellow alumni, message your care team, and find support 24/7.`
**CTA**: `Next`

### Welcome screen 4
**Headline**: `Your privacy is sacred`
**Body**: `Milton Nation is HIPAA-aware. Your data stays encrypted, your conversations stay private, and you control what's shared.`
**CTA**: `Continue`

---

## Empty states

### Community feed (no posts in category)
**Icon**: `person.2.slash`
**Headline**: `No posts yet`
**Body**: `Be the first to share in this category.`
**CTA**: `Create Post`

### Chat list (no care team assigned)
**Icon**: `person.crop.circle.badge.questionmark`
**Headline**: `No care team assigned yet`
**Body**: `Contact an admin to get connected with your counselor or therapist.`

### Meetings list (none nearby)
**Icon**: `calendar.badge.exclamationmark`
**Headline**: `No meetings within 10 miles`
**Body**: `Try expanding your search radius, or check back later.`

### Profile badges (none earned)
**Icon**: `trophy`
**Headline**: `No badges yet`
**Body**: `Keep going. Your first badge is just around the corner.`

---

## Voice & tone guide

- **Direct, never clinical.** Say "you're approved" not "your application has been processed."
- **Recovery-first.** "Days sober" not "days in recovery." "Streak" not "abstinence period."
- **Warm, not saccharine.** "Welcome" beats "Welcome to your healing journey."
- **Action-oriented buttons.** "Create Post" not "Submit". "Reset" not "OK".
- **Avoid medical claims.** Never say "treatment", "cure", "diagnose", or "therapy" except when referring to actual licensed staff roles.
- **Crisis copy is short + warm.** "Help is here. Tap to call." beats "If you are experiencing a mental health emergency, please consider..."
