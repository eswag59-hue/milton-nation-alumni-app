# Architecture Decision Records

Each section explains a significant architectural choice — what we picked, what we didn't, and why.

---

## ADR-001: Supabase as the only backend

**Decision**: All persistence, auth, storage, real-time, and serverless logic runs on Supabase. No Firebase, no AWS, no third-party data plane.

**Why**:
- HIPAA-aware vendor with a single BAA (Pro plan).
- Postgres + RLS gives us facility isolation enforced at the database, not the app.
- Built-in Realtime over WebSocket eliminates the need for a custom socket server.
- Edge Functions (Deno) handle anything we'd have used Lambda for.

**Trade-offs**:
- Single-vendor risk. Mitigated by: standard Postgres → migration to RDS or Cloud SQL is straightforward; storage uses S3-compatible API.
- Auth is tied to Supabase. The app's auth abstraction (`AuthServiceProtocol`) lets us swap implementations without touching ViewModels.

---

## ADR-002: `@Observable` + Tasks, no Combine

**Decision**: Every ViewModel uses Swift's `@Observable` macro. State mutations happen on the MainActor inside `Task` blocks. No `Combine`, no `@Published`, no `Publisher` chains.

**Why**:
- `@Observable` is the future of SwiftUI state. It's structural-sharing-friendly and avoids `ObservableObject`'s view-invalidation overhead.
- Concurrency primitives (`async/await`, `MainActor`, `Task.cancelled`) cover what we previously used `Combine` for: debouncing, cancellation, error pipelines.
- Junior-friendly: a `Task` block reads top-to-bottom; a `.flatMap(.publisher).eraseToAnyPublisher()` chain doesn't.

**Trade-offs**:
- No `Publisher`-based plug-ins. We don't need any.
- Re-running async work on retry requires manual task references (e.g., `loadConversationsTask?.cancel()` in `ChatViewModel`). Pattern is consistent across all VMs.

---

## ADR-003: Two-protocol service layer (Mock + Supabase)

**Decision**: `DataServiceProtocol` and `AuthServiceProtocol` each have a `Mock*` and `Supabase*` implementation. The choice happens once in `Milton_Nation_Alumni_AppApp.init()` based on `#if DEBUG`.

**Why**:
- Lets developers iterate on UI without Supabase running.
- Lets the test suite run zero-network in <2 seconds for 247 tests.
- Forces a clean abstraction: every screen consumes data through a protocol, never through `SupabaseClient`.

**Trade-offs**:
- Need to maintain two implementations. Real cost is ~10% of feature time.
- Risk of mock divergence. Mitigated by: tests assert against `MockDataService`; production smoke testing covers the `SupabaseDataService` path.

---

## ADR-004: Facility isolation via Postgres RLS, not separate clients

**Decision**: One Supabase project, one client. Florida and Ohio data live in the same tables — separated by a `facility` column and RLS policies that filter rows server-side.

**Why**:
- Single backend = single deploy pipeline + single set of secrets + single migration history.
- RLS is unbypassable from the client. Even a compromised admin token can't see other facilities.
- Super-admins (`admin_facility = NULL`) get cross-facility view by policy, not by switching clients.

**Trade-offs**:
- Missing a `WHERE facility = X` filter in app code is harmless because RLS will enforce it. But if we ever forget to set `facility` on insert, the row is invisible to everyone.
- Mitigated by: `INSERT` triggers + `NOT NULL CHECK (facility IS NOT NULL)` on the columns.

See `supabase/migrations/20260331_add_facility_isolation.sql`.

---

## ADR-005: Phone OTP, no passwords (for alumni)

**Decision**: Alumni log in with phone + 6-digit SMS OTP. No password screen exists for them.

**Why**:
- Recovery alumni should never have to remember a password.
- Phone is already verified at registration via Twilio.
- A2P 10DLC + Supabase Auth handle rate-limiting and replay protection.

**Trade-offs**:
- SMS deliverability is a vector for attack (SIM swap). Mitigated by: device binding via Keychain + `lastLogin` audit, and OTP TTL of 10 min.
- Admins still log in with email + password (different surface, more sensitive).

---

## ADR-006: Content moderation in 3 tiers

**Decision**: Every post / comment / message runs through:

1. **Local sync scan** — `ContentSafetyEngine` matches against a 257-keyword database (4 categories × 3 risk tiers).
2. **Server escalation** — `ContentFilterService.analyzeAndEscalate` calls the `flag-content` edge function for high-risk items.
3. **Admin review queue** — flagged items appear in `AdminDashboardScreen` for human triage.

**Why**:
- Local scan catches 90%+ of issues with zero latency, zero cost, and no PHI leaving the device.
- Server escalation gives admins audit trail and let us tune detection without app updates (once `moderation_keywords` table is wired up).
- Human review is the final safety net for edge cases.

**Trade-offs**:
- Keyword matching has false positives. Mitigated by: 3 risk tiers (high → auto-flag, medium → admin review, low → log only).
- No ML scoring. Acceptable for v1; consider hosted model post-launch.

---

## ADR-007: No third-party analytics or crash SDKs

**Decision**: Analytics events go to Supabase `analytics_events`. Crashes go to Supabase `crash_reports`. We do not use Mixpanel, Amplitude, Sentry, Bugsnag, or any other vendor.

**Why**:
- Recovery data is sensitive; piping it through ad-tech vendors is a privacy risk.
- Single BAA, single data plane, single audit trail.
- Supabase RLS lets us scope analytics to admin viewers only.

**Trade-offs**:
- We rebuild basic dashboards ourselves. We can dump rows from Supabase Studio for v1; consider Metabase or Grafana post-launch.
- No symbolicated crash reports out of the box. `CrashReportingService` records `NSError` + context strings; we accept this for v1.

---

## ADR-008: Real-time foreground reconnect via NotificationCenter

**Decision**: When the app comes to foreground, `RealtimeService.reconnectIfNeeded()` posts `RealtimeService.reconnectNeeded`. Every ViewModel that holds a Realtime subscription observes the notification and re-subscribes.

**Why**:
- WebSocket connections drop when the app goes to background (iOS suspends networking).
- A central reconnect signal beats every ViewModel having its own scenePhase observer.
- The notification is fire-and-forget — any new VM that adds a subscription just observes the same notification.

**Trade-offs**:
- All VMs must remove their observer in `deinit` — pattern is consistent and tested.
- No fancy backoff out of the box. Added in `backoffAndRetry(attempt:)` for transient failures.

---

## ADR-009: Offline-first analytics queue

**Decision**: `AnalyticsService` persists buffered events to UserDefaults. When the network reconnects (`NetworkMonitor.didReconnect`), it auto-flushes.

**Why**:
- Network outages during recovery sessions shouldn't lose engagement data.
- Crash-during-flush would lose in-memory events; persistence solves both.
- `UserDefaults` is fine for ≤1000 small JSON events; if we exceed that we'd switch to SQLite.

**Trade-offs**:
- Bounded queue (1000 events). Oldest dropped on overflow. Acceptable — telemetry is best-effort, not an audit trail.

---

## ADR-010: Build-flavor service switch happens at app entry, not runtime

**Decision**: `Milton_Nation_Alumni_AppApp.init()` picks `MockAuthService` or `SupabaseAuthService` based on `#if DEBUG` and constructs `AppViewModel` with that choice. No runtime toggle exists.

**Why**:
- Eliminates an entire class of "is mock or real" bugs.
- DEBUG = always mock = always offline-capable.
- Release = always real = no way for a deployed app to silently use mocks.

**Trade-offs**:
- TestFlight builds use the same `Release` configuration as App Store builds. There's no "staging" middle ground. If we add staging, we'd add a third `STAGING` xcconfig + a separate Supabase project.

---

## ADR-011: 247 unit tests, no UI tests (yet)

**Decision**: Every ViewModel and Service has unit tests. No XCUITest UI tests exist for v1.

**Why**:
- Unit tests run in <2 seconds. Total CI time stays under 5 minutes.
- UI tests are flakier and 10× slower. Cost/value isn't there for a first launch.
- 247 tests cover every business-logic path; UI is comparatively thin (most screens delegate everything to a VM).

**Trade-offs**:
- No automated regression detection for visual changes. Acceptable for a small team that does manual smoke testing on every release.
- Plan to add ~20 UI tests post-launch covering the 6 most critical user journeys (login, post create, send message, sobriety reset, struggling mode, contacts edit).

---

## ADR-012: One-shot demo bypass, env-gated

**Decision**: A reviewer demo account (`+15550001234` / `000000`) bypasses real SMS. Gated behind `DEMO_BYPASS_ENABLED=true` env var on the `verify-sms-otp` edge function.

**Why**:
- Apple App Store review needs to test the app without using a real phone.
- Hard-coding the bypass without a kill switch would be a permanent vulnerability.
- Env var lets us flip it on for review week and off for public launch with one click.

**Trade-offs**:
- Forgetting to flip it off post-approval would mean anyone who guesses the demo phone can sign in. Mitigated by: launch checklist Phase 9.1 (the very first post-approval task).
