-- Give clinical staff (case_manager / therapist / counselor) the facility-scoped
-- operational powers a facility admin has — announcements, meetings, post/comment
-- moderation, content flags, and caseload monitoring (sobriety changes + badges)
-- WITHOUT user-approval / user-management (those stay admin-only).
BEGIN;

CREATE OR REPLACE FUNCTION public.is_clinical_staff()
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid()
      AND role IN ('case_manager','therapist','counselor')
      AND status = 'active'
  );
$$;

-- Announcements: manage own-facility announcements.
DROP POLICY IF EXISTS "Staff manage facility announcements" ON public.announcements;
CREATE POLICY "Staff manage facility announcements" ON public.announcements
FOR ALL USING (
  is_clinical_staff() AND (facility IS NULL OR facility = current_user_facility())
) WITH CHECK (
  is_clinical_staff() AND (facility IS NULL OR facility = current_user_facility())
);

-- Meetings: Milton-wide (no facility column) — staff can add/edit/remove.
DROP POLICY IF EXISTS "Staff manage meetings" ON public.meetings;
CREATE POLICY "Staff manage meetings" ON public.meetings
FOR ALL USING (is_clinical_staff()) WITH CHECK (is_clinical_staff());

-- Posts: moderate (approve/reject) posts in their facility.
DROP POLICY IF EXISTS "Staff moderate facility posts" ON public.posts;
CREATE POLICY "Staff moderate facility posts" ON public.posts
FOR UPDATE USING (
  is_clinical_staff() AND (facility IS NULL OR facility = current_user_facility())
);

-- Comments: read + moderate comments on facility-visible posts.
DROP POLICY IF EXISTS "Staff read facility comments" ON public.comments;
CREATE POLICY "Staff read facility comments" ON public.comments
FOR SELECT USING (
  is_clinical_staff() AND EXISTS (
    SELECT 1 FROM public.posts p WHERE p.id = comments.post_id
      AND (p.facility IS NULL OR p.facility = current_user_facility())
  )
);
DROP POLICY IF EXISTS "Staff moderate facility comments" ON public.comments;
CREATE POLICY "Staff moderate facility comments" ON public.comments
FOR UPDATE USING (
  is_clinical_staff() AND EXISTS (
    SELECT 1 FROM public.posts p WHERE p.id = comments.post_id
      AND (p.facility IS NULL OR p.facility = current_user_facility())
  )
);

-- Content flags: view + review flags for their facility's members.
DROP POLICY IF EXISTS "Staff view facility content flags" ON public.content_flags;
CREATE POLICY "Staff view facility content flags" ON public.content_flags
FOR SELECT USING (
  is_clinical_staff() AND (
    content_flags.user_id IS NOT NULL
    AND public.facility_of(content_flags.user_id) = current_user_facility()
  )
);
DROP POLICY IF EXISTS "Staff review facility content flags" ON public.content_flags;
CREATE POLICY "Staff review facility content flags" ON public.content_flags
FOR UPDATE USING (
  is_clinical_staff() AND (
    content_flags.user_id IS NOT NULL
    AND public.facility_of(content_flags.user_id) = current_user_facility()
  )
);

-- Sobriety change log: monitor their facility's members' sobriety updates.
DROP POLICY IF EXISTS "Staff read facility sobriety changes" ON public.sobriety_change_log;
CREATE POLICY "Staff read facility sobriety changes" ON public.sobriety_change_log
FOR SELECT USING (
  is_clinical_staff() AND public.facility_of(user_id) = current_user_facility()
);

-- User badges: monitor their facility's members' milestones/badges.
DROP POLICY IF EXISTS "Staff read facility badges" ON public.user_badges;
CREATE POLICY "Staff read facility badges" ON public.user_badges
FOR SELECT USING (
  is_clinical_staff() AND public.facility_of(user_id) = current_user_facility()
);

-- Staff read their facility's member profiles (caseload + sobriety monitoring).
DROP POLICY IF EXISTS "Staff read facility profiles" ON public.profiles;
CREATE POLICY "Staff read facility profiles" ON public.profiles
FOR SELECT USING (
  is_clinical_staff() AND (facility IS NULL OR facility = current_user_facility())
);

COMMIT;
