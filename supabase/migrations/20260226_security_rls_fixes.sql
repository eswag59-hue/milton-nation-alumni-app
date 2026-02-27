-- ============================================================
-- Security Migration 2026-02-26
-- Fix 1: audit_logs INSERT policy (prevent forged user_id)
-- Fix 2: chat-media SELECT policy (restrict to participants only)
-- ============================================================

-- 1. Fix audit_logs INSERT RLS policy
DROP POLICY IF EXISTS "Authenticated users insert audit logs" ON public.audit_logs;

CREATE POLICY "Authenticated users insert audit logs"
    ON public.audit_logs FOR INSERT
    WITH CHECK (
        auth.uid() IS NOT NULL
        AND (user_id = auth.uid() OR user_id IS NULL)
    );

-- 2. Fix chat-media storage SELECT policy
DROP POLICY IF EXISTS "Authenticated users can view chat media" ON storage.objects;
DROP POLICY IF EXISTS "Users can view accessible chat media" ON storage.objects;

CREATE POLICY "Users can view accessible chat media"
    ON storage.objects FOR SELECT TO authenticated
    USING (
        bucket_id = 'chat-media'
        AND (
            -- Uploader can always view their own files
            (storage.foldername(name))[1] = auth.uid()::text
            OR
            -- The other conversation participant (user_id or staff_id) can view
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
