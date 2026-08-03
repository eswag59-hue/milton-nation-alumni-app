-- ============================================================================
-- Least-privilege on SECURITY DEFINER functions (security advisor:
-- {anon,authenticated}_security_definer_function_executable).
--
-- Default state: every function had EXECUTE granted to PUBLIC + anon +
-- authenticated + service_role. That is broader than needed for functions that
-- are NOT part of a client flow. We tighten ONLY where provably safe and leave
-- the rest as-is (documented below) — over-revoking here would break the app.
--
-- REVOKE targets PUBLIC as well as the role, because access is granted via BOTH
-- PUBLIC and the explicit role grant; revoking only the role leaves PUBLIC.
--
-- KEPT AS-IS (intentional — do NOT revoke):
--   * is_admin / is_super_admin / current_user_facility / facility_of /
--     is_clinical_staff — called INSIDE RLS policies; the querying role
--     (authenticated, sometimes anon) needs EXECUTE or every RLS-protected
--     table becomes inaccessible. The advisor warning on these is by-design.
--   * handle_new_user / log_sobriety_change — trigger functions. They fire via
--     the trigger regardless of caller EXECUTE and cannot be usefully invoked
--     directly, so the exposure is ~nil; left untouched to avoid any risk on
--     the auth-signup / profile-update paths.
--   * purge_deactivated_accounts — already restricted to service_role.
-- ============================================================================

BEGIN;

-- Pure maintenance function — only cron / service_role should call it.
REVOKE EXECUTE ON FUNCTION public.cleanup_expired_otp()                        FROM PUBLIC, anon, authenticated;

-- App RPCs: called by the SIGNED-IN app (authenticated) only. Keep
-- authenticated + service_role; drop anon + PUBLIC so unauthenticated callers
-- can't invoke them. (Verified: each is called via .rpc() from the Swift app
-- and none are invoked from an Edge Function with the anon key.)
REVOKE EXECUTE ON FUNCTION public.award_points(uuid, integer, text)            FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.increment_comment_count(uuid)                FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.toggle_like(uuid)                            FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.toggle_comment_like(uuid)                    FROM PUBLIC, anon;
REVOKE EXECUTE ON FUNCTION public.bookable_providers()                         FROM PUBLIC, anon;

COMMIT;

-- ROLLBACK: GRANT EXECUTE ON FUNCTION public.<fn>(<args>) TO anon;  (and, for
-- cleanup_expired_otp, TO authenticated) — plus TO PUBLIC to fully restore.
