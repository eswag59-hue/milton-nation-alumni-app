-- Migration: sobriety_change_log + trigger
-- Captures every change to profiles.sobriety_date for admin dashboards

CREATE TABLE IF NOT EXISTS public.sobriety_change_log (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
    previous_date DATE,
    new_date DATE NOT NULL,
    changed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    changed_by UUID REFERENCES public.profiles(id),
    is_reset BOOLEAN GENERATED ALWAYS AS (new_date > previous_date) STORED
);

CREATE INDEX IF NOT EXISTS idx_sobriety_log_user ON public.sobriety_change_log(user_id);
CREATE INDEX IF NOT EXISTS idx_sobriety_log_changed_at ON public.sobriety_change_log(changed_at DESC);

ALTER TABLE public.sobriety_change_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS sobriety_log_admin_read ON public.sobriety_change_log;
CREATE POLICY sobriety_log_admin_read ON public.sobriety_change_log
    FOR SELECT TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM public.profiles p
            WHERE p.id = auth.uid()
            AND p.role IN ('admin','super_admin')
        )
    );

DROP POLICY IF EXISTS sobriety_log_self_read ON public.sobriety_change_log;
CREATE POLICY sobriety_log_self_read ON public.sobriety_change_log
    FOR SELECT TO authenticated
    USING (user_id = auth.uid());

-- Trigger: log every change to sobriety_date
CREATE OR REPLACE FUNCTION public.log_sobriety_change()
RETURNS TRIGGER AS $$
BEGIN
    IF (OLD.sobriety_date IS DISTINCT FROM NEW.sobriety_date) THEN
        INSERT INTO public.sobriety_change_log (user_id, previous_date, new_date, changed_by)
        VALUES (NEW.id, OLD.sobriety_date, NEW.sobriety_date, auth.uid());
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS sobriety_change_log_trg ON public.profiles;
CREATE TRIGGER sobriety_change_log_trg
    AFTER UPDATE OF sobriety_date ON public.profiles
    FOR EACH ROW EXECUTE FUNCTION public.log_sobriety_change();
