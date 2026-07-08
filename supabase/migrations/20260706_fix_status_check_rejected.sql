-- Fix: profiles.status CHECK omitted 'rejected', but the admin reject-user
-- flow writes status='rejected' (SupabaseDataService.rejectUser). Without this,
-- every rejection fails with a constraint violation in production.
ALTER TABLE public.profiles DROP CONSTRAINT IF EXISTS profiles_status_check;
ALTER TABLE public.profiles ADD CONSTRAINT profiles_status_check
    CHECK (status = ANY (ARRAY['pending'::text, 'active'::text, 'rejected'::text, 'deactivated'::text, 'deleted'::text]));
