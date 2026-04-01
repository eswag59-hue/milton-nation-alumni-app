-- =============================================================================
-- Migration: 20260311_performance_and_constraints.sql
-- Performance indexes, data-integrity constraints, and OTP table cleanup.
-- Safe to re-run (all statements use IF NOT EXISTS / DO $$ guards).
-- =============================================================================

-- ---------------------------------------------------------------------------
-- 1. INDEXES on high-cardinality filter columns
--    These columns appear in RLS policies and common queries; without indexes
--    Postgres performs a sequential scan on every row for every auth check.
-- ---------------------------------------------------------------------------

-- profiles: role and status are used in nearly every RLS policy
CREATE INDEX IF NOT EXISTS idx_profiles_role
    ON public.profiles (role);

CREATE INDEX IF NOT EXISTS idx_profiles_status
    ON public.profiles (status);

-- posts: status is used for feed queries and moderation queries
CREATE INDEX IF NOT EXISTS idx_posts_status
    ON public.posts (status);

-- messages: status is used to filter clean/flagged/pending messages
CREATE INDEX IF NOT EXISTS idx_messages_status
    ON public.messages (status);

-- comments: status is used for moderation and feed visibility
CREATE INDEX IF NOT EXISTS idx_comments_status
    ON public.comments (status);

-- content_flags: common admin queries filter by resolved status and risk level
CREATE INDEX IF NOT EXISTS idx_content_flags_review_status
    ON public.content_flags (review_status);

CREATE INDEX IF NOT EXISTS idx_content_flags_risk_level
    ON public.content_flags (risk_level);

-- analytics_events: time-series queries always filter by event_type or user_id
CREATE INDEX IF NOT EXISTS idx_analytics_events_event_name
    ON public.analytics_events (event_name);

CREATE INDEX IF NOT EXISTS idx_analytics_events_user_id
    ON public.analytics_events (user_id);

-- ---------------------------------------------------------------------------
-- 2. CONTENT LENGTH CONSTRAINTS
--    Prevent unbounded TEXT columns from becoming a storage/DoS vector.
--    Server-side constraints complement the client-side 2000-char limit.
-- ---------------------------------------------------------------------------

DO $$
BEGIN
    -- posts.content: max 50,000 characters (server-side ceiling)
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'posts_content_length' AND conrelid = 'public.posts'::regclass
    ) THEN
        ALTER TABLE public.posts
            ADD CONSTRAINT posts_content_length
            CHECK (char_length(content) BETWEEN 1 AND 50000);
    END IF;

    -- comments.content: max 10,000 characters
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'comments_content_length' AND conrelid = 'public.comments'::regclass
    ) THEN
        ALTER TABLE public.comments
            ADD CONSTRAINT comments_content_length
            CHECK (char_length(content) BETWEEN 1 AND 10000);
    END IF;

    -- messages.content: max 10,000 characters
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'messages_content_length' AND conrelid = 'public.messages'::regclass
    ) THEN
        ALTER TABLE public.messages
            ADD CONSTRAINT messages_content_length
            CHECK (char_length(content) BETWEEN 1 AND 10000);
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 3. PHONE FORMAT CONSTRAINT on profiles
--    Prevents invalid phone numbers from reaching Twilio and causing SMS failures.
--    Accepts E.164 format with optional country code (e.g. +12125551234 or 2125551234).
-- ---------------------------------------------------------------------------

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'profiles_phone_format' AND conrelid = 'public.profiles'::regclass
    ) THEN
        ALTER TABLE public.profiles
            ADD CONSTRAINT profiles_phone_format
            CHECK (
                phone IS NULL OR
                phone ~ '^\+?1?[0-9]{10,15}$'
            );
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- 4. PUSH NOTIFICATION LOG TABLE
--    Required for the user-targeted rate limiting added to send-push-notification.
--    Tracks outbound notifications so we can enforce per-sender hourly limits.
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS public.push_notification_log (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sent_by       UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    target_user_id UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    target_roles  TEXT[],
    device_count  INT NOT NULL DEFAULT 0,
    success       BOOLEAN NOT NULL DEFAULT true,
    error_message TEXT,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Index for rate-limit queries (filter by sender + target + time window)
CREATE INDEX IF NOT EXISTS idx_push_log_sent_by_created
    ON public.push_notification_log (sent_by, target_user_id, created_at DESC);

-- RLS: users can only see their own sent logs; admins see all
ALTER TABLE public.push_notification_log ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users view own notification log"
    ON public.push_notification_log FOR SELECT TO authenticated
    USING (sent_by = auth.uid() OR public.is_admin());

CREATE POLICY "Service role inserts notification log"
    ON public.push_notification_log FOR INSERT
    WITH CHECK (true);  -- Edge functions use service role key

-- ---------------------------------------------------------------------------
-- 5. OTP CHALLENGES — enforce hard 24h expiry via database-level cleanup
--    Any challenge older than 24 hours is definitively expired regardless of
--    the expires_at field (defense-in-depth for clock skew or manipulation).
-- ---------------------------------------------------------------------------

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint
        WHERE conname = 'sms_otp_challenges_max_age' AND conrelid = 'public.sms_otp_challenges'::regclass
    ) THEN
        ALTER TABLE public.sms_otp_challenges
            ADD CONSTRAINT sms_otp_challenges_max_age
            CHECK (created_at >= (now() - INTERVAL '24 hours') OR verified = true);
    END IF;
END $$;

-- ---------------------------------------------------------------------------
-- NOTES FOR MANUAL SUPABASE DASHBOARD ACTIONS
-- ---------------------------------------------------------------------------
-- After applying this migration:
-- 1. Enable pg_cron extension (Dashboard → Database → Extensions → pg_cron)
--    Then run the following to auto-purge stale OTP records nightly:
--
--    SELECT cron.schedule(
--        'purge-expired-otp-challenges',
--        '0 3 * * *',
--        $$ DELETE FROM public.sms_otp_challenges
--           WHERE expires_at < now() OR created_at < now() - INTERVAL '24 hours'; $$
--    );
--
-- 2. Confirm DEMO_BYPASS_ENABLED is set to "false" (or deleted) in
--    Dashboard → Edge Functions → Secrets before App Store submission.
--
-- 3. Set APP_STORE_URL secret in Dashboard → Edge Functions → Secrets:
--    APP_STORE_URL = https://apps.apple.com/app/id<YOUR_ACTUAL_APP_ID>
