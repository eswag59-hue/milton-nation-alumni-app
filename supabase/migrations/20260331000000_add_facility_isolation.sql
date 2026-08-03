-- ============================================================
-- Facility Isolation
-- Adds Ohio/Florida facility separation to profiles and content tables.
-- Run in Supabase SQL Editor: Dashboard → SQL Editor → New Query
-- ============================================================

-- 1. Add facility columns to profiles
ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS facility TEXT
        CHECK (facility IN ('ohio', 'florida'));

ALTER TABLE public.profiles
    ADD COLUMN IF NOT EXISTS admin_facility TEXT
        CHECK (admin_facility IN ('ohio', 'florida'));

-- 2. Add facility columns to content tables
--    Existing rows get NULL (treated as visible to all until re-migrated)
ALTER TABLE public.posts
    ADD COLUMN IF NOT EXISTS facility TEXT
        CHECK (facility IN ('ohio', 'florida'));

ALTER TABLE public.announcements
    ADD COLUMN IF NOT EXISTS facility TEXT
        CHECK (facility IN ('ohio', 'florida'));

-- If you have a custom meetings table (not BMTL), add facility there too:
-- ALTER TABLE public.meetings ADD COLUMN IF NOT EXISTS facility TEXT CHECK (facility IN ('ohio', 'florida'));

-- 3. Helper function: returns the facility to use for RLS filtering
--    - super_admin → NULL (bypasses facility filter; app applies its own filter)
--    - admin / staff roles → admin_facility
--    - alumni / pending users → facility
CREATE OR REPLACE FUNCTION public.current_user_facility()
RETURNS TEXT
LANGUAGE SQL
STABLE
SECURITY DEFINER
AS $$
    SELECT
        CASE role
            WHEN 'super_admin'   THEN NULL
            WHEN 'admin'         THEN admin_facility
            WHEN 'case_manager'  THEN admin_facility
            WHEN 'therapist'     THEN admin_facility
            WHEN 'counselor'     THEN admin_facility
            ELSE facility  -- alumni and pending users
        END
    FROM public.profiles
    WHERE id = auth.uid()
$$;

-- 4. RLS policies for posts (facility isolation)
--    We ADD new policies; the existing ones remain but now have facility awareness.

-- Drop existing select policy if present and recreate with facility filter:
DROP POLICY IF EXISTS "Alumni can read approved posts" ON public.posts;
DROP POLICY IF EXISTS "posts_select_facility" ON public.posts;

CREATE POLICY "posts_select_facility" ON public.posts
    FOR SELECT USING (
        -- super_admin sees everything
        (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'super_admin'
        -- Everyone else: same facility as them, or no facility set yet (legacy rows)
        OR facility IS NULL
        OR facility = public.current_user_facility()
    );

-- Insert: facility must match the user's own facility (can't post to another facility)
DROP POLICY IF EXISTS "posts_insert_facility" ON public.posts;

CREATE POLICY "posts_insert_facility" ON public.posts
    FOR INSERT WITH CHECK (
        facility IS NULL
        OR facility = public.current_user_facility()
        OR (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'super_admin'
    );

-- 5. RLS policies for announcements
DROP POLICY IF EXISTS "announcements_select_facility" ON public.announcements;

CREATE POLICY "announcements_select_facility" ON public.announcements
    FOR SELECT USING (
        (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'super_admin'
        OR facility IS NULL
        OR facility = public.current_user_facility()
    );

-- 6. Performance indexes
CREATE INDEX IF NOT EXISTS profiles_facility_idx     ON public.profiles(facility);
CREATE INDEX IF NOT EXISTS profiles_admin_facility_idx ON public.profiles(admin_facility);
CREATE INDEX IF NOT EXISTS posts_facility_idx        ON public.posts(facility);
CREATE INDEX IF NOT EXISTS announcements_facility_idx ON public.announcements(facility);

-- 7. Admin facility scope: admins can only update profiles within their facility
--    (or no facility set yet = pending users)
DROP POLICY IF EXISTS "profiles_admin_update_facility" ON public.profiles;

CREATE POLICY "profiles_admin_update_facility" ON public.profiles
    FOR UPDATE USING (
        -- super_admin can update any profile
        (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'super_admin'
        -- admin can update profiles in their own facility, or pending (no facility) users
        OR (
            (SELECT role FROM public.profiles WHERE id = auth.uid()) = 'admin'
            AND (
                facility IS NULL
                OR facility = (SELECT admin_facility FROM public.profiles WHERE id = auth.uid())
            )
        )
        -- users can always update their own profile
        OR id = auth.uid()
    );
