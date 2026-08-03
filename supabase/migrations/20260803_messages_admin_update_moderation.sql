-- ============================================================================
-- Admin chat-monitor moderation: allow admins/super_admins to UPDATE a
-- message's `status` (allow -> 'approved', deny -> 'denied') so the decision
-- PERSISTS instead of only living in the admin app's memory (which re-flagged
-- the message on the next load).
--
-- BEFORE this migration, `public.messages` had only SELECT + INSERT policies
-- (schema.sql §3f "Participants read/send messages", "Admins read all
-- messages"; tightened to facility scope in 20260713). There was NO UPDATE
-- policy at all, so every admin allow/deny write was silently rejected by RLS.
--
-- FACILITY ISOLATION: the write is scoped exactly like the SELECT monitor
-- policy "Admins read facility messages" (20260713) and the write-scoping in
-- "profiles_admin_update_facility" (20260713 follow-up):
--   * is_admin()          -> admin OR super_admin, status='active'
--   * super_admin         -> any facility
--   * admin               -> ONLY messages whose conversation's alumnus
--                            (conversations.user_id) is in the admin's own
--                            facility, via facility_of(c.user_id) =
--                            current_user_facility()
-- The SECURITY DEFINER helpers (is_admin / is_super_admin / current_user_facility
-- / facility_of) already exist and avoid RLS recursion on profiles.
--
-- WITH CHECK repeats the predicate so an admin can neither retarget a message
-- into another facility's conversation nor leave the row outside their scope —
-- defense-in-depth even though the app only ever changes `status`.
--
-- Clinical staff (case_manager / therapist / counselor) are intentionally NOT
-- granted write here: is_admin() covers admin/super_admin only, mirroring
-- profiles_admin_update_facility. If staff allow/deny is desired later, widen
-- this predicate deliberately in its own migration.
-- ============================================================================

BEGIN;

DROP POLICY IF EXISTS "Admins update facility messages" ON public.messages;

CREATE POLICY "Admins update facility messages" ON public.messages
FOR UPDATE
USING (
  is_admin()
  AND EXISTS (
    SELECT 1 FROM public.conversations c
    WHERE c.id = messages.conversation_id
      AND (is_super_admin() OR public.facility_of(c.user_id) = current_user_facility())
  )
)
WITH CHECK (
  is_admin()
  AND EXISTS (
    SELECT 1 FROM public.conversations c
    WHERE c.id = messages.conversation_id
      AND (is_super_admin() OR public.facility_of(c.user_id) = current_user_facility())
  )
);

COMMIT;

-- ============================================================================
-- VERIFICATION (run with REAL user JWTs via REST, NOT the service role, which
-- bypasses RLS). Given a flagged message in a Florida alumnus's conversation:
--   FL admin     UPDATE messages SET status='approved' WHERE id=<msg>  -> 1 row
--   OH admin     same UPDATE                                           -> 0 rows (blocked)
--   super-admin  same UPDATE for EITHER facility                       -> 1 row
--   alumni/staff same UPDATE                                           -> 0 rows (blocked)
-- Confirm no other facility's messages become updatable (cross-facility leak).
-- ============================================================================

-- ROLLBACK:
--   DROP POLICY IF EXISTS "Admins update facility messages" ON public.messages;
-- (messages had no UPDATE policy before this migration, so dropping it fully
--  restores the prior behavior — admin allow/deny writes are rejected again.)
