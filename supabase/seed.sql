-- ============================================================
-- seed.sql — Initial data for Milton Nation Alumni App
-- Run in Supabase SQL Editor AFTER schema.sql
-- ============================================================

-- ============================================================
-- 1. BADGES (12 badges matching MockData.badges)
-- ============================================================
INSERT INTO public.badges (name, description, emoji, points_required, sort_order) VALUES
  ('Seedling',  'You''re growing! Earned at 100 points.',              '🌱', 100,  1),
  ('Sprout',    'Reaching new heights! Earned at 250 points.',         '🌿', 250,  2),
  ('Bloom',     'Starting to blossom! Earned at 500 points.',          '🌸', 500,  3),
  ('Tree',      'Standing tall! Earned at 750 points.',                '🌳', 750,  4),
  ('Oak',       'Mighty and unshakeable! Earned at 1,000 points.',     '🌲', 1000, 5),
  ('Mountain',  'Reaching the summit! Earned at 1,500 points.',        '⛰️', 1500, 6),
  ('Star',      'Shining bright! Earned at 2,000 points.',             '⭐', 2000, 7),
  ('Fire',      'Unstoppable! Earned at 2,500 points.',                '🔥', 2500, 8),
  ('Diamond',   'Rare and resilient! Earned at 3,000 points.',         '💎', 3000, 9),
  ('Crown',     'Royally committed! Earned at 3,500 points.',          '👑', 3500, 10),
  ('Phoenix',   'Rising from the ashes! Earned at 4,000 points.',      '🦅', 4000, 11),
  ('Legend',    'A true legend of recovery! Earned at 5,000 points.',   '🏆', 5000, 12);


-- ============================================================
-- 2. DAILY QUOTES (110 quotes matching MockData.quotes)
-- ============================================================
INSERT INTO public.daily_quotes (text, attribution) VALUES
  -- Classic recovery quotes
  ('Fall seven times, stand up eight.', 'Japanese Proverb'),
  ('The only way out is through.', 'Robert Frost'),
  ('Recovery is not a race. You don''t have to feel guilty if it takes you longer than you thought it would.', 'Unknown'),
  ('One day at a time.', 'AA Motto'),
  ('You are not your addiction. You are the person who overcame it.', 'Unknown'),
  ('Strength doesn''t come from what you can do. It comes from overcoming the things you once thought you couldn''t.', 'Rikki Rogers'),
  ('The greatest glory in living lies not in never falling, but in rising every time we fall.', 'Nelson Mandela'),
  -- Courage & strength
  ('Courage isn''t having the strength to go on — it is going on when you don''t have strength.', 'Napoleon Bonaparte'),
  ('It does not matter how slowly you go as long as you do not stop.', 'Confucius'),
  ('You may have to fight a battle more than once to win it.', 'Margaret Thatcher'),
  ('What lies behind us and what lies before us are tiny matters compared to what lies within us.', 'Ralph Waldo Emerson'),
  ('The secret of getting ahead is getting started.', 'Mark Twain'),
  ('Believe you can and you''re halfway there.', 'Theodore Roosevelt'),
  ('Out of suffering have emerged the strongest souls.', 'Kahlil Gibran'),
  ('Though no one can go back and make a brand new start, anyone can start from now and make a brand new ending.', 'Carl Bard'),
  ('Rock bottom became the solid foundation on which I rebuilt my life.', 'J.K. Rowling'),
  ('Every moment is a fresh beginning.', 'T.S. Eliot'),
  ('The wound is the place where the Light enters you.', 'Rumi'),
  ('Hardships often prepare ordinary people for an extraordinary destiny.', 'C.S. Lewis'),
  ('The only person you are destined to become is the person you decide to be.', 'Ralph Waldo Emerson'),
  ('Don''t let yesterday take up too much of today.', 'Will Rogers'),
  -- Recovery-specific
  ('Recovery is an acceptance that your life is in shambles and you have to change it.', 'Jamie Lee Curtis'),
  ('People often say that motivation doesn''t last. Neither does bathing — that''s why we recommend it daily.', 'Zig Ziglar'),
  ('Sobriety was the greatest gift I ever gave myself.', 'Rob Lowe'),
  ('The first step toward change is awareness. The second step is acceptance.', 'Nathaniel Branden'),
  ('We cannot solve our problems with the same thinking we used when we created them.', 'Albert Einstein'),
  ('Sometimes the smallest step in the right direction ends up being the biggest step of your life.', 'Naeem Callaway'),
  ('Recovery is about progression, not perfection.', 'Unknown'),
  ('You don''t have to see the whole staircase, just take the first step.', 'Martin Luther King Jr.'),
  ('Success is not final, failure is not fatal: it is the courage to continue that counts.', 'Winston Churchill'),
  ('The best time to plant a tree was 20 years ago. The second best time is now.', 'Chinese Proverb'),
  ('Addiction begins with the hope that something out there can instantly fill up the emptiness inside.', 'Jean Kilbourne'),
  ('When everything seems to be going against you, remember that the airplane takes off against the wind, not with it.', 'Henry Ford'),
  ('I understood myself only after I destroyed myself. And only in the process of fixing myself, did I know who I really was.', 'Sade Andria Zabala'),
  ('In the middle of difficulty lies opportunity.', 'Albert Einstein'),
  ('Recovery is something you have to work on every single day, and it''s something that doesn''t get a day off.', 'Demi Lovato'),
  ('There is no greater agony than bearing an untold story inside you.', 'Maya Angelou'),
  ('Be gentle with yourself. You''re doing the best you can.', 'Unknown'),
  ('The only impossible journey is the one you never begin.', 'Tony Robbins'),
  ('Your present circumstances don''t determine where you can go; they merely determine where you start.', 'Nido Qubein'),
  ('You were never created to live depressed, defeated, guilty, condemned, ashamed or unworthy.', 'Joel Osteen'),
  ('Let go of who you think you''re supposed to be; embrace who you are.', 'Brene Brown'),
  -- Hope & resilience
  ('This too shall pass.', 'Persian Proverb'),
  ('Healing is not linear.', 'Unknown'),
  ('Stars can''t shine without darkness.', 'Unknown'),
  ('You are allowed to be both a masterpiece and a work in progress simultaneously.', 'Sophia Bush'),
  ('What we achieve inwardly will change outer reality.', 'Plutarch'),
  ('I am not what happened to me. I am what I choose to become.', 'Carl Jung'),
  ('New beginnings are often disguised as painful endings.', 'Lao Tzu'),
  ('The human capacity for burden is like bamboo — far more flexible than you''d ever believe at first glance.', 'Jodi Picoult'),
  ('With the new day comes new strength and new thoughts.', 'Eleanor Roosevelt'),
  ('Life doesn''t get easier or more forgiving; we get stronger and more resilient.', 'Steve Maraboli'),
  ('It''s not whether you get knocked down, it''s whether you get up.', 'Vince Lombardi'),
  ('The comeback is always stronger than the setback.', 'Unknown'),
  ('Turn your wounds into wisdom.', 'Oprah Winfrey'),
  ('Almost everything will work again if you unplug it for a few minutes, including you.', 'Anne Lamott'),
  ('Act as if what you do makes a difference. It does.', 'William James'),
  ('I am thankful for my struggle because without it I wouldn''t have stumbled across my strength.', 'Alex Elle'),
  ('Nothing is impossible. The word itself says I''m possible.', 'Audrey Hepburn'),
  ('Change your thoughts and you change your world.', 'Norman Vincent Peale'),
  ('Our greatest glory is not in never failing, but in rising every time we fail.', 'Confucius'),
  ('The best way to predict your future is to create it.', 'Abraham Lincoln'),
  ('No matter how hard the past, you can always begin again.', 'Buddha'),
  -- Self-care & growth
  ('Caring for your body, mind, and spirit is your greatest and grandest responsibility.', 'Deepak Chopra'),
  ('Be patient with yourself. Self-growth is tender; it''s holy ground.', 'Stephen Covey'),
  ('You can''t go back and change the beginning, but you can start where you are and change the ending.', 'C.S. Lewis'),
  ('Happiness is not something ready-made. It comes from your own actions.', 'Dalai Lama'),
  ('Progress, not perfection.', 'Unknown'),
  ('Every day in every way, I''m getting better and better.', 'Emile Coue'),
  ('It is during our darkest moments that we must focus to see the light.', 'Aristotle'),
  ('Keep your face always toward the sunshine — and shadows will fall behind you.', 'Walt Whitman'),
  ('We are what we repeatedly do. Excellence then, is not an act, but a habit.', 'Aristotle'),
  ('Grant me the serenity to accept the things I cannot change, the courage to change the things I can, and the wisdom to know the difference.', 'Serenity Prayer'),
  ('Every morning we are born again. What we do today matters most.', 'Buddha'),
  ('You are braver than you believe, stronger than you seem, and smarter than you think.', 'A.A. Milne'),
  ('Your life does not get better by chance, it gets better by change.', 'Jim Rohn'),
  ('If you''re going through hell, keep going.', 'Winston Churchill'),
  ('Don''t count the days; make the days count.', 'Muhammad Ali'),
  -- Community & connection
  ('Alone we can do so little; together we can do so much.', 'Helen Keller'),
  ('Surround yourself with only people who are going to lift you higher.', 'Oprah Winfrey'),
  ('There is no exercise better for the heart than reaching down and lifting people up.', 'John Holmes'),
  ('Connection is the opposite of addiction.', 'Johann Hari'),
  ('We rise by lifting others.', 'Robert Ingersoll'),
  ('Asking for help is not a sign of weakness. It''s a sign of strength.', 'Barack Obama'),
  ('No one saves us but ourselves. No one can and no one may. We ourselves must walk the path.', 'Buddha'),
  ('In the midst of winter, I found there was, within me, an invincible summer.', 'Albert Camus'),
  ('Never be ashamed of a scar. It simply means you were stronger than whatever tried to hurt you.', 'Unknown'),
  ('When you can''t control what''s happening, challenge yourself to control the way you respond.', 'Unknown'),
  ('You have within you right now, everything you need to deal with whatever the world can throw at you.', 'Brian Tracy'),
  ('It always seems impossible until it''s done.', 'Nelson Mandela'),
  ('The struggle you''re in today is developing the strength you need for tomorrow.', 'Robert Tew'),
  ('Just because you''re struggling doesn''t mean you''re failing. Every great success requires some kind of struggle.', 'Unknown'),
  ('Hope is being able to see that there is light despite all of the darkness.', 'Desmond Tutu'),
  ('A journey of a thousand miles begins with a single step.', 'Lao Tzu'),
  ('The greatest weapon against stress is our ability to choose one thought over another.', 'William James'),
  ('Gratitude turns what we have into enough.', 'Aesop'),
  ('You don''t drown by falling in the water; you drown by staying there.', 'Edwin Louis Cole'),
  ('What is coming is better than what is gone.', 'Unknown'),
  ('There are far, far better things ahead than any we leave behind.', 'C.S. Lewis'),
  ('Getting sober was the single bravest thing I''ve ever done and will ever do in my life.', 'Jamie Lee Curtis'),
  ('When we are no longer able to change a situation, we are challenged to change ourselves.', 'Viktor Frankl'),
  ('Letting go doesn''t mean giving up, but rather accepting that there are things that cannot be.', 'Unknown'),
  ('Every day may not be good, but there is something good in every day.', 'Alice Morse Earle');


-- ============================================================
-- 3. INITIAL ANNOUNCEMENTS
-- ============================================================
INSERT INTO public.announcements (title, description) VALUES
  ('Welcome to Milton Alumni!', 'We''re excited to launch our new alumni app. Stay connected, share your journey, and support each other. Check back here for the latest updates from the Milton team.'),
  ('New Weekly Mindfulness Group', 'Join our new guided mindfulness group every Thursday at 10 AM. Virtual and in-person options available. Sign up through the Meetings tab.');


-- ============================================================
-- 4. STORAGE BUCKETS
-- (Run these via Supabase Dashboard > Storage, or via SQL)
-- ============================================================
-- Note: Storage bucket creation is typically done via the Dashboard.
-- If you need to do it via SQL, use the storage schema:
--
-- INSERT INTO storage.buckets (id, name, public) VALUES
--   ('post-media', 'post-media', false),
--   ('profile-photos', 'profile-photos', false),
--   ('chat-media', 'chat-media', false);
--
-- Then add storage policies:
--
-- CREATE POLICY "Users can upload to own folder" ON storage.objects
--   FOR INSERT TO authenticated
--   WITH CHECK (
--     bucket_id IN ('post-media', 'profile-photos', 'chat-media')
--     AND (storage.foldername(name))[1] = auth.uid()::text
--   );
--
-- CREATE POLICY "Users can read own files" ON storage.objects
--   FOR SELECT TO authenticated
--   USING (
--     bucket_id IN ('post-media', 'profile-photos', 'chat-media')
--     AND (storage.foldername(name))[1] = auth.uid()::text
--   );
--
-- CREATE POLICY "Admins can read all files" ON storage.objects
--   FOR SELECT TO authenticated
--   USING (
--     EXISTS (
--       SELECT 1 FROM public.profiles
--       WHERE id = auth.uid()
--       AND role IN ('admin', 'super_admin')
--     )
--   );
