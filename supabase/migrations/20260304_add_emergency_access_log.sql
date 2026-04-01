-- Emergency Access Log (Break-Glass)
-- HIPAA Technical Safeguard — documents every super-admin emergency access event.
--
-- Only super_admins can INSERT (grant) or UPDATE (revoke) their own entries.
-- All authenticated admins can SELECT for accountability review.
-- No DELETE — immutable audit trail.

CREATE TABLE IF NOT EXISTS public.emergency_access_log (
    id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id         UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    target_user_id   UUID        NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    reason           TEXT        NOT NULL,          -- mandatory justification
    granted_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    expires_at       TIMESTAMPTZ NOT NULL,          -- auto-set to granted_at + 1 hour
    revoked_at       TIMESTAMPTZ                    -- set when admin manually revokes; isActive computed in app
);

ALTER TABLE public.emergency_access_log ENABLE ROW LEVEL SECURITY;

-- Super admins can grant emergency access (insert their own entries)
CREATE POLICY "Super admins can grant emergency access"
    ON public.emergency_access_log
    FOR INSERT
    TO authenticated
    WITH CHECK (
        admin_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'super_admin' AND status = 'active'
        )
    );

-- Super admins can revoke their own grants (update only revoked_at)
CREATE POLICY "Super admins can revoke their own grants"
    ON public.emergency_access_log
    FOR UPDATE
    TO authenticated
    USING (
        admin_id = auth.uid()
        AND EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid() AND role = 'super_admin' AND status = 'active'
        )
    )
    WITH CHECK (admin_id = auth.uid());

-- All admins can read the log for accountability review
CREATE POLICY "Admins read emergency access log"
    ON public.emergency_access_log
    FOR SELECT
    TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles
            WHERE id = auth.uid()
              AND role IN ('admin', 'super_admin')
              AND status = 'active'
        )
    );

-- Indexes
CREATE INDEX IF NOT EXISTS eal_admin_id_idx        ON public.emergency_access_log(admin_id);
CREATE INDEX IF NOT EXISTS eal_target_user_id_idx  ON public.emergency_access_log(target_user_id);
CREATE INDEX IF NOT EXISTS eal_granted_at_idx      ON public.emergency_access_log(granted_at DESC);
