-- ============================================================
-- Migration: Add content_flags table
-- Date: 2026-02-26
-- Purpose: Store redacted content safety flags for admin review.
--          NEVER contains raw user text — only category metadata.
-- ============================================================

-- ── Table ────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.content_flags (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id          UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    risk_level       TEXT NOT NULL
                         CHECK (risk_level IN ('low_risk', 'medium_risk', 'high_risk')),
    categories       TEXT[] NOT NULL,
    feature          TEXT NOT NULL,
    -- Redacted summary ONLY — no raw user text stored here (HIPAA)
    redacted_summary TEXT NOT NULL,
    is_emergency     BOOLEAN NOT NULL DEFAULT false,
    review_status    TEXT NOT NULL DEFAULT 'pending'
                         CHECK (review_status IN ('pending','reviewed','dismissed','escalated')),
    reviewed_by      UUID REFERENCES public.profiles(id) ON DELETE SET NULL,
    review_note      TEXT,
    timestamp        TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ── Indexes ──────────────────────────────────────────────────

CREATE INDEX IF NOT EXISTS idx_content_flags_user_id
    ON public.content_flags(user_id);

CREATE INDEX IF NOT EXISTS idx_content_flags_risk_level
    ON public.content_flags(risk_level);

CREATE INDEX IF NOT EXISTS idx_content_flags_review_status
    ON public.content_flags(review_status);

CREATE INDEX IF NOT EXISTS idx_content_flags_timestamp
    ON public.content_flags(timestamp DESC);

CREATE INDEX IF NOT EXISTS idx_content_flags_is_emergency
    ON public.content_flags(is_emergency)
    WHERE is_emergency = true;

-- ── Row Level Security ────────────────────────────────────────

ALTER TABLE public.content_flags ENABLE ROW LEVEL SECURITY;

-- Only admins can read flags
CREATE POLICY "Admins can view content flags"
    ON public.content_flags FOR SELECT
    USING (public.is_admin());

-- Service role (Edge Function) inserts flags — bypasses RLS automatically
-- App users can also insert their own flag records (for flag-content function flow)
CREATE POLICY "Authenticated users can insert own content flags"
    ON public.content_flags FOR INSERT
    WITH CHECK (
        auth.uid() IS NOT NULL
        AND (user_id = auth.uid() OR user_id IS NULL)
    );

-- Admins can update review_status, reviewed_by, review_note
CREATE POLICY "Admins can update content flag review status"
    ON public.content_flags FOR UPDATE
    USING (public.is_admin())
    WITH CHECK (public.is_admin());

-- No DELETE — flags are immutable audit records (same as audit_logs)

-- ── moderation_keywords table (for RemoteModerationKeywordsService) ──────────

CREATE TABLE IF NOT EXISTS public.moderation_keywords (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    keyword    TEXT NOT NULL,
    category   TEXT NOT NULL CHECK (category IN (
                   'self_harm', 'drugs', 'alcohol', 'violence', 'emergency'
               )),
    risk       TEXT NOT NULL CHECK (risk IN (
                   'high_risk', 'medium_risk', 'low_risk', 'emergency'
               )),
    is_active  BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE public.moderation_keywords ENABLE ROW LEVEL SECURITY;

-- All authenticated users can read the keyword list (needed for remote config fetch)
CREATE POLICY "Authenticated users can read moderation keywords"
    ON public.moderation_keywords FOR SELECT
    TO authenticated
    USING (true);

-- Only admins can manage the keyword list
CREATE POLICY "Admins can manage moderation keywords"
    ON public.moderation_keywords FOR ALL
    USING (public.is_admin());

-- ── Audit action: add 'content_flagged' and 'content_escalated' ──────────────
-- (No schema change needed — audit_logs.action is TEXT; new values work automatically)
