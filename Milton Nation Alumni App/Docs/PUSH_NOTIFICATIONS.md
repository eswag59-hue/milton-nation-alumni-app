# Milton Nation — Push Notification Audit

This file lists every push notification the app sends, who receives it,
what triggers it, and where it lives in the codebase. "Local" means it's
scheduled via `UNUserNotificationCenter` on-device (no APNS round-trip);
"Server" means it's dispatched via the `send-push-notification` Supabase
Edge Function and delivered to the recipient's device via APNS.

---

## Alumni (role: `alumni`)

| # | Notification                  | Trigger                                                | Type   | Code                                                  |
|---|-------------------------------|--------------------------------------------------------|--------|-------------------------------------------------------|
| 1 | "Application Submitted ✓"     | Alumni completes signup and submits for review         | Local  | `LoginViewModel.swift:254`                            |
| 2 | "You're Approved! 🎉"          | Admin approves the alumni's pending account            | Server | `SupabaseDataService.swift:929` (`send-push-notification`) |
| 3 | "Welcome to Milton Alumni!"   | (Legacy local fallback for approval)                   | Local  | `AdminViewModel.swift:571`                            |
| 4 | "New Comment"                 | Someone comments on a post the alumni authored         | Local  | `CommunityViewModel.swift:452`                        |
| 5 | "Post Approved"               | Admin approves the alumni's post                       | Local  | `AdminViewModel.swift:819`                            |
| 6 | "Post Not Approved"           | Admin rejects the alumni's post                        | Local  | `AdminViewModel.swift:828`                            |
| 7 | "Privacy Notice"              | An admin invoked emergency access on the alumni's data | Local  | `AdminViewModel.swift:1526`                           |

### Local milestone & engagement reminders
Settings → Notifications toggles (`SettingsScreen.swift:25-31`) control four
categories that the app respects when scheduling:
- **Community** (`notifyCommunity`) — comment/like activity on the alumni's content
- **Chat** (`notifyChat`) — new chat messages
- **Meetings** (`notifyMeetings`) — meeting reminders
- **Milestones** (`notifyMilestones`) — sobriety milestone celebrations (30/60/90/180/365 days)

---

## Admin (role: `admin`)

| # | Notification               | Trigger                                                                                  | Type   | Code                              |
|---|----------------------------|------------------------------------------------------------------------------------------|--------|-----------------------------------|
| 1 | "New Member Request"       | An alumni submits an application that falls under the admin's facility                   | Local  | `AppViewModel.swift:86, 110`      |
| 2 | "⚠️ Member Needs Support"   | An assigned alumni taps "I'm Struggling Today"                                           | Local  | `StrugglingModal.swift:187`       |
| 3 | Crisis content alert       | Content filter flags a chat / post / comment with `flaggedForCrisis` status              | Server | `flag-content` Edge Function fans out via `send-push-notification` |
| 4 | Sobriety reset alert       | An alumni resets their sobriety date (raised via `sobriety_change_log` trigger)          | Server | (server-side notification, surfaces in AdminDashboard "Notifications" tab) |

### Admin-only dashboard surfaces (not push, but worth listing)
- Pending users badge — `AdminDashboardScreen.swift:208`
- Recent badge awards feed — `fetchRecentBadgeAwards`
- Flagged messages feed — `fetchFlaggedMessages`

---

## Super Admin (role: `super_admin`)

Super admin receives **everything an admin receives** plus:

| # | Notification                       | Trigger                                                              | Type   | Code                       |
|---|------------------------------------|----------------------------------------------------------------------|--------|----------------------------|
| 1 | Cross-facility new member request  | Any alumni application across all facilities                         | Local  | `AppViewModel.swift:110`   |
| 2 | Emergency-access audit alert       | Any admin invokes emergency access on any user                       | Local  | `AdminViewModel.swift:1526` (also stored in audit log) |

---

## Device-token plumbing (referenced for completeness)

| Trigger                                       | Action                                              | Code                                  |
|-----------------------------------------------|-----------------------------------------------------|---------------------------------------|
| Successful login                              | Register the APNS device token under the user_id    | `AppViewModel.swift:59`               |
| Logout                                        | Unregister the APNS device token                    | `AppViewModel.swift:167, 214`         |
| Settings toggle change                        | Re-sync notification preferences to the server      | `SettingsScreen.swift:25-31`          |
| First-launch                                  | Prompt for notification permission                  | `AppViewModel.swift:148`              |

---

## Edge Function: `send-push-notification`

Single server-side entry point for cross-device pushes. Called from:
- `SupabaseDataService.approveUser(...)` — "You're Approved! 🎉"
- `SupabaseAuthService.swift:223` — auth-related notifications
- (Implicitly) `flag-content` Edge Function for crisis fan-out to admins

Payload shape (Swift side: `UserApprovalNotifParams`):
```
{ target: "user" | "admin" | "super_admin",
  userId: <recipient user_id>,
  title: <string>,
  body: <string>,
  data: { type: <string>, ...metadata } }
```
