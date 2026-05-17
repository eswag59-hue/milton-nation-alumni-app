-- Phase 4.2 — Re-seed minimal demo content for App Store Reviewer
--
-- WHEN: Run this immediately before flipping DEMO_BYPASS_ENABLED → true
--       and submitting to Apple. Apple's reviewer will log in as alexdemo
--       and should see a populated experience (sample posts, a comment,
--       sample badge already earned, care team assigned).
--
-- After Apple approves, this seed content can stay or be wiped — your call.
-- It's all under alexdemo's user_id, so a single DELETE removes it cleanly.
--
-- NO PHI: All sample text is generic recovery-positive content. Names are
-- demo accounts already in the database (Dana Case = case manager,
-- Dr. Robin Nova = therapist).

BEGIN;

-- Set up a reference: alexdemo's user_id
DO $$
DECLARE
  alex_id UUID;
  dana_id UUID;
  drnova_id UUID;
  post_id_1 UUID := gen_random_uuid();
  post_id_2 UUID := gen_random_uuid();
  post_id_3 UUID := gen_random_uuid();
BEGIN
  SELECT id INTO alex_id FROM auth.users WHERE email = 'appreviewer@miltonrecovery.com';
  SELECT id INTO dana_id FROM auth.users WHERE email = 'case-manager-demo@miltonrecovery.com';
  SELECT id INTO drnova_id FROM auth.users WHERE email = 'therapist-demo@miltonrecovery.com';

  -- 3 sample posts from alexdemo (all approved, varied categories)
  INSERT INTO public.posts (id, user_id, user_name, user_photo_url, category, content, status, is_pinned, likes_count, comments_count, matched_keywords, created_at, approved_at) VALUES
    (post_id_1, alex_id, 'alexdemo', NULL, 'wins', 'Hit my 90-day mark today. Couldn''t have done it without the support of this community and my care team. One day at a time.', 'approved', false, 2, 1, ARRAY[]::text[], NOW() - INTERVAL '2 days', NOW() - INTERVAL '2 days'),
    (post_id_2, alex_id, 'alexdemo', NULL, 'gratitude', 'Grateful for honest mornings, good coffee, and meetings that meet me where I am.', 'approved', false, 1, 0, ARRAY[]::text[], NOW() - INTERVAL '5 days', NOW() - INTERVAL '5 days'),
    (post_id_3, alex_id, 'alexdemo', NULL, 'support', 'For anyone newly in recovery — the first 30 days are the hardest. Reach out. You''re not alone.', 'approved', false, 3, 0, ARRAY[]::text[], NOW() - INTERVAL '8 days', NOW() - INTERVAL '8 days');

  -- One comment on the first post (from Dana, the case manager) — shows
  -- care-team engagement to the reviewer.
  INSERT INTO public.comments (id, post_id, user_id, user_name, user_photo_url, content, matched_keywords, status, created_at) VALUES
    (gen_random_uuid(), post_id_1, dana_id, 'danacase', NULL, 'So proud of you, Alex. 90 days is a real milestone — keep going.', ARRAY[]::text[], 'approved', NOW() - INTERVAL '2 days' + INTERVAL '1 hour');

  -- Ensure alexdemo is assigned to a case manager + therapist (care team
  -- visible in "I''m Struggling Today" sheet).
  INSERT INTO public.staff_assignments (user_id, staff_id, created_at)
  VALUES
    (alex_id, dana_id, NOW() - INTERVAL '60 days'),
    (alex_id, drnova_id, NOW() - INTERVAL '60 days')
  ON CONFLICT DO NOTHING;

  -- One earned badge (90-day milestone) for alexdemo, if not already there.
  -- Find a badge tied to ~90 days and award it.
  INSERT INTO public.user_badges (id, user_id, badge_id, earned_at)
  SELECT gen_random_uuid(), alex_id, b.id, NOW() - INTERVAL '1 day'
  FROM public.badges b
  WHERE b.points_required BETWEEN 100 AND 500
  ORDER BY b.points_required
  LIMIT 1
  ON CONFLICT DO NOTHING;

END $$;

-- Audit: confirm what we just added
SELECT 'posts_alexdemo' AS chk, COUNT(*) FROM public.posts WHERE user_id = (SELECT id FROM auth.users WHERE email='appreviewer@miltonrecovery.com')
UNION ALL
SELECT 'comments_demo', COUNT(*) FROM public.comments WHERE user_id IN (SELECT id FROM auth.users WHERE email LIKE '%-demo@miltonrecovery.com')
UNION ALL
SELECT 'staff_assignments_alex', COUNT(*) FROM public.staff_assignments WHERE user_id = (SELECT id FROM auth.users WHERE email='appreviewer@miltonrecovery.com')
UNION ALL
SELECT 'user_badges_alex', COUNT(*) FROM public.user_badges WHERE user_id = (SELECT id FROM auth.users WHERE email='appreviewer@miltonrecovery.com');

COMMIT;
