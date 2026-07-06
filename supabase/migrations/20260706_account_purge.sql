-- ============================================================
-- Account Purge (30-day permanent deletion)
-- ============================================================
-- Implements the "Delete My Account" promise: when a member deletes their
-- account it is marked `deactivated` (grace period). 30 days later this job
-- HARD-DELETES their personal data (PII + their posts/comments/messages/likes/
-- device tokens) and sets status = 'deleted'.
--
-- RETAINED for HIPAA / audit / clinical-legal reasons (NOT deleted):
--   • audit_logs        — immutable 6-year audit trail (who did what).
--   • content_flags     — redacted safety flags (no raw text / no PII). We
--                          de-identify by nulling user_id but keep the record.
--
-- NOTE: The exact retention scope below (what is deleted vs. kept) MUST be
--       reviewed and signed off by legal + clinical before go-live. See the
--       "DELETE" vs "RETAIN" sections and adjust to match the BAA / policy.
--
-- Run in Supabase SQL Editor: Dashboard → SQL Editor → New Query.
-- pg_cron MUST be enabled (Dashboard → Database → Extensions → enable `pg_cron`)
-- for the daily schedule at the bottom to run. The purge function can also be
-- invoked manually (or via the `purge-accounts` Edge Function) at any time.
-- ============================================================

-- 1. Track when deletion was requested (starts the 30-day clock).
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS deactivated_at TIMESTAMPTZ;

CREATE INDEX IF NOT EXISTS profiles_deactivated_at_idx
    ON public.profiles (deactivated_at)
    WHERE status = 'deactivated';

-- 2. The purge function.
--    SECURITY DEFINER so it runs with the owner's privileges (bypasses RLS)
--    when invoked by pg_cron or the service-role Edge Function.
CREATE OR REPLACE FUNCTION public.purge_deactivated_accounts()
RETURNS TABLE (purged_count INT)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_cutoff  TIMESTAMPTZ := now() - INTERVAL '30 days';
    v_ids     UUID[];
    v_count   INT := 0;
BEGIN
    -- Which accounts are past the 30-day grace period?
    SELECT array_agg(id) INTO v_ids
    FROM public.profiles
    WHERE status = 'deactivated'
      AND deactivated_at IS NOT NULL
      AND deactivated_at < v_cutoff;

    IF v_ids IS NULL OR array_length(v_ids, 1) IS NULL THEN
        purged_count := 0;
        RETURN NEXT;
        RETURN;
    END IF;

    -- ── DELETE personal / user-generated data ────────────────────────────────

    -- Likes the user gave (on anyone's posts).
    DELETE FROM public.likes WHERE user_id = ANY(v_ids);

    -- Comment likes, if that table exists (created outside the tracked schema).
    IF to_regclass('public.comment_likes') IS NOT NULL THEN
        EXECUTE 'DELETE FROM public.comment_likes WHERE user_id = ANY($1)' USING v_ids;
    END IF;

    -- Comments the user made on anyone's posts.
    DELETE FROM public.comments WHERE user_id = ANY(v_ids);

    -- Posts the user authored (ON DELETE CASCADE removes their comments/likes).
    DELETE FROM public.posts WHERE user_id = ANY(v_ids);

    -- Chat messages the user sent.
    DELETE FROM public.messages WHERE sender_id = ANY(v_ids);

    -- Conversations the user is the alumni participant in (cascades messages).
    DELETE FROM public.conversations WHERE user_id = ANY(v_ids);

    -- Push device tokens.
    DELETE FROM public.device_tokens WHERE user_id = ANY(v_ids);

    -- Gamification / milestone rows (personal progress).
    DELETE FROM public.user_badges          WHERE user_id = ANY(v_ids);
    DELETE FROM public.sobriety_milestones  WHERE user_id = ANY(v_ids);
    DELETE FROM public.meeting_rsvps        WHERE user_id = ANY(v_ids);

    -- Staff assignments referencing the user (as alumni or as staff).
    DELETE FROM public.staff_assignments WHERE user_id = ANY(v_ids) OR staff_id = ANY(v_ids);

    -- Sobriety change history (personal clinical-adjacent data).
    IF to_regclass('public.sobriety_change_log') IS NOT NULL THEN
        EXECUTE 'DELETE FROM public.sobriety_change_log WHERE user_id = ANY($1)' USING v_ids;
    END IF;

    -- Blocked-user rows (both directions).
    IF to_regclass('public.blocked_users') IS NOT NULL THEN
        EXECUTE 'DELETE FROM public.blocked_users WHERE blocker_id = ANY($1) OR blocked_id = ANY($1)' USING v_ids;
    END IF;

    -- ── RETAIN but DE-IDENTIFY safety flags (HIPAA-safe: already redacted) ────
    -- content_flags carries only redacted metadata (no raw text). We keep the
    -- record for safety review but sever the identity link.
    UPDATE public.content_flags SET user_id = NULL WHERE user_id = ANY(v_ids);

    -- audit_logs are intentionally UNTOUCHED (immutable audit trail).

    -- ── REDACT the profile row itself ────────────────────────────────────────
    -- Columns are NOT NULL, so we overwrite PII with non-identifying sentinels
    -- rather than deleting the row (deleting would orphan retained audit refs).
    UPDATE public.profiles p
    SET
        full_name          = 'Deleted User',
        username           = 'deleted_' || replace(p.id::text, '-', ''),
        email              = 'deleted-' || replace(p.id::text, '-', '') || '@removed.invalid',
        phone              = NULL,
        profile_photo_url  = NULL,
        recovery_program   = '',
        sobriety_date      = DATE '1970-01-01',
        discharge_date     = DATE '1970-01-01',
        mfa_method         = NULL,
        status             = 'deleted',
        updated_at         = now()
    WHERE p.id = ANY(v_ids);

    v_count := array_length(v_ids, 1);

    -- Audit the purge itself (retained record that a purge occurred).
    INSERT INTO public.audit_logs (action, user_id, detail, timestamp)
    SELECT 'account_purged', unnest(v_ids), 'Personal data purged after 30-day grace period', now();

    purged_count := v_count;
    RETURN NEXT;
END;
$$;

-- 3. Daily schedule via pg_cron (runs 03:30 UTC every day).
--    REQUIRES the `pg_cron` extension to be enabled in the dashboard first:
--    Dashboard → Database → Extensions → search "pg_cron" → Enable.
--    If pg_cron is not enabled this block is skipped gracefully; enable it and
--    re-run this migration (or just this DO block) to install the schedule.
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'pg_cron') THEN
        -- Unschedule any prior version so re-running is idempotent.
        IF EXISTS (SELECT 1 FROM cron.job WHERE jobname = 'purge-deactivated-accounts') THEN
            PERFORM cron.unschedule('purge-deactivated-accounts');
        END IF;

        PERFORM cron.schedule(
            'purge-deactivated-accounts',
            '30 3 * * *',
            $cron$ SELECT public.purge_deactivated_accounts(); $cron$
        );
    ELSE
        RAISE NOTICE 'pg_cron is not enabled — skipping schedule install. Enable pg_cron in the dashboard and re-run this migration to schedule the daily purge.';
    END IF;
END;
$$;

-- 4. Lock the function down: only the owner / service role should execute it.
REVOKE ALL ON FUNCTION public.purge_deactivated_accounts() FROM PUBLIC;
REVOKE ALL ON FUNCTION public.purge_deactivated_accounts() FROM anon, authenticated;
