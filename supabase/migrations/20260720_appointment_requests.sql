-- Session-request workflow.
--
-- A client requests a session with a PREFERRED provider (any provider, not
-- just their own care team) at a primary or backup time. A scheduler (admin/
-- super-admin) or the requested clinician then approves it — keeping or
-- overriding the provider and picking the final time — which confirms it and
-- puts it on both schedules.
--
--   requested_provider_id : who the client asked for (immutable record)
--   provider_id           : who's actually assigned (starts = requested, the
--                           approver may override)
--   preferred_start       : the client's primary desired time
--   preferred_start_2     : the client's backup time
--   scheduled_start       : the FINAL confirmed time (set on approval / direct
--                           schedule; null while still 'requested')
--   approved_by           : the scheduler/clinician who confirmed it

alter table public.appointments
  add column if not exists requested_provider_id uuid references public.profiles(id),
  add column if not exists preferred_start   timestamptz,
  add column if not exists preferred_start_2 timestamptz,
  add column if not exists approved_by       uuid references public.profiles(id);

-- Providers a client may request. SECURITY DEFINER so a client (who can't read
-- staff profiles under RLS) still gets the list — scoped to their own facility.
-- Includes clinical providers AND admins (schedulers), per product decision.
create or replace function public.bookable_providers()
returns table(id uuid, full_name text, role text)
language sql
security definer
set search_path = public
as $$
  select p.id, p.full_name, p.role::text
  from public.profiles p
  where p.status = 'active'
    and p.role in ('therapist','case_manager','counselor','admin')
    and (
      public.is_super_admin()
      or p.admin_facility = public.current_user_facility()
    )
  order by p.full_name;
$$;

grant execute on function public.bookable_providers() to authenticated;
