-- Crash reports table for iOS exception and non-fatal error tracking.
-- Separate from audit_logs (security/compliance) — this is technical observability.
--
-- report_type values:
--   'fatal'     — unhandled ObjC/Swift exception; uploaded on the NEXT launch
--   'non_fatal' — caught error recorded immediately via recordError(_:context:)

CREATE TABLE IF NOT EXISTS public.crash_reports (
    id               UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    report_type      TEXT        NOT NULL CHECK (report_type IN ('fatal', 'non_fatal')),
    exception_name   TEXT,
    exception_reason TEXT,
    call_stack       JSONB,          -- JSON array of stack-frame strings
    app_version      TEXT        NOT NULL,
    build_number     TEXT        NOT NULL,
    os_version       TEXT        NOT NULL,
    device_model     TEXT        NOT NULL,
    user_id          UUID        REFERENCES public.profiles(id) ON DELETE SET NULL,
    session_id       UUID,
    crashed_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

ALTER TABLE public.crash_reports ENABLE ROW LEVEL SECURITY;

-- Allow any client (anon or authenticated) to INSERT crash reports.
-- A crash can happen before login, so anon inserts must be permitted.
-- The data contains only technical diagnostics — no other users' PHI.
CREATE POLICY "Anyone can insert crash reports"
    ON public.crash_reports
    FOR INSERT
    WITH CHECK (true);

-- Only admins can READ crash reports (requires is_admin() helper from schema.sql).
CREATE POLICY "Admins read all crash reports"
    ON public.crash_reports
    FOR SELECT
    TO authenticated
    USING (is_admin());

-- Indexes for the most common dashboard queries.
CREATE INDEX IF NOT EXISTS crash_reports_report_type_idx  ON public.crash_reports(report_type);
CREATE INDEX IF NOT EXISTS crash_reports_user_id_idx      ON public.crash_reports(user_id);
CREATE INDEX IF NOT EXISTS crash_reports_app_version_idx  ON public.crash_reports(app_version);
CREATE INDEX IF NOT EXISTS crash_reports_crashed_at_idx   ON public.crash_reports(crashed_at DESC);
