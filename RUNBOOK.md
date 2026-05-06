# Runbook

Operational playbooks for running Milton Nation in production.

---

## Incident response — quick reference

### 1. Users can't sign up / log in (SMS OTP failing)

**Symptoms**: Signups fail at the OTP step. Users say "I never received a code."

**Likely causes** (in order):

1. **Twilio A2P 10DLC Campaign rejected/expired** → US carriers block all messages.
   - Check: https://console.twilio.com/us1/develop/sms/regulatory-compliance/brands
   - Fix: Resubmit campaign, contact Twilio support.

2. **Twilio account suspended** (billing, abuse complaints).
   - Check: Twilio Console homepage shows red banner.
   - Fix: Update billing or respond to abuse ticket.

3. **`TWILIO_PHONE_NUMBER` secret rotated** without updating Supabase.
   - Check: `curl https://api.supabase.com/v1/projects/hksxzuytcmqqwxmfjzdp/secrets` (with management token).
   - Fix: Update secret in Supabase Dashboard → Functions → Secrets.

4. **`send-sms-otp` edge function deployment broken**.
   - Check: Supabase Dashboard → Edge Functions → send-sms-otp → Logs.
   - Fix: Roll back via `supabase functions deploy send-sms-otp` from a known-good git commit.

**Mitigation**: Enable `DEMO_BYPASS_ENABLED=true` temporarily so existing users can still sign in via the demo path while you fix.

---

### 2. Push notifications stopped working

**Symptoms**: Users not receiving "new comment" / "approved" / "care team alert" pushes.

**Likely causes**:

1. **APNs key expired**. Apple keys don't expire automatically, but if you rotated yours:
   - Check: developer.apple.com → Keys → look for the key referenced in `APNS_KEY_ID`.
   - Fix: Generate a new key, download .p8, update `APNS_KEY_ID` + `APNS_PRIVATE_KEY` Supabase secrets.

2. **APNs Team ID mismatch** — common when switching from personal to LLC team.
   - Check: `APNS_TEAM_ID` Supabase secret should be `9P9N377D6K`.
   - Fix: Update secret.

3. **Bundle ID change** — production push key is bound to the App ID.
   - Check: Bundle ID in Xcode matches the App ID with Push capability.

4. **`device_tokens` table empty** — no devices registered.
   - Check: SQL → `SELECT count(*) FROM device_tokens;`
   - Fix: Users need to grant notification permission. Check `requestNotificationPermissionIfNeeded`.

---

### 3. Real-time updates not arriving

**Symptoms**: New posts/messages don't appear without manual refresh.

**Likely causes**:

1. **Foreground reconnect notification not firing**. Should auto-fire via `scenePhase`.
   - Workaround: kill + relaunch app.
   - Permanent fix: see `Milton_Nation_Alumni_AppApp.swift` scenePhase handler.

2. **RLS policy regression** — new policy added that excludes the user's row.
   - Check: SQL → run as the user's auth UUID.
   - Fix: Roll back the offending policy.

3. **Supabase Realtime quota exceeded** (Free tier: 200 concurrent connections).
   - Check: Supabase Dashboard → Project Settings → Usage.
   - Fix: Upgrade to Pro plan.

---

### 4. Admin dashboard shows wrong / missing data

**Symptoms**: Florida admin sees Ohio data, or admin sees empty alumni roster.

**Likely causes**:

1. **`admin_facility` is NULL** on the admin's profile.
   - Check: `SELECT email, role, admin_facility FROM profiles WHERE role IN ('admin','super_admin');`
   - Fix: `UPDATE profiles SET admin_facility = 'florida' WHERE email = '...'`

2. **RLS policy missing facility filter** on a table.
   - Check: `SELECT * FROM pg_policies WHERE tablename = 'X';`
   - Fix: Re-apply `20260331_add_facility_isolation.sql`.

---

### 5. Crash reports not arriving

**Symptoms**: `crash_reports` table not growing despite known crashes.

**Likely causes**:

1. **`CrashReportingService.install()` not called** at app launch.
   - Check: `Milton_Nation_Alumni_AppApp.init()` should call it before any async work.

2. **`CrashReportingService.persistToSupabase` is false**.
   - Check: Should be `true` in Release builds.

---

## Routine maintenance

### Weekly

- Review `audit_logs` for unusual admin actions (`SELECT * FROM audit_logs WHERE event_type IN ('promote_user','export_data','deny_flagged_message') ORDER BY created_at DESC LIMIT 50;`)
- Check Supabase storage usage — alert if approaching plan limit.
- Verify no rows in `crash_reports` newer than 24h that match known issues.

### Monthly

- Test demo bypass account (`+15550001234`).
- Verify Resend domain is still verified (https://resend.com/domains).
- Review Twilio A2P campaign — confirm "Approved" status.
- Run `supabase db dump` and back up locally.
- Rotate any secrets that have been exposed (e.g., a developer left).

### Quarterly

- HIPAA risk assessment review.
- Update privacy policy with any new data collection.
- Penetration test on the auth flow.
- Review every RLS policy — confirm no over-permissive `USING (true)` slipped in.

---

## Scaling thresholds

| Metric | Threshold | Action |
|---|---|---|
| Concurrent realtime connections | 80% of plan limit | Upgrade Supabase plan |
| Storage usage | 80% of plan limit | Audit large objects, prune old chat-media |
| Edge function invocations | 80% of plan limit | Cache aggressively, batch where possible |
| Database CPU | sustained > 60% | Add indexes, upgrade compute |
| Auth signups/day | > 100 | Verify A2P daily SMS quota |

---

## Disaster recovery

### Database lost

- Supabase Pro plan includes daily backups + 7 days of PITR.
- Restore via Supabase Dashboard → Database → Backups → Restore.
- For deeper history: every Friday, run `supabase db dump > backups/$(date +%F).sql` and store off-site.

### App pulled from App Store

- Apple may pull for guideline issues. Common: privacy nutrition label drift, age-rating mismatch, demo bypass not disabled.
- Check the rejection email — most issues fix in ≤1 hour.
- Submit a new build with the fix and an "Expedited Review" request.

### Compromised admin account

- Rotate the admin's password immediately.
- Revoke their Keychain token: `UPDATE profiles SET status = 'deactivated' WHERE id = '<admin_id>'`
- Audit `audit_logs` for everything that admin did in the last 7 days.
- Re-issue access only after MFA reset.

---

## Contact escalation

| Severity | Who | How |
|---|---|---|
| App down for all users | On-call dev | Slack #milton-on-call + phone |
| Single user can't access | Support | support@miltonrecovery.com |
| Data privacy concern | Privacy officer | privacy@miltonrecovery.com (HIPAA-trained) |
| Apple-related issue | Developer relations | Open Apple Developer Support ticket |
| Twilio-related issue | Twilio support | https://console.twilio.com/us1/help |
| Supabase-related issue | Supabase support | support@supabase.com or Discord |
