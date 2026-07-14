-- ============================================================================
-- 20260713 — Enforce facility isolation at the DATABASE layer (RLS)
-- ============================================================================
--
-- STATUS: ✅ APPLIED to production 2026-07-13 and VERIFIED with real JWTs for
--         all 5 roles (OH/FL alumni, OH/FL admins, super_admin): posts,
--         profiles, comments, content_flags, conversations, and messages all
--         partition cleanly by facility; participants keep chat access;
--         super_admin sees both facilities. (An earlier naive version hit
--         42P17 infinite recursion — a profiles policy must never sub-SELECT
--         profiles; this version uses SECURITY DEFINER helpers instead.)
--
-- WHY THIS EXISTS
-- ---------------
-- Facility isolation (Florida vs. Ohio) was enforced ONLY in the Swift client.
-- At the RLS layer it was NOT enforced: every facility-scoped table paired a
-- correct facility policy with an older, looser policy. Postgres OR-combines
-- PERMISSIVE policies, so the loose one wins and the facility policy is dead.
--
-- PROVEN cross-facility leaks (verified live 2026-07-13 with real user JWTs +
-- the shipped anon key — NO admin creds needed):
--   * posts         — OH alumnus AND FL admin each read all 12 posts (8FL+4OH)
--   * announcements — every user reads all facilities' announcements
--   * profiles      — any admin reads the OTHER facility's names/emails/phones
--   * comments / content_flags / conversations / messages — admin is_admin()
--                     reads are unscoped; a FL admin can read OH care-team CHAT.
-- The anon key ships in the app binary, so RLS is the only real boundary;
-- client-side filtering is bypassed with one curl.
--
-- ⚠️ THE RECURSION TRAP (why the naive fix failed)
-- -------------------------------------------------
-- A SELECT policy ON profiles must NOT contain a sub-SELECT against profiles
-- (e.g. "(SELECT role FROM profiles WHERE id = auth.uid())"). Evaluating the
-- policy re-reads profiles, which re-evaluates the policy -> infinite loop.
-- FIX: detect super_admin via a SECURITY DEFINER function (bypasses RLS), and
-- use current_user_facility() (also SECURITY DEFINER). Never inline-subquery
-- the same table a policy is attached to.
-- On non-profiles tables (posts, announcements), an inline
-- "(SELECT role FROM profiles WHERE id = auth.uid())" is safe because it reads
-- the caller's OWN profile row (allowed by "Users read own profile") — but we
-- use is_super_admin() everywhere below for consistency and safety.
--
-- ROLLBACK: recreate the prior policies (captured in /tmp/rls_rollback.sql on
-- 2026-07-13, and reproduced at the bottom of this file for the record).
-- ============================================================================

BEGIN;

-- --- SECURITY DEFINER helper: super_admin check with NO RLS recursion --------
CREATE OR REPLACE FUNCTION public.is_super_admin()
RETURNS boolean
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'super_admin' AND status = 'active'
  );
$$;

-- ---------------------------------------------------------------------------
-- POSTS
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "Read approved posts"   ON public.posts;
DROP POLICY IF EXISTS "Admins read all posts" ON public.posts;
DROP POLICY IF EXISTS "posts_select_facility" ON public.posts;
-- keep "Authors read own posts" (user_id = auth.uid())

CREATE POLICY "Read approved posts (facility-scoped)" ON public.posts
FOR SELECT USING (
  status = 'approved' AND auth.uid() IS NOT NULL
  AND (facility IS NULL OR facility = current_user_facility() OR is_super_admin())
);

CREATE POLICY "Admins read facility posts" ON public.posts
FOR SELECT USING (
  is_admin()
  AND (facility IS NULL OR facility = current_user_facility() OR is_super_admin())
);

-- ---------------------------------------------------------------------------
-- ANNOUNCEMENTS
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "Read announcements"            ON public.announcements;
DROP POLICY IF EXISTS "announcements_select_facility" ON public.announcements;

CREATE POLICY "Read announcements (facility-scoped)" ON public.announcements
FOR SELECT USING (
  auth.uid() IS NOT NULL
  AND (facility IS NULL OR facility = current_user_facility() OR is_super_admin())
);

-- ---------------------------------------------------------------------------
-- PROFILES  (names/emails/phones — PII/PHI). NO inline profiles sub-SELECT.
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "Admins read all profiles" ON public.profiles;
-- keep "Users read own profile" and "Users read assigned staff profiles"

CREATE POLICY "Admins read facility profiles" ON public.profiles
FOR SELECT USING (
  is_admin()
  AND (facility IS NULL OR facility = current_user_facility() OR is_super_admin())
);

-- ---------------------------------------------------------------------------
-- COMMENTS  (no facility column — derive via the parent POST, not the author,
--            so we don't fight profiles-RLS). A user sees a comment only if the
--            parent post is visible to them under the posts policies above.
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "Admins read all comments"       ON public.comments;
DROP POLICY IF EXISTS "Read comments on visible posts" ON public.comments;

CREATE POLICY "Read comments on facility-visible posts" ON public.comments
FOR SELECT USING (
  auth.uid() IS NOT NULL
  AND EXISTS (
    SELECT 1 FROM public.posts p
    WHERE p.id = comments.post_id
      AND (
        p.user_id = auth.uid()
        OR (p.status = 'approved'
            AND (p.facility IS NULL OR p.facility = current_user_facility() OR is_super_admin()))
      )
  )
);

CREATE POLICY "Admins read facility comments" ON public.comments
FOR SELECT USING (
  is_admin()
  AND EXISTS (
    SELECT 1 FROM public.posts p
    WHERE p.id = comments.post_id
      AND (p.facility IS NULL OR p.facility = current_user_facility() OR is_super_admin())
  )
);

-- ---------------------------------------------------------------------------
-- CONTENT_FLAGS  (no facility column — derive via the flagged user's profile).
--   Uses a SECURITY DEFINER helper so admins can read the facility of an
--   arbitrary user without needing direct RLS read access to that profile row.
-- ---------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.facility_of(uid uuid)
RETURNS text
LANGUAGE sql
STABLE SECURITY DEFINER
SET search_path = public
AS $$ SELECT facility FROM public.profiles WHERE id = uid $$;

DROP POLICY IF EXISTS "Admins can view content flags" ON public.content_flags;

CREATE POLICY "Admins view facility content flags" ON public.content_flags
FOR SELECT USING (
  is_admin()
  AND (
    is_super_admin()
    OR (content_flags.user_id IS NOT NULL
        AND public.facility_of(content_flags.user_id) = current_user_facility())
  )
);

-- ---------------------------------------------------------------------------
-- CONVERSATIONS / MESSAGES  (care-team chat — PHI). Participants keep access;
--   admin monitoring scoped to the facility of the alumnus (conversations.user_id).
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "Admins read all conversations" ON public.conversations;
CREATE POLICY "Admins read facility conversations" ON public.conversations
FOR SELECT USING (
  is_admin()
  AND (is_super_admin() OR public.facility_of(conversations.user_id) = current_user_facility())
);

DROP POLICY IF EXISTS "Admins read all messages" ON public.messages;
CREATE POLICY "Admins read facility messages" ON public.messages
FOR SELECT USING (
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
-- bypasses RLS). Expected after apply:
--   OH alumnus  -> posts: ohio + NULL only
--   FL alumnus  -> posts: florida + NULL only
--   FL admin    -> posts/profiles: florida + NULL only
--   OH admin    -> posts/profiles: ohio + NULL only
--   super-admin -> BOTH facilities
--   care-team chat: an admin sees ONLY their facility's conversations/messages
-- ============================================================================

-- ---------------------------------------------------------------------------
-- ROLLBACK (recreate the pre-2026-07-13 policies):
--   posts:  "Read approved posts" USING (status='approved' AND auth.uid() IS NOT NULL);
--           "Admins read all posts" USING (is_admin());
--           "posts_select_facility" USING ((SELECT role FROM profiles WHERE id=auth.uid())='super_admin'
--                                           OR facility IS NULL OR facility=current_user_facility());
--   announcements: "Read announcements" USING (auth.uid() IS NOT NULL);
--                  "announcements_select_facility" USING (<same super_admin/facility expr>);
--   profiles: "Admins read all profiles" USING (is_admin());
--   comments: "Admins read all comments" USING (is_admin());
--             "Read comments on visible posts" USING (auth.uid() IS NOT NULL AND EXISTS(
--                SELECT 1 FROM posts WHERE posts.id=comments.post_id
--                AND (posts.status='approved' OR posts.user_id=auth.uid())));
--   content_flags: "Admins can view content flags" USING (is_admin());
--   conversations: "Admins read all conversations" USING (is_admin());
--   messages: "Admins read all messages" USING (is_admin());
-- ============================================================================

-- ── 2026-07-14 follow-up: profiles UPDATE policies ──────────────────────────
-- The admin "Approve" action failed with 42P17 (recursion) because
-- profiles_admin_update_facility inline-sub-selected profiles, and
-- "Admins update any profile" (is_admin(), no facility scope) was a
-- cross-facility WRITE leak. Replaced with a helper-based, facility-scoped policy.
DROP POLICY IF EXISTS "profiles_admin_update_facility" ON public.profiles;
DROP POLICY IF EXISTS "Admins update any profile"      ON public.profiles;
CREATE POLICY "profiles_admin_update_facility" ON public.profiles
FOR UPDATE USING (
  is_super_admin()
  OR (is_admin() AND (facility IS NULL OR facility = current_user_facility()))
  OR id = auth.uid()
);
