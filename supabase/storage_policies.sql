-- ============================================================
-- Milton Nation Alumni App — Storage Bucket RLS Policies
-- ============================================================
-- Run this in the Supabase SQL Editor AFTER creating the
-- three storage buckets (post-media, profile-photos, chat-media).
--
-- All buckets are PRIVATE (not public). Access is controlled
-- via signed URLs generated server-side / from the app.
--
-- Each CREATE POLICY is wrapped in a DO block so this script
-- is fully idempotent (safe to re-run).
-- ============================================================

-- ────────────────────────────────────────────────────────────
-- 1. post-media bucket
-- ────────────────────────────────────────────────────────────

DO $$ BEGIN
  CREATE POLICY "Users can upload post media"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'post-media' AND (storage.foldername(name))[1] = auth.uid()::text);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "Authenticated users can view post media"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'post-media');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "Users can delete own post media"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'post-media' AND (storage.foldername(name))[1] = auth.uid()::text);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "Users can update own post media"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'post-media' AND (storage.foldername(name))[1] = auth.uid()::text);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ────────────────────────────────────────────────────────────
-- 2. profile-photos bucket
-- ────────────────────────────────────────────────────────────

DO $$ BEGIN
  CREATE POLICY "Users can upload profile photos"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'profile-photos' AND (storage.foldername(name))[1] = auth.uid()::text);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "Authenticated users can view profile photos"
  ON storage.objects FOR SELECT TO authenticated
  USING (bucket_id = 'profile-photos');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "Users can delete own profile photos"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'profile-photos' AND (storage.foldername(name))[1] = auth.uid()::text);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "Users can update own profile photos"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'profile-photos' AND (storage.foldername(name))[1] = auth.uid()::text);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ────────────────────────────────────────────────────────────
-- 3. chat-media bucket
-- ────────────────────────────────────────────────────────────

DO $$ BEGIN
  CREATE POLICY "Users can upload chat media"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'chat-media' AND (storage.foldername(name))[1] = auth.uid()::text);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  -- Drop the overly-broad policy if it exists from a previous deployment
  DROP POLICY IF EXISTS "Authenticated users can view chat media" ON storage.objects;
EXCEPTION WHEN undefined_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "Users can view accessible chat media"
  ON storage.objects FOR SELECT TO authenticated
  USING (
    bucket_id = 'chat-media'
    AND (
      -- Uploader can always view their own files
      (storage.foldername(name))[1] = auth.uid()::text
      OR
      -- The other conversation participant can view (user_id or staff_id in conversations)
      EXISTS (
        SELECT 1 FROM public.conversations c
        WHERE (
            c.user_id  = ((storage.foldername(name))[1])::uuid
            OR c.staff_id = ((storage.foldername(name))[1])::uuid
          )
          AND (c.user_id = auth.uid() OR c.staff_id = auth.uid())
      )
      OR
      -- Admins can view all chat media for moderation
      public.is_admin()
    )
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "Users can delete own chat media"
  ON storage.objects FOR DELETE TO authenticated
  USING (bucket_id = 'chat-media' AND (storage.foldername(name))[1] = auth.uid()::text);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "Users can update own chat media"
  ON storage.objects FOR UPDATE TO authenticated
  USING (bucket_id = 'chat-media' AND (storage.foldername(name))[1] = auth.uid()::text);
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

-- ────────────────────────────────────────────────────────────
-- 4. device_tokens table (for push notifications)
-- ────────────────────────────────────────────────────────────

CREATE TABLE IF NOT EXISTS public.device_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    platform TEXT NOT NULL DEFAULT 'ios',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE(user_id, token)
);

ALTER TABLE public.device_tokens ENABLE ROW LEVEL SECURITY;

DO $$ BEGIN
  CREATE POLICY "Users can manage own device tokens"
  ON public.device_tokens FOR ALL TO authenticated
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE POLICY "Admins can read all device tokens"
  ON public.device_tokens FOR SELECT TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = auth.uid()
      AND profiles.role IN ('admin', 'super_admin')
    )
  );
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE INDEX IF NOT EXISTS idx_device_tokens_user_id ON public.device_tokens(user_id);
