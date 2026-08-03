-- ============================================================================
-- Security hardening: pin search_path on the functions the Supabase security
-- advisor flags as `function_search_path_mutable` (lint 0011).
--
-- A SECURITY DEFINER (or any) function without a fixed search_path is
-- exploitable: a caller can prepend a schema (or a temp object) to search_path
-- and shadow the unqualified names the function references. Pinning it closes
-- that vector.
--
-- We use `SET search_path = public, pg_temp` (NOT `''`): these function bodies
-- reference app objects unqualified in places, so keeping `public` in scope
-- preserves behavior, while listing pg_temp LAST removes the implicit
-- "pg_temp first" relation-shadowing risk. Pure config change — no behavior
-- change, no data change.
--
-- Idempotent: ALTER FUNCTION ... SET is safe to re-run.
-- ============================================================================

BEGIN;

ALTER FUNCTION public.award_points(p_user_id uuid, p_points integer, p_action text) SET search_path = public, pg_temp;
ALTER FUNCTION public.cleanup_expired_otp()                                         SET search_path = public, pg_temp;
ALTER FUNCTION public.current_user_facility()                                       SET search_path = public, pg_temp;
ALTER FUNCTION public.increment_comment_count(p_post_id uuid)                       SET search_path = public, pg_temp;
ALTER FUNCTION public.is_admin()                                                    SET search_path = public, pg_temp;
ALTER FUNCTION public.log_sobriety_change()                                         SET search_path = public, pg_temp;
ALTER FUNCTION public.toggle_like(p_post_id uuid)                                   SET search_path = public, pg_temp;
ALTER FUNCTION public.update_updated_at()                                           SET search_path = public, pg_temp;

COMMIT;

-- VERIFICATION (should return 0 rows after apply):
--   SELECT p.proname FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
--   WHERE n.nspname='public' AND p.proname IN
--     ('award_points','cleanup_expired_otp','current_user_facility',
--      'increment_comment_count','is_admin','log_sobriety_change',
--      'toggle_like','update_updated_at')
--     AND NOT EXISTS (SELECT 1 FROM unnest(coalesce(p.proconfig,'{}')) c
--                     WHERE c LIKE 'search_path=%');
--
-- ROLLBACK: ALTER FUNCTION public.<name>(<args>) RESET search_path;
