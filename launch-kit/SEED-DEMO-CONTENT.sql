-- ============================================================================
-- Milton Nation Alumni App — DEMO SEED (production project hksxzuytcmqqwxmfjzdp)
-- Additive, clearly-marked, easily-deletable demo dataset.
-- Cleanup: launch-kit/CLEANUP-DEMO-CONTENT.sql
-- Markers: 5 demo alumni + 2 pending applicants use @miltondemo.seed emails,
--          *_demo usernames, and is_test_account:true in auth metadata.
--          All seeded content rows use the d3xxxxxx-... fixed-UUID namespace.
-- ============================================================================
BEGIN;

-- ---------------------------------------------------------------------------
-- 1. Auth users (trigger on_auth_user_created auto-creates matching profiles)
-- ---------------------------------------------------------------------------
INSERT INTO auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
  confirmation_token, recovery_token, email_change_token_new, email_change,
  email_change_token_current, phone_change, phone_change_token, reauthentication_token
) VALUES
-- 5 active demo alumni (3 Florida, 2 Ohio)
('d3000000-0000-4000-a000-000000000001','00000000-0000-0000-0000-000000000000','authenticated','authenticated',
 'recovery.warrior@miltondemo.seed', crypt('Milton2026!', gen_salt('bf')), now(),
 '{"provider":"email","providers":["email"]}',
 '{"full_name":"Marcus Tran","username":"marcus_t_demo","sobriety_date":"2025-06-08","discharge_date":"2025-07-08","recovery_program":"Residential — Florida","is_test_account":true}',
 now(), now(), '', '', '', '', '', '', '', ''),
('d3000000-0000-4000-a000-000000000002','00000000-0000-0000-0000-000000000000','authenticated','authenticated',
 'grateful.heart@miltondemo.seed', crypt('Milton2026!', gen_salt('bf')), now(),
 '{"provider":"email","providers":["email"]}',
 '{"full_name":"Priya Nair","username":"priya_n_demo","sobriety_date":"2025-12-15","discharge_date":"2026-01-14","recovery_program":"PHP — Florida","is_test_account":true}',
 now(), now(), '', '', '', '', '', '', '', ''),
('d3000000-0000-4000-a000-000000000003','00000000-0000-0000-0000-000000000000','authenticated','authenticated',
 'one.day.at.a.time@miltondemo.seed', crypt('Milton2026!', gen_salt('bf')), now(),
 '{"provider":"email","providers":["email"]}',
 '{"full_name":"Jamal Brooks","username":"jamal_b_demo","sobriety_date":"2026-05-29","discharge_date":"2026-06-20","recovery_program":"IOP — Florida","is_test_account":true}',
 now(), now(), '', '', '', '', '', '', '', ''),
('d3000000-0000-4000-a000-000000000004','00000000-0000-0000-0000-000000000000','authenticated','authenticated',
 'steel.city.strong@miltondemo.seed', crypt('Milton2026!', gen_salt('bf')), now(),
 '{"provider":"email","providers":["email"]}',
 '{"full_name":"Sarah Kovac","username":"sarah_k_demo","sobriety_date":"2024-07-13","discharge_date":"2024-08-13","recovery_program":"Residential — Ohio","is_test_account":true}',
 now(), now(), '', '', '', '', '', '', '', ''),
('d3000000-0000-4000-a000-000000000005','00000000-0000-0000-0000-000000000000','authenticated','authenticated',
 'new.chapter.oh@miltondemo.seed', crypt('Milton2026!', gen_salt('bf')), now(),
 '{"provider":"email","providers":["email"]}',
 '{"full_name":"Devon Ellis","username":"devon_e_demo","sobriety_date":"2026-04-16","discharge_date":"2026-05-15","recovery_program":"PHP — Ohio","is_test_account":true}',
 now(), now(), '', '', '', '', '', '', '', ''),
-- 2 pending applicants (one FL, one OH) — status stays 'pending'
('d3000000-0000-4000-a000-000000000006','00000000-0000-0000-0000-000000000000','authenticated','authenticated',
 'hopeful.beginner@miltondemo.seed', crypt('Milton2026!', gen_salt('bf')), now(),
 '{"provider":"email","providers":["email"]}',
 '{"full_name":"Chris Bell","username":"chris_pending_demo","sobriety_date":"2026-07-01","discharge_date":"2026-07-10","recovery_program":"IOP — Florida","is_test_account":true}',
 now(), now(), '', '', '', '', '', '', '', ''),
('d3000000-0000-4000-a000-000000000007','00000000-0000-0000-0000-000000000000','authenticated','authenticated',
 'fresh.start.oh@miltondemo.seed', crypt('Milton2026!', gen_salt('bf')), now(),
 '{"provider":"email","providers":["email"]}',
 '{"full_name":"Taylor Reed","username":"taylor_pending_demo","sobriety_date":"2026-06-20","discharge_date":"2026-07-05","recovery_program":"Residential — Ohio","is_test_account":true}',
 now(), now(), '', '', '', '', '', '', '', '')
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 2. Activate + facility-tag the demo profiles (trigger created them 'pending')
-- ---------------------------------------------------------------------------
UPDATE public.profiles SET status='active', facility='florida'
  WHERE id IN ('d3000000-0000-4000-a000-000000000001',
               'd3000000-0000-4000-a000-000000000002',
               'd3000000-0000-4000-a000-000000000003');
UPDATE public.profiles SET status='active', facility='ohio'
  WHERE id IN ('d3000000-0000-4000-a000-000000000004',
               'd3000000-0000-4000-a000-000000000005');
-- Pending applicants: keep status='pending', just tag facility for admin routing
UPDATE public.profiles SET facility='florida'
  WHERE id = 'd3000000-0000-4000-a000-000000000006';
UPDATE public.profiles SET facility='ohio'
  WHERE id = 'd3000000-0000-4000-a000-000000000007';

-- appreviewer (Alex Demo): ~92-day sobriety streak, facility florida (Home streak)
UPDATE public.profiles
  SET sobriety_date = CURRENT_DATE - 92, facility='florida'
  WHERE id = 'b62c98ff-2ad9-4484-a238-dee43b793292';

-- ---------------------------------------------------------------------------
-- 3. Posts — 12 approved (all 5 categories, FL/OH split, 2 pinned) + 1 crisis
-- ---------------------------------------------------------------------------
INSERT INTO public.posts
  (id, user_id, user_name, category, content, status, is_pinned, likes_count, comments_count, matched_keywords, created_at, approved_at, facility)
VALUES
('d3100000-0000-4000-a000-000000000001','d3000000-0000-4000-a000-000000000001','Marcus Tran','wins',
 'One year and counting. A year ago I could not picture a single sober morning — today I run 5k before work and mean it when I say I am grateful. To everyone still in their first week: it gets real, and it gets good.',
 'approved', true, 5, 2, '{}', now()-interval '25 days', now()-interval '25 days'+interval '30 minutes','florida'),
('d3100000-0000-4000-a000-000000000002','d3000000-0000-4000-a000-000000000002','Priya Nair','gratitude',
 'Grateful for the Thursday womens group. I walked in a stranger and walked out with people who text me on the hard days. Community is the medicine they never put on a prescription.',
 'approved', false, 2, 0, '{}', now()-interval '22 days', now()-interval '22 days'+interval '30 minutes','florida'),
('d3100000-0000-4000-a000-000000000003','d3000000-0000-4000-a000-000000000003','Jamal Brooks','struggles',
 'Not going to sugarcoat it — this was a heavy week. Cravings hit hard after a stressful shift and old thoughts came knocking. What is different this time is that I called my case manager instead of my old number. Still standing.',
 'approved', false, 5, 2, '{}', now()-interval '20 days', now()-interval '20 days'+interval '30 minutes','florida'),
('d3100000-0000-4000-a000-000000000004','d3000000-0000-4000-a000-000000000004','Sarah Kovac','wins',
 'I got the job!! Full time, benefits, a manager who knows my story and hired me anyway. Two years ago I was unemployable in my own eyes. Steubenville, we are BACK.',
 'approved', true, 3, 1, '{}', now()-interval '18 days', now()-interval '18 days'+interval '30 minutes','ohio'),
('d3100000-0000-4000-a000-000000000005','d3000000-0000-4000-a000-000000000005','Devon Ellis','support',
 'If anyone in the Ohio cohort needs a ride to the Tuesday meeting, I have a truck and an empty passenger seat. No one white-knuckles alone on my watch. DM me.',
 'approved', false, 1, 0, '{}', now()-interval '16 days', now()-interval '16 days'+interval '30 minutes','ohio'),
('d3100000-0000-4000-a000-000000000006','b62c98ff-2ad9-4484-a238-dee43b793292','Alex Demo','gratitude',
 'Three months today. Grateful for this app, for the people in it, and for a version of me that finally answers the phone. Small chip, big deal.',
 'approved', false, 4, 1, '{}', now()-interval '14 days', now()-interval '14 days'+interval '30 minutes','florida'),
('d3100000-0000-4000-a000-000000000007','d3000000-0000-4000-a000-000000000001','Marcus Tran','general',
 'PSA: morning sunlight + a 20 minute walk does more for my head than an hour of scrolling. Cheap, free, works. Thats the whole post.',
 'approved', false, 1, 0, '{}', now()-interval '12 days', now()-interval '12 days'+interval '30 minutes','florida'),
('d3100000-0000-4000-a000-000000000008','d3000000-0000-4000-a000-000000000002','Priya Nair','support',
 'Looking for a good early-morning virtual meeting — my schedule flipped and the evening ones no longer work. What do you all use? Drop links below and you might just save my routine.',
 'approved', false, 2, 1, '{}', now()-interval '10 days', now()-interval '10 days'+interval '30 minutes','florida'),
('d3100000-0000-4000-a000-000000000009','d3000000-0000-4000-a000-000000000004','Sarah Kovac','gratitude',
 'Had dinner with my daughter for the first time in three years last night. She said she was proud of me. I am still crying and I do not care who knows.',
 'approved', false, 1, 0, '{}', now()-interval '8 days', now()-interval '8 days'+interval '30 minutes','ohio'),
('d3100000-0000-4000-a000-000000000010','d3000000-0000-4000-a000-000000000005','Devon Ellis','wins',
 '88 days. Picked up the chip at the meeting tonight and my hands were steady for the first time in years. Onward.',
 'approved', false, 2, 0, '{}', now()-interval '6 days', now()-interval '6 days'+interval '30 minutes','ohio'),
('d3100000-0000-4000-a000-000000000011','d3000000-0000-4000-a000-000000000003','Jamal Brooks','general',
 'Reading recommendation that is getting me through: anything with short chapters. On the nights my brain will not settle, five pages is a win. What are you all reading?',
 'approved', false, 1, 0, '{}', now()-interval '4 days', now()-interval '4 days'+interval '30 minutes','florida'),
('d3100000-0000-4000-a000-000000000012','b62c98ff-2ad9-4484-a238-dee43b793292','Alex Demo','wins',
 'Back in the gym after two years away. Could barely finish a set but I finished it. The old me quit at hard. The new me is curious about it.',
 'approved', false, 2, 0, '{}', now()-interval '2 days', now()-interval '2 days'+interval '30 minutes','florida'),
-- Crisis-flagged post (clearly a DEMO flag) — populates the admin crisis queue
('d3100000-0000-4000-a000-000000000013','d3000000-0000-4000-a000-000000000003','Jamal Brooks','struggles',
 '[DEMO CRISIS FLAG] Feeling really hopeless tonight and I do not know if I can keep doing this. Everything feels like too much. (Seeded demo content for testing the crisis-flag surface — not a real report.)',
 'flagged_for_crisis', false, 0, 0, '{hopeless,cannot keep doing this}', now()-interval '1 days', NULL,'florida')
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 4. Comments (7 across 5 posts; one from the case manager, Dana Case)
-- ---------------------------------------------------------------------------
INSERT INTO public.comments (id, post_id, user_id, user_name, content, status, created_at) VALUES
('d3200000-0000-4000-a000-000000000001','d3100000-0000-4000-a000-000000000001','d3000000-0000-4000-a000-000000000002','Priya Nair','So proud of you Marcus. Watching you run past me at group changed what I thought was possible for me too.','approved', now()-interval '24 days'),
('d3200000-0000-4000-a000-000000000002','d3100000-0000-4000-a000-000000000001','b62c98ff-2ad9-4484-a238-dee43b793292','Alex Demo','This is huge. Framing this comment for my hard days.','approved', now()-interval '24 days'+interval '2 hours'),
('d3200000-0000-4000-a000-000000000003','d3100000-0000-4000-a000-000000000003','27890961-c041-4097-980d-6a9276d6db88','Dana Case','Jamal, calling instead of using is exactly the muscle we have been building — thank you for reaching out. I will check in with you tomorrow.','approved', now()-interval '19 days'),
('d3200000-0000-4000-a000-000000000004','d3100000-0000-4000-a000-000000000003','d3000000-0000-4000-a000-000000000005','Devon Ellis','We have got you, brother. One shift at a time.','approved', now()-interval '19 days'+interval '3 hours'),
('d3200000-0000-4000-a000-000000000005','d3100000-0000-4000-a000-000000000004','d3000000-0000-4000-a000-000000000005','Devon Ellis','Congrats on the job Sarah! Steubenville strong.','approved', now()-interval '17 days'),
('d3200000-0000-4000-a000-000000000006','d3100000-0000-4000-a000-000000000006','d3000000-0000-4000-a000-000000000004','Sarah Kovac','Gratitude changes everything. Congrats on 90, Alex.','approved', now()-interval '13 days'),
('d3200000-0000-4000-a000-000000000007','d3100000-0000-4000-a000-000000000008','d3000000-0000-4000-a000-000000000001','Marcus Tran','The 6:30am virtual meeting is my anchor — link is in the meetings tab. It sticks.','approved', now()-interval '9 days')
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 5. Likes (29 rows; likes_count columns above match these exactly)
-- ---------------------------------------------------------------------------
INSERT INTO public.likes (post_id, user_id) VALUES
-- post 01 (5)
('d3100000-0000-4000-a000-000000000001','d3000000-0000-4000-a000-000000000002'),
('d3100000-0000-4000-a000-000000000001','d3000000-0000-4000-a000-000000000003'),
('d3100000-0000-4000-a000-000000000001','d3000000-0000-4000-a000-000000000004'),
('d3100000-0000-4000-a000-000000000001','d3000000-0000-4000-a000-000000000005'),
('d3100000-0000-4000-a000-000000000001','b62c98ff-2ad9-4484-a238-dee43b793292'),
-- post 02 (2)
('d3100000-0000-4000-a000-000000000002','d3000000-0000-4000-a000-000000000001'),
('d3100000-0000-4000-a000-000000000002','b62c98ff-2ad9-4484-a238-dee43b793292'),
-- post 03 (5)
('d3100000-0000-4000-a000-000000000003','d3000000-0000-4000-a000-000000000001'),
('d3100000-0000-4000-a000-000000000003','d3000000-0000-4000-a000-000000000002'),
('d3100000-0000-4000-a000-000000000003','d3000000-0000-4000-a000-000000000005'),
('d3100000-0000-4000-a000-000000000003','b62c98ff-2ad9-4484-a238-dee43b793292'),
('d3100000-0000-4000-a000-000000000003','d3000000-0000-4000-a000-000000000004'),
-- post 04 (3)
('d3100000-0000-4000-a000-000000000004','d3000000-0000-4000-a000-000000000005'),
('d3100000-0000-4000-a000-000000000004','d3000000-0000-4000-a000-000000000001'),
('d3100000-0000-4000-a000-000000000004','b62c98ff-2ad9-4484-a238-dee43b793292'),
-- post 05 (1)
('d3100000-0000-4000-a000-000000000005','d3000000-0000-4000-a000-000000000004'),
-- post 06 (4)
('d3100000-0000-4000-a000-000000000006','d3000000-0000-4000-a000-000000000001'),
('d3100000-0000-4000-a000-000000000006','d3000000-0000-4000-a000-000000000002'),
('d3100000-0000-4000-a000-000000000006','d3000000-0000-4000-a000-000000000003'),
('d3100000-0000-4000-a000-000000000006','d3000000-0000-4000-a000-000000000004'),
-- post 07 (1)
('d3100000-0000-4000-a000-000000000007','d3000000-0000-4000-a000-000000000002'),
-- post 08 (2)
('d3100000-0000-4000-a000-000000000008','d3000000-0000-4000-a000-000000000003'),
('d3100000-0000-4000-a000-000000000008','d3000000-0000-4000-a000-000000000001'),
-- post 09 (1)
('d3100000-0000-4000-a000-000000000009','d3000000-0000-4000-a000-000000000005'),
-- post 10 (2)
('d3100000-0000-4000-a000-000000000010','d3000000-0000-4000-a000-000000000004'),
('d3100000-0000-4000-a000-000000000010','d3000000-0000-4000-a000-000000000001'),
-- post 11 (1)
('d3100000-0000-4000-a000-000000000011','b62c98ff-2ad9-4484-a238-dee43b793292'),
-- post 12 (2)
('d3100000-0000-4000-a000-000000000012','d3000000-0000-4000-a000-000000000001'),
('d3100000-0000-4000-a000-000000000012','d3000000-0000-4000-a000-000000000002')
ON CONFLICT (post_id, user_id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 6. Content flags (1 high-risk crisis + 1 user_report) -> admin Flags queue
-- ---------------------------------------------------------------------------
INSERT INTO public.content_flags
  (id, user_id, risk_level, categories, feature, redacted_summary, is_emergency, review_status, created_at)
VALUES
('d3400000-0000-4000-a000-000000000001','d3000000-0000-4000-a000-000000000003','high_risk',
 '{self_harm,crisis}','community_post',
 'DEMO: Member expressed hopelessness and possible self-harm ideation in a community post. Immediate outreach recommended.',
 true,'pending', now()-interval '1 days'),
('d3400000-0000-4000-a000-000000000002','d3000000-0000-4000-a000-000000000005','low_risk',
 '{user_report}','user_report',
 'DEMO: A member reported a community post for review (possible off-topic content). Low urgency.',
 false,'pending', now()-interval '3 days')
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 7. Care-team conversations (appreviewer <-> case manager / therapist)
-- ---------------------------------------------------------------------------
INSERT INTO public.conversations (id, user_id, staff_id, last_message, last_message_at, unread_count, created_at) VALUES
('d3500000-0000-4000-a000-000000000001','b62c98ff-2ad9-4484-a238-dee43b793292','27890961-c041-4097-980d-6a9276d6db88',
 'Honestly some dark thoughts crept in this week and it scared me.', now()-interval '1 days', 1, now()-interval '3 days'),
('d3500000-0000-4000-a000-000000000002','b62c98ff-2ad9-4484-a238-dee43b793292','73477276-fe9e-4177-aa5e-f3c4c4aeddca',
 'See you Thursday at 3.', now()-interval '2 days'+interval '20 minutes', 0, now()-interval '2 days')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.messages (id, conversation_id, sender_id, message_type, content, status, matched_keywords, created_at) VALUES
('d3600000-0000-4000-a000-000000000001','d3500000-0000-4000-a000-000000000001','b62c98ff-2ad9-4484-a238-dee43b793292','text',
 'Hey Dana, checking in — had a rough couple of days but I am staying with it.','clean','{}', now()-interval '3 days'),
('d3600000-0000-4000-a000-000000000002','d3500000-0000-4000-a000-000000000001','27890961-c041-4097-980d-6a9276d6db88','text',
 'Really glad you reached out, Alex. That takes strength. Want to talk through it this week?','clean','{}', now()-interval '3 days'+interval '10 minutes'),
('d3600000-0000-4000-a000-000000000003','d3500000-0000-4000-a000-000000000001','b62c98ff-2ad9-4484-a238-dee43b793292','text',
 'Honestly some dark thoughts crept in this week and it scared me.','flagged_for_crisis','{dark thoughts}', now()-interval '1 days'),
('d3600000-0000-4000-a000-000000000004','d3500000-0000-4000-a000-000000000002','b62c98ff-2ad9-4484-a238-dee43b793292','text',
 'Looking forward to our session this week.','clean','{}', now()-interval '2 days'),
('d3600000-0000-4000-a000-000000000005','d3500000-0000-4000-a000-000000000002','73477276-fe9e-4177-aa5e-f3c4c4aeddca','text',
 'See you Thursday at 3.','clean','{}', now()-interval '2 days'+interval '20 minutes')
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 8. Staff assignments (demo caseload; appreviewer's own already exist)
-- ---------------------------------------------------------------------------
INSERT INTO public.staff_assignments (id, user_id, staff_id, role_type) VALUES
('d3700000-0000-4000-a000-000000000001','d3000000-0000-4000-a000-000000000001','27890961-c041-4097-980d-6a9276d6db88','case_manager'),
('d3700000-0000-4000-a000-000000000002','d3000000-0000-4000-a000-000000000002','73477276-fe9e-4177-aa5e-f3c4c4aeddca','therapist'),
('d3700000-0000-4000-a000-000000000003','d3000000-0000-4000-a000-000000000003','27890961-c041-4097-980d-6a9276d6db88','case_manager')
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 9. Meetings (5; FL/OH, virtual/in_person/hybrid, recurring; future dates)
--    created_by = admin@miltonrecovery (Florida Admin)
-- ---------------------------------------------------------------------------
INSERT INTO public.meetings
  (id, title, description, meeting_type, date, start_time, end_time, location_address, virtual_link, is_recurring, recurrence_pattern, recurrence_end_date, created_by)
VALUES
('d3800000-0000-4000-a000-000000000001','Sunday Serenity Group — Florida',
 'Weekly in-person alumni support group. Coffee at 9:45, meeting at 10.','in_person',
 CURRENT_DATE+3, CURRENT_DATE+3+time '10:00', CURRENT_DATE+3+time '11:00',
 'Milton Recovery, Delray Beach, FL', NULL, true, 'weekly', CURRENT_DATE+90,
 '4166899d-623e-4193-8523-4fe80e10fb39'),
('d3800000-0000-4000-a000-000000000002','Virtual Evening Check-In',
 'Short guided check-in over video. Cameras optional, honesty required.','virtual',
 CURRENT_DATE+2, CURRENT_DATE+2+time '19:00', CURRENT_DATE+2+time '20:00',
 NULL, 'https://meet.miltonnation.org/evening', true, 'weekly', CURRENT_DATE+84,
 '4166899d-623e-4193-8523-4fe80e10fb39'),
('d3800000-0000-4000-a000-000000000003','Steel City Support — Ohio',
 'In-person Ohio cohort meeting. Newcomers welcome, rides available.','in_person',
 CURRENT_DATE+5, CURRENT_DATE+5+time '18:00', CURRENT_DATE+5+time '19:30',
 'Milton Jefferson, Steubenville, OH', NULL, false, NULL, NULL,
 '4166899d-623e-4193-8523-4fe80e10fb39'),
('d3800000-0000-4000-a000-000000000004','Alumni Speaker Night',
 'Monthly speaker meeting — an alum shares their story. Join in person or online.','hybrid',
 CURRENT_DATE+10, CURRENT_DATE+10+time '18:30', CURRENT_DATE+10+time '20:00',
 'Milton Recovery, Delray Beach, FL', 'https://meet.miltonnation.org/speaker', false, NULL, NULL,
 '4166899d-623e-4193-8523-4fe80e10fb39'),
('d3800000-0000-4000-a000-000000000005','Saturday Morning Meditation',
 'Start the weekend grounded. 45 minutes of guided meditation and breathwork.','virtual',
 CURRENT_DATE+6, CURRENT_DATE+6+time '08:00', CURRENT_DATE+6+time '08:45',
 NULL, 'https://meet.miltonnation.org/meditate', true, 'weekly', CURRENT_DATE+90,
 '4166899d-623e-4193-8523-4fe80e10fb39')
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 10. Announcements (FL, OH, and one global/null-facility)
-- ---------------------------------------------------------------------------
INSERT INTO public.announcements (id, title, description, facility, created_at) VALUES
('d3900000-0000-4000-a000-000000000001','Family Weekend at Delray',
 'Florida alumni: bring your loved ones for a day of workshops, lunch, and connection on the 20th. RSVP in the app.','florida', now()-interval '5 days'),
('d3900000-0000-4000-a000-000000000002','New IOP Track Opening in Steubenville',
 'Ohio alumni: a new evening IOP track starts next month. Spread the word to anyone who needs a step-up in support.','ohio', now()-interval '4 days'),
('d3900000-0000-4000-a000-000000000003','Alumni App Feedback Survey',
 'We are shaping what comes next. Tap the survey link on your Home tab and tell us what would make this app more useful. Two minutes, big impact.', NULL, now()-interval '2 days')
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 11. Daily quotes (6; one scheduled for CURRENT_DATE) — public-domain/original
-- ---------------------------------------------------------------------------
INSERT INTO public.daily_quotes (id, text, attribution, scheduled_date) VALUES
('d3a00000-0000-4000-a000-000000000001','The journey of a thousand miles begins with a single step.','Lao Tzu', CURRENT_DATE),
('d3a00000-0000-4000-a000-000000000002','We suffer more often in imagination than in reality.','Seneca', CURRENT_DATE+1),
('d3a00000-0000-4000-a000-000000000003','You have power over your mind — not outside events. Realize this, and you will find strength.','Marcus Aurelius', CURRENT_DATE+2),
('d3a00000-0000-4000-a000-000000000004','The wound is the place where the light enters you.','Rumi', CURRENT_DATE+3),
('d3a00000-0000-4000-a000-000000000005','Fall seven times, stand up eight.','Japanese proverb', CURRENT_DATE+4),
('d3a00000-0000-4000-a000-000000000006','Progress, not perfection — one honest day at a time.','Milton Nation', CURRENT_DATE+5)
ON CONFLICT (id) DO NOTHING;

-- ---------------------------------------------------------------------------
-- 12. Badges + milestones for appreviewer (Alex) — 90-day progression
-- ---------------------------------------------------------------------------
-- Sprout (250) + Bloom (500); appreviewer already holds Seedling (pre-existing, untouched)
INSERT INTO public.user_badges (id, user_id, badge_id) VALUES
('d3b00000-0000-4000-a000-000000000001','b62c98ff-2ad9-4484-a238-dee43b793292','f0cbd5c9-6ebc-4f6b-810b-e66dafdfb66a'),
('d3b00000-0000-4000-a000-000000000002','b62c98ff-2ad9-4484-a238-dee43b793292','85d32503-5327-405a-b67f-2849aba69a20')
ON CONFLICT (user_id, badge_id) DO NOTHING;

INSERT INTO public.sobriety_milestones (id, user_id, milestone_type, milestone_date, points_awarded) VALUES
('d3c00000-0000-4000-a000-000000000001','b62c98ff-2ad9-4484-a238-dee43b793292','30_days', CURRENT_DATE-62, 30),
('d3c00000-0000-4000-a000-000000000002','b62c98ff-2ad9-4484-a238-dee43b793292','60_days', CURRENT_DATE-32, 60),
('d3c00000-0000-4000-a000-000000000003','b62c98ff-2ad9-4484-a238-dee43b793292','90_days', CURRENT_DATE-2,  90)
ON CONFLICT (id) DO NOTHING;

COMMIT;
