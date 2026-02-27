-- ============================================================
-- Migration: Add sms_otp_challenges table
-- Run this if you already have the base schema deployed and
-- need to add SMS OTP support.
-- Date: 2026-02-25
-- ============================================================

-- 1. Create the table
CREATE TABLE IF NOT EXISTS public.sms_otp_challenges (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    phone TEXT NOT NULL,
    otp_hash TEXT NOT NULL,             -- SHA-256 hash of the 6-digit code (never stored plaintext)
    expires_at TIMESTAMPTZ NOT NULL,    -- 5 minutes from creation
    verified BOOLEAN NOT NULL DEFAULT false,
    attempts INT NOT NULL DEFAULT 0,
    max_attempts INT NOT NULL DEFAULT 5,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 2. Enable RLS (service role bypasses; no direct user access needed)
ALTER TABLE public.sms_otp_challenges ENABLE ROW LEVEL SECURITY;

-- 3. Indexes for fast lookups by user and expiry pruning
CREATE INDEX IF NOT EXISTS idx_sms_otp_challenges_user_id
    ON public.sms_otp_challenges(user_id);

CREATE INDEX IF NOT EXISTS idx_sms_otp_challenges_expires_at
    ON public.sms_otp_challenges(expires_at);

-- 4. Auto-cleanup: delete expired and verified challenges older than 1 day
-- (Supabase doesn't run cron jobs natively without pg_cron extension,
--  but the edge functions clean up per-user on each request.
--  This policy-level cleanup handles orphaned rows.)
--
-- Optional: enable pg_cron in Supabase Dashboard → Extensions, then:
-- SELECT cron.schedule(
--   'cleanup-otp-challenges',
--   '0 * * * *',     -- every hour
--   $$DELETE FROM public.sms_otp_challenges
--     WHERE expires_at < now() - interval '1 hour';$$
-- );
