-- ============================================================================
-- Milton Nation Alumni App — DEMO CONTENT CLEANUP
-- Project: hksxzuytcmqqwxmfjzdp (PRODUCTION)
--
-- Removes EVERYTHING created by the demo seed and restores the one existing
-- account that was modified (appreviewer / "Alex Demo"). Additive-only: it
-- touches ONLY the seeded fixed-UUID namespace (d3xxxxxx-...) and the
-- @miltondemo.seed users. Pre-existing rows (real data, the pre-existing
-- appreviewer staff assignments, and appreviewer's pre-existing Seedling
-- badge) are left untouched.
--
-- SAFE TO RUN REPEATEDLY (every statement is idempotent — a second run
-- simply finds nothing to delete).
--
-- HOW TO RUN:
--   cd "/Users/ezrabarishansky/Developer/Milton Nation Alumni App/Milton Nation Alumni App"
--   supabase db query --linked < launch-kit/CLEANUP-DEMO-CONTENT.sql
--
-- FK-safe order: children (likes/comments/messages/rsvps) -> conversations
--   -> posts -> flags/assignments/badges/milestones -> meetings/announcements
--   /quotes -> restore appreviewer -> demo auth users (cascades to profiles).
-- ============================================================================
BEGIN;

-- 1. Likes on seeded posts (also cascade when posts are deleted; explicit here)
DELETE FROM public.likes    WHERE post_id::text LIKE 'd3100000-%';

-- 2. Comments on seeded posts (includes the case-manager comment)
DELETE FROM public.comments WHERE post_id::text LIKE 'd3100000-%';
DELETE FROM public.comments WHERE id::text      LIKE 'd3200000-%';

-- 3. Messages in seeded conversations (also cascade on conversation delete)
DELETE FROM public.messages WHERE conversation_id::text LIKE 'd3500000-%';
DELETE FROM public.messages WHERE id::text              LIKE 'd3600000-%';

-- 4. Seeded conversations
DELETE FROM public.conversations WHERE id::text LIKE 'd3500000-%';

-- 5. Any RSVPs against seeded meetings (none seeded, but safe/repeatable)
DELETE FROM public.meeting_rsvps WHERE meeting_id::text LIKE 'd3800000-%';

-- 6. Seeded posts (12 approved + 1 crisis-flagged) — cascades leftover likes/comments
DELETE FROM public.posts WHERE id::text LIKE 'd3100000-%';

-- 7. Seeded content flags (crisis + user_report)
DELETE FROM public.content_flags WHERE id::text LIKE 'd3400000-%';

-- 8. Seeded demo staff assignments ONLY (appreviewer's pre-existing ones untouched)
DELETE FROM public.staff_assignments WHERE id::text LIKE 'd3700000-%';

-- 9. Seeded badges ONLY (appreviewer's pre-existing Seedling badge untouched)
DELETE FROM public.user_badges WHERE id::text LIKE 'd3b00000-%';

-- 10. Seeded milestones for appreviewer
DELETE FROM public.sobriety_milestones WHERE id::text LIKE 'd3c00000-%';

-- 11. Seeded meetings
DELETE FROM public.meetings WHERE id::text LIKE 'd3800000-%';

-- 12. Seeded announcements
DELETE FROM public.announcements WHERE id::text LIKE 'd3900000-%';

-- 13. Seeded daily quotes
DELETE FROM public.daily_quotes WHERE id::text LIKE 'd3a00000-%';

-- 14. Restore appreviewer ("Alex Demo") to its pre-seed sobriety_date.
--     (Seed set it to CURRENT_DATE-92; original value was 2023-06-15.
--      facility was already 'florida' pre-seed, so nothing to restore there.)
UPDATE public.profiles
   SET sobriety_date = DATE '2023-06-15'
 WHERE id = 'b62c98ff-2ad9-4484-a238-dee43b793292';

-- 15. Delete the 5 demo alumni + 2 pending applicants.
--     profiles.id -> auth.users(id) is ON DELETE CASCADE, so removing the auth
--     users removes their profiles automatically. All rows that referenced them
--     were deleted above (content_flags.user_id is ON DELETE SET NULL).
DELETE FROM auth.users WHERE email LIKE '%@miltondemo.seed';

COMMIT;

-- ----------------------------------------------------------------------------
-- Optional verification (run separately after the COMMIT above):
--   SELECT count(*) FROM public.profiles WHERE email LIKE '%@miltondemo.seed';        -- expect 0
--   SELECT count(*) FROM public.posts    WHERE id::text LIKE 'd3100000-%';            -- expect 0
--   SELECT count(*) FROM public.daily_quotes WHERE id::text LIKE 'd3a00000-%';        -- expect 0
--   SELECT sobriety_date FROM public.profiles
--     WHERE id='b62c98ff-2ad9-4484-a238-dee43b793292';                               -- expect 2023-06-15
-- ----------------------------------------------------------------------------
