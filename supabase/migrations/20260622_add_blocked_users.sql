-- ============================================================
-- Migration: Add blocked_users table (Apple Guideline 1.2 — UGC block)
-- Lets a user block another user; blocked authors' posts/comments/
-- messages are filtered out client-side. A user manages only their
-- own block list (RLS). Additive only — no existing tables touched.
-- Date: 2026-06-22
-- ============================================================

CREATE TABLE IF NOT EXISTS public.blocked_users (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    blocker_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    blocked_id  UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (blocker_id, blocked_id),
    CONSTRAINT blocked_users_no_self CHECK (blocker_id <> blocked_id)
);

ALTER TABLE public.blocked_users ENABLE ROW LEVEL SECURITY;

CREATE INDEX IF NOT EXISTS idx_blocked_users_blocker
    ON public.blocked_users(blocker_id);

-- RLS: a user can see and manage ONLY their own block list.
DROP POLICY IF EXISTS "blocked_users_select_own" ON public.blocked_users;
CREATE POLICY "blocked_users_select_own" ON public.blocked_users
    FOR SELECT USING (blocker_id = auth.uid());

DROP POLICY IF EXISTS "blocked_users_insert_own" ON public.blocked_users;
CREATE POLICY "blocked_users_insert_own" ON public.blocked_users
    FOR INSERT WITH CHECK (blocker_id = auth.uid());

DROP POLICY IF EXISTS "blocked_users_delete_own" ON public.blocked_users;
CREATE POLICY "blocked_users_delete_own" ON public.blocked_users
    FOR DELETE USING (blocker_id = auth.uid());
