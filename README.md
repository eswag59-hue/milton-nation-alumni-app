# Milton Nation Alumni App

[![Test](https://github.com/eswag59-hue/milton-nation-alumni-app/actions/workflows/test.yml/badge.svg)](https://github.com/eswag59-hue/milton-nation-alumni-app/actions/workflows/test.yml)

The official iOS alumni app for **Milton Recovery Centers**. Provides ongoing recovery support to verified alumni in Florida and Ohio: sobriety tracking, peer community, secure care-team messaging, meeting finder, and crisis support — all built with HIPAA-aware architecture.

> **Status**: Pre-launch. 247 tests passing. Build clean. Awaiting App Store review.

---

## Table of Contents

- [Stack](#stack)
- [Architecture](#architecture)
- [Project Layout](#project-layout)
- [Getting Started](#getting-started)
- [Running Tests](#running-tests)
- [Backend (Supabase)](#backend-supabase)
- [External Services](#external-services)
- [Security & HIPAA](#security--hipaa)
- [Deployment](#deployment)
- [Contributing](#contributing)

---

## Stack

| Layer | Technology |
|---|---|
| **App** | Swift 5.9+, SwiftUI, iOS 18+ deployment target |
| **State** | `@Observable` (Swift Macros), no Combine, no Redux |
| **Backend** | Supabase (Postgres + Realtime + Auth + Storage + Edge Functions) |
| **Auth** | Phone OTP via Twilio + Supabase Auth |
| **Push** | APNs (production tier) + Supabase send-push-notification edge function |
| **Email** | Resend (welcome emails — no PHI) |
| **Meetings** | BMLT public API (real meeting data) |
| **Analytics** | Custom event store in Supabase `analytics_events` (no third-party SDKs) |
| **Crash Reports** | Custom store in Supabase `crash_reports` |

---

## Architecture

```
┌────────────────────────────────────────────────────────────────────┐
│                       SwiftUI Views (17 screens)                    │
│   HomeScreen / CommunityScreen / ChatListScreen / ChatDetailScreen │
│   ProfileScreen / MeetingsScreen / AdminDashboardScreen / ...      │
└──────────────────────────────┬─────────────────────────────────────┘
                               │  reads via @Environment / @Bindable
                               ▼
┌────────────────────────────────────────────────────────────────────┐
│                    @Observable ViewModels (10)                      │
│   AppViewModel / Login / Home / Community / Chat / Meetings /      │
│   Profile / Contacts / Admin / NearbyMeetings                      │
└──────────────────────────────┬─────────────────────────────────────┘
                               │  injects DataServiceProtocol
                               ▼
┌────────────────────────────────────────────────────────────────────┐
│                 Service Layer (26 services)                         │
│  • SupabaseDataService / MockDataService (DataServiceProtocol)     │
│  • SupabaseAuthService / MockAuthService (AuthServiceProtocol)     │
│  • RealtimeService — websocket subscriptions                       │
│  • OfflineCacheService — SQLite                                    │
│  • ContentFilterService + ContentSafetyEngine — moderation         │
│  • PushNotificationService / AnalyticsService / AuditLogger        │
│  • DeviceSecurityService / KeychainService / SessionManager        │
│  • PhoneService / LocationService / NetworkMonitor                 │
└────────────┬───────────────────────────────────┬───────────────────┘
             │                                   │
             ▼                                   ▼
┌──────────────────────────────┐  ┌──────────────────────────────────┐
│     Supabase Postgres        │  │       Edge Functions (7)         │
│  23 tables · RLS on all      │  │  send-sms-otp / verify-sms-otp   │
│  82 indexes · 8 migrations   │  │  send-push-notification          │
│                              │  │  send-welcome-email / flag-content│
│  Storage: post-media,        │  │  send-invite-sms                 │
│  profile-photos, chat-media, │  │  assign-user-facility            │
│  brand-assets                │  │                                  │
└──────────────────────────────┘  └──────────────────────────────────┘
             │
             ├─ Twilio (SMS OTP)
             ├─ APNs (push notifications)
             ├─ Resend (transactional email)
             └─ BMLT API (meeting finder)
```

### Key architectural decisions

- **No Combine.** `@Observable` + `Task` covers every state-flow we need without a publisher graph.
- **Two service protocols** (`DataServiceProtocol`, `AuthServiceProtocol`) with both `Mock*` and `Supabase*` implementations. DEBUG builds use mocks for instant offline iteration; Release builds always hit Supabase.
- **No Firebase, no Sentry, no Mixpanel.** Everything observable runs on Supabase tables, keeping the data inside one HIPAA-aware vendor.
- **Facility isolation via RLS.** A `facility` column on `profiles`, `posts`, and `announcements` plus row-level security policies ensures Florida admins never see Ohio data and vice versa. See `supabase/migrations/20260331_add_facility_isolation.sql`.
- **Realtime first-class.** Every list (chat, posts, pending users, admin queue) subscribes to Postgres changes and reconciles automatically. Foreground transitions trigger `RealtimeService.reconnectIfNeeded()`.

---

## Project Layout

```
Milton Nation Alumni App/
├── Milton Nation Alumni App/        # iOS app source (87 Swift files, 19,500 LOC)
│   ├── Models/                       # 11 plain Codable structs
│   ├── ViewModels/                   # 10 @Observable classes
│   ├── Views/
│   │   ├── Screens/                  # 17 top-level screens
│   │   └── Components/               # 20 reusable components
│   ├── Services/                     # 26 services (data, auth, real-time, safety, etc.)
│   ├── Theme/AppTheme.swift          # Single source of design tokens
│   ├── Config/                       # Debug.xcconfig, Release.xcconfig
│   └── Milton_Nation_Alumni_AppApp.swift  # @main entry point
│
├── Milton Nation Alumni AppTests/    # 16 test files, 247 tests, 18 suites
│
├── supabase/
│   ├── migrations/                   # 9 SQL migrations
│   ├── functions/                    # 7 TypeScript edge functions (Deno)
│   ├── seed_admin_accounts.sql       # Florida + Ohio admin seeding
│   └── setup_ohio.md                 # Multi-facility deployment runbook
│
├── docs/                             # GitHub Pages — privacy, terms, support
└── .github/workflows/                # CI: builds + runs all 247 tests on every push
```

---

## Getting Started

### Prerequisites

- **Xcode 16** (or later)
- **iOS 18 simulator** (the project targets `iPhone 16e` for tests; any iOS 18+ device works)
- **Apple Developer account** with the project's bundle ID provisioned (`milton-recovery-centers.Milton-Nation-Alumni-App`)

### One-time setup

1. Clone the repo and open `Milton Nation Alumni App.xcodeproj`.
2. The Supabase URL and anon key are committed to source (anon key is **public by design** — see `Services/SupabaseConfig.swift`).
3. In **Signing & Capabilities**, set Team to **Milton Health Group LLC**.
4. Build & run.

### DEBUG mode (default)

DEBUG builds use `MockAuthService` + `MockDataService`. You can sign in with:

| Email | Role |
|---|---|
| any email except the ones below | Alumni user |
| `admin@milton.com` | Florida admin |
| `super@milton.com` | Super admin |
| `therapist@milton.com` | Therapist (staff view) |
| `case@milton.com` | Case manager (staff view) |
| `counselor@milton.com` | Counselor (staff view) |

Any 6-digit number works as the OTP.

### Release mode

Release builds use `SupabaseAuthService` + `SupabaseDataService` and hit production. Real phone numbers receive real Twilio SMS.

---

## Running Tests

```bash
xcodebuild test \
  -project "Milton Nation Alumni App.xcodeproj" \
  -scheme "Milton Nation Alumni App" \
  -destination "platform=iOS Simulator,name=iPhone 16e"
```

Expected output: `Test run with 247 tests in 18 suites passed`.

GitHub Actions runs the same command on every push and PR — see `.github/workflows/test.yml`.

---

## Backend (Supabase)

**Project ID**: `hksxzuytcmqqwxmfjzdp`
**URL**: `https://hksxzuytcmqqwxmfjzdp.supabase.co`

### Tables (23 total, all RLS-enabled)

`profiles`, `posts`, `comments`, `likes`, `messages`, `conversations`, `staff_assignments`,
`meetings`, `meeting_rsvps`, `badges`, `user_badges`, `sobriety_milestones`,
`announcements`, `daily_quotes`, `audit_logs`, `analytics_events`, `crash_reports`,
`content_flags`, `moderation_keywords`, `device_tokens`, `push_notification_log`,
`emergency_access_log`, `sms_otp_challenges`, `sobriety_change_log`

### Migrations

```
supabase/migrations/
├── 20260225_add_sms_otp_challenges.sql
├── 20260226002_add_content_flags.sql
├── 20260226_security_rls_fixes.sql
├── 20260302_add_analytics_events.sql
├── 20260302_add_crash_reports.sql
├── 20260304_add_emergency_access_log.sql
├── 20260311_performance_and_constraints.sql
├── 20260331_add_facility_isolation.sql
└── 20260506_add_sobriety_change_log.sql
```

Apply via Supabase SQL Editor in chronological order.

### Edge Functions

| Function | Purpose | Auth |
|---|---|---|
| `send-sms-otp` | Twilio SMS sender for login OTP | JWT |
| `verify-sms-otp` | OTP code verification + session minting | JWT |
| `send-invite-sms` | Send invite link to new alumni | JWT (admin) |
| `send-push-notification` | APNs push fan-out | JWT (admin) |
| `send-welcome-email` | Resend transactional email post-approval | JWT (admin) |
| `flag-content` | Server-side moderation escalation | JWT |
| `assign-user-facility` | Admin RPC for setting a user's facility | JWT (admin) |

Deploy with `supabase functions deploy <name>`.

### Required Secrets

- `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_PHONE_NUMBER`
- `RESEND_API_KEY`
- `APNS_KEY_ID`, `APNS_TEAM_ID`, `APNS_PRIVATE_KEY`
- `APP_URL` (base URL for email links — `https://miltonrecovery.com`)
- `DEMO_BYPASS_ENABLED` — set `true` only during App Store review; `false` in prod
- `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, `SUPABASE_DB_URL` (auto-managed by Supabase)

### Storage

- `post-media` (private, 10MB cap, image/video MIMEs)
- `profile-photos` (private, 10MB cap, image/video MIMEs)
- `chat-media` (private, 10MB cap, image/video MIMEs)
- `brand-assets` (public)

---

## External Services

| Service | What it does | BAA? |
|---|---|---|
| **Supabase** | Postgres, Auth, Storage, Edge Functions, Realtime | Yes (Pro plan or higher) |
| **Twilio** | A2P 10DLC SMS for OTP login | BAA available — required for HIPAA |
| **Resend** | Welcome emails post-approval | **No BAA** — never include PHI in emails |
| **APNs (Apple)** | Push notifications | N/A (Apple service) |
| **BMLT API** | Public meeting database | N/A (public, read-only) |

---

## Security & HIPAA

The app is built HIPAA-aware:

- **Encryption in transit**: all network is TLS 1.2+; ATS enforces it.
- **Encryption at rest**: Supabase encrypts all rows + Storage objects.
- **Phone OTP** + **Face ID** for re-auth — credentials never touch the JS bridge.
- **Keychain** for the Supabase auth token (`KeychainService`).
- **Screenshot detection + background blur** (`ScreenshotProtection`, `SessionManager`).
- **Jailbreak detection** (`DeviceSecurityService`) — non-dismissible alert.
- **RBAC + RLS**: every Postgres table has policies. Admins can only see their facility.
- **Audit logging**: `audit_logs` table records every privileged action (`AuditLogger`).
- **Content moderation**: 257-keyword detection + crisis escalation (`ContentSafetyEngine`).
- **Session timeout** + auto-logout on background (`SessionManager`).
- **No PHI in logs**, no PHI in emails, no PHI in third-party SDKs.

See `supabase/migrations/20260226_security_rls_fixes.sql` for a complete RLS policy listing.

---

## Deployment

### TestFlight / App Store

1. Set Xcode signing team to **Milton Health Group LLC** (`9P9N377D6K`).
2. **Product → Archive** with "Any iOS Device" selected.
3. Distribute → App Store Connect → Upload.
4. Wait ~10 min for processing.
5. Attach build to version in App Store Connect → submit for review.

### Edge Functions

```bash
supabase functions deploy send-sms-otp
supabase functions deploy verify-sms-otp
# ... etc
```

### Migrations

Apply manually via Supabase SQL Editor (Dashboard → SQL Editor) in chronological order.

---

## Contributing

This is a private codebase for Milton Health Group LLC. External contributions are not accepted.

For internal contributions:

1. Branch off `main`.
2. Make changes; ensure all tests still pass (`Cmd+U`).
3. Commit with a descriptive message.
4. Open a PR — CI will run all 247 tests.
5. Squash-merge after review.

---

## License

Proprietary. All rights reserved by Milton Health Group LLC.
