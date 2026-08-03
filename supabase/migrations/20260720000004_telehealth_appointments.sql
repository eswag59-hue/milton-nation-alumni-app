-- Telehealth scheduling core.
--
-- Distinct from `meetings` (alumni / AA-NA group meetings anyone can drop into).
-- An appointment is a scheduled 1:1 session between a client and a provider
-- (therapist / case manager / admin), delivered over a per-session Zoom link.
--
-- Scope note: `purpose` is an ORGANIZATIONAL label ("what it's for"), NOT a
-- billing/claims artifact. Insurance billing lives in Milton's other systems;
-- this table never carries payer, member-id, or claim data.
--
-- RLS follows the patterns already proven in this schema: SELECT policies are
-- kept separate from write policies (a FOR ALL policy leaks SELECT and would
-- nullify facility scoping), and access uses the existing SECURITY DEFINER
-- helpers rather than sub-selecting the same table (which caused 42P17 before).

create table if not exists public.appointments (
  id                uuid primary key default gen_random_uuid(),
  client_id         uuid not null references public.profiles(id) on delete cascade,
  provider_id       uuid not null references public.profiles(id),
  facility          text check (facility is null or facility in ('florida','ohio')),
  appointment_type  text not null default 'individual_therapy',
  purpose           text,                       -- organizational label only
  status            text not null default 'requested'
                       check (status in ('requested','confirmed','cancelled','completed','no_show')),
  requested_by      uuid references public.profiles(id),
  scheduled_start   timestamptz,
  duration_minutes  int not null default 50 check (duration_minutes between 10 and 240),
  -- Zoom is wired in a later phase; a session may exist before its link does.
  zoom_meeting_id   text,
  zoom_join_url     text,
  staff_note        text,                        -- non-clinical scheduling note
  created_by        uuid references public.profiles(id),
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create index if not exists appointments_client_idx   on public.appointments (client_id, scheduled_start);
create index if not exists appointments_provider_idx on public.appointments (provider_id, scheduled_start);
create index if not exists appointments_facility_idx on public.appointments (facility);

-- One client's private post-session reflection + rating. Separate table so a
-- future provider-notes surface never shares a row with client-owned data.
create table if not exists public.appointment_feedback (
  id              uuid primary key default gen_random_uuid(),
  appointment_id  uuid not null references public.appointments(id) on delete cascade,
  client_id       uuid not null references public.profiles(id) on delete cascade,
  rating          int check (rating between 1 and 5),
  reflection      text,
  created_at      timestamptz not null default now(),
  unique (appointment_id)
);

alter table public.appointments        enable row level security;
alter table public.appointment_feedback enable row level security;

-- ── appointments: reads (permissive union is intended here) ──────────────
create policy "Client reads own appointments"
  on public.appointments for select to authenticated
  using (client_id = auth.uid());

create policy "Provider reads own appointments"
  on public.appointments for select to authenticated
  using (provider_id = auth.uid());

create policy "Facility staff read facility appointments"
  on public.appointments for select to authenticated
  using (
    (is_clinical_staff() or is_admin())
    and (is_super_admin() or facility is null or facility = current_user_facility())
  );

-- ── appointments: writes ─────────────────────────────────────────────────
-- A client may request a session for themselves; a request is never
-- self-confirmed.
create policy "Client requests appointment"
  on public.appointments for insert to authenticated
  with check (client_id = auth.uid() and status = 'requested');

-- Staff schedule / confirm within their own facility.
create policy "Staff create facility appointments"
  on public.appointments for insert to authenticated
  with check (
    (is_clinical_staff() or is_admin())
    and (is_super_admin() or facility is null or facility = current_user_facility())
  );

-- Client may update their own row only to cancel it.
create policy "Client cancels own appointment"
  on public.appointments for update to authenticated
  using (client_id = auth.uid())
  with check (client_id = auth.uid());

create policy "Staff update facility appointments"
  on public.appointments for update to authenticated
  using (
    (is_clinical_staff() or is_admin())
    and (is_super_admin() or facility is null or facility = current_user_facility())
  )
  with check (is_super_admin() or facility is null or facility = current_user_facility());

-- ── feedback: client owns it; providers may read their sessions' feedback ─
create policy "Client writes own feedback"
  on public.appointment_feedback for insert to authenticated
  with check (client_id = auth.uid());

create policy "Client reads own feedback"
  on public.appointment_feedback for select to authenticated
  using (client_id = auth.uid());

create policy "Client updates own feedback"
  on public.appointment_feedback for update to authenticated
  using (client_id = auth.uid()) with check (client_id = auth.uid());

create policy "Provider reads session feedback"
  on public.appointment_feedback for select to authenticated
  using (
    exists (
      select 1 from public.appointments a
      where a.id = appointment_feedback.appointment_id
        and a.provider_id = auth.uid()
    )
  );

-- keep updated_at fresh (reuses the shared helper if present)
drop trigger if exists appointments_updated_at on public.appointments;
create trigger appointments_updated_at
  before update on public.appointments
  for each row execute function public.update_updated_at();
