-- ============================================================================
-- 20260713 — Enforce facility isolation at the DATABASE layer (RLS)
-- ============================================================================
--
-- STATUS: PROPOSED — NOT YET APPLIED. Review before running.
--
-- WHY THIS EXISTS
-- ---------------
-- Facility isolation (Florida vs. Ohio) was enforced ONLY in the Swift client
-- (a filter in SupabaseDataService). At the RLS layer it was NOT enforced:
-- every facility-scoped table paired a correct facility policy with an older,
-- looser policy. Postgres OR-combines PERMISSIVE policies, so the loose one
-- wins and the facility policy becomes dead code.
--
-- PROVEN cross-facility leaks (verified live, 2026-07-13, with real JWTs +
-- the shipped anon key — no admin access required):
--   * posts         — an OH alumnus / an FL admin both read ALL 12 posts
--                     (8 FL + 4 OH). Policy "Read approved posts" +
--                     "Admins read all posts" override "posts_select_facility".
--   * announcements — "Read announcements" (auth.uid() IS NOT NULL) overrides
--                     "announcements_select_facility".
--   * profiles      — "Admins read all profiles" (is_admin(), no facility)
--                     leaks the OTHER facility's names/emails/phones to any
--                     admin. (PII/PHI.)
--   * comments / content_flags / conversations / messages — the admin
--                     "is_admin()" read policies have NO facility scope, so any
--                     admin reads the other facility's data, INCLUDING 1:1
--                     care-team chat messages (messages/conversations).
--
-- The anon key ships in the app binary, so RLS is the ONLY real server-side
-- boundary. Client-side filtering is trivially bypassed with curl.
--
-- DESIGN
-- ------
-- current_user_facility() already returns the right value:
--   super_admin -> NULL (sees all)   admin/staff -> admin_facility
--   alumnus     -> profiles.facility
-- We keep it. We DROP the loose policies and REPLACE them with facility-aware
-- ones. Tables without a facility column (comments, content_flags,
-- conversations, messages) derive facility by joining to the relevant user's
-- profile.
--
-- ROLLBACK: the DROP/CREATE pairs below are reversible — re-create the old
-- policies (definitions captured in the header of each section) to revert.
--
-- ⚠️ REVIEW GATES BEFORE APPLYING:
--   1. conversations/messages policies change who can read care-team chat.
--      Confirm the intended rule: "an admin may read a conversation only if the
--      alumnus (conversations.user_id) belongs to the admin's facility;
--      super_admin reads all." Participants (user_id/staff_id) always read.
--   2. Confirm staff (case_manager/therapist) profiles have facility set the way
--      current_user_facility() expects (admin_facility), or they may see an
--      empty feed.
--   3. Run the verification block at the bottom after applying.
-- ============================================================================

BEGIN;

-- ---------------------------------------------------------------------------
-- POSTS
--   old loose: "Read approved posts" = (status='approved' AND auth.uid() IS NOT NULL)
--   old loose: "Admins read all posts" = is_admin()
--   keep: "Authors read own posts" = (user_id = auth.uid())
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "Read approved posts"   ON public.posts;
DROP POLICY IF EXISTS "Admins read all posts" ON public.posts;
DROP POLICY IF EXISTS "posts_select_facility" ON public.posts;

-- Approved posts, facility-scoped (alumni + staff + super_admin).
CREATE POLICY "Read approved posts (facility-scoped)" ON public.posts
FOR SELECT USING (
  status = 'approved'
  AND auth.uid() IS NOT NULL
  AND (
    facility IS NULL
    OR facility = current_user_facility()
    OR (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'super_admin'
  )
);

-- Admins read ALL statuses (pending/flagged) but only within their facility;
-- super_admin reads all facilities.
CREATE POLICY "Admins read facility posts" ON public.posts
FOR SELECT USING (
  is_admin()
  AND (
    facility IS NULL
    OR facility = current_user_facility()
    OR (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'super_admin'
  )
);

-- ---------------------------------------------------------------------------
-- ANNOUNCEMENTS
--   old loose: "Read announcements" = (auth.uid() IS NOT NULL)
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "Read announcements"             ON public.announcements;
DROP POLICY IF EXISTS "announcements_select_facility"  ON public.announcements;

CREATE POLICY "Read announcements (facility-scoped)" ON public.announcements
FOR SELECT USING (
  auth.uid() IS NOT NULL
  AND (
    facility IS NULL
    OR facility = current_user_facility()
    OR (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'super_admin'
  )
);

-- ---------------------------------------------------------------------------
-- PROFILES  (names/emails/phones — PII/PHI)
--   old loose: "Admins read all profiles" = is_admin()
--   keep: "Users read own profile", "Users read assigned staff profiles"
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "Admins read all profiles" ON public.profiles;

CREATE POLICY "Admins read facility profiles" ON public.profiles
FOR SELECT USING (
  is_admin()
  AND (
    facility IS NULL
    OR facility = current_user_facility()
    OR (SELECT p.role FROM public.profiles p WHERE p.id = auth.uid()) = 'super_admin'
  )
);

-- ---------------------------------------------------------------------------
-- COMMENTS  (no facility column — derive via the parent post)
--   old loose: "Admins read all comments" = is_admin()
--   old: "Read comments on visible posts" checks post.status only, so it
--        re-opens cross-facility comments even after posts are fixed. Replace
--        it with one that requires the parent post to be facility-visible.
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
        OR (
          p.status = 'approved'
          AND (
            p.facility IS NULL
            OR p.facility = current_user_facility()
            OR (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'super_admin'
          )
        )
      )
  )
);

CREATE POLICY "Admins read facility comments" ON public.comments
FOR SELECT USING (
  is_admin()
  AND EXISTS (
    SELECT 1 FROM public.posts p
    WHERE p.id = comments.post_id
      AND (
        p.facility IS NULL
        OR p.facility = current_user_facility()
        OR (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'super_admin'
      )
  )
);

-- ---------------------------------------------------------------------------
-- CONTENT_FLAGS  (no facility column — derive via the flagged user's profile)
--   old loose: "Admins can view content flags" = is_admin()
--   NOTE: flags whose user_id IS NULL (anonymous/system) fall back to
--         super_admin-only to avoid leaking an un-attributable flag to the
--         wrong facility. Adjust if product wants both admins to see system flags.
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "Admins can view content flags" ON public.content_flags;

CREATE POLICY "Admins view facility content flags" ON public.content_flags
FOR SELECT USING (
  is_admin()
  AND (
    (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'super_admin'
    OR (
      content_flags.user_id IS NOT NULL
      AND (SELECT facility FROM public.profiles WHERE id = content_flags.user_id)
          = current_user_facility()
    )
  )
);

-- ---------------------------------------------------------------------------
-- CONVERSATIONS / MESSAGES  (care-team chat — PHI)
--   Participants (user_id/staff_id) keep full access. Admin monitoring is
--   scoped to the facility of the alumnus (conversations.user_id).
--   old loose: "Admins read all conversations" / "Admins read all messages"
-- ---------------------------------------------------------------------------
DROP POLICY IF EXISTS "Admins read all conversations" ON public.conversations;
CREATE POLICY "Admins read facility conversations" ON public.conversations
FOR SELECT USING (
  is_admin()
  AND (
    (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'super_admin'
    OR (SELECT facility FROM public.profiles WHERE id = conversations.user_id)
       = current_user_facility()
  )
);

DROP POLICY IF EXISTS "Admins read all messages" ON public.messages;
CREATE POLICY "Admins read facility messages" ON public.messages
FOR SELECT USING (
  is_admin()
  AND EXISTS (
    SELECT 1 FROM public.conversations c
    WHERE c.id = messages.conversation_id
      AND (
        (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'super_admin'
        OR (SELECT facility FROM public.profiles WHERE id = c.user_id)
           = current_user_facility()
      )
  )
);

COMMIT;

-- ============================================================================
-- VERIFICATION (run after COMMIT; expect facility isolation to hold)
--   As an OH alumnus JWT:   SELECT should return ONLY ohio + NULL-facility posts.
--   As an FL admin JWT:     SELECT posts should return ONLY florida + NULL.
--   As super_admin JWT:     SELECT posts should return BOTH facilities.
-- (Do this via REST with real JWTs, as in the 2026-07-13 repro, not as the
--  service role — the service role bypasses RLS.)
-- ============================================================================
