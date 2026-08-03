-- Care-team alerts queue.
--
-- When a member taps "Notify my care team," a push already fans out to the
-- facility's care team — but the push is deliberately PHI-free (no name), so on
-- its own it can't tell a responder WHO needs help. This table is the in-app,
-- post-auth record that carries that (HIPAA-covered) detail: tapping the push
-- opens the app, the app reads this queue, and the responder taps through to
-- the member's chat. The member identity never travels through Apple.
--
-- Written by the send-push-notification Edge Function (service role). Read by
-- the facility's care team; a purged member cascades its alerts away.

create table if not exists public.care_team_alerts (
  id               uuid primary key default gen_random_uuid(),
  member_id        uuid not null references public.profiles(id) on delete cascade,
  facility         text check (facility is null or facility in ('florida','ohio')),
  kind             text not null default 'struggling',   -- struggling | crisis_content (future)
  status           text not null default 'open'
                      check (status in ('open','acknowledged','resolved')),
  acknowledged_by  uuid references public.profiles(id),
  acknowledged_at  timestamptz,
  created_at       timestamptz not null default now()
);

create index if not exists care_team_alerts_facility_status_idx
  on public.care_team_alerts (facility, status, created_at desc);

alter table public.care_team_alerts enable row level security;

-- The facility's care team reads its own alerts; super admins read all.
create policy "Care team reads facility alerts"
  on public.care_team_alerts for select to authenticated
  using (
    (is_clinical_staff() or is_admin())
    and (is_super_admin() or facility is null or facility = current_user_facility())
  );

-- The same staff may acknowledge / resolve them.
create policy "Care team updates facility alerts"
  on public.care_team_alerts for update to authenticated
  using (
    (is_clinical_staff() or is_admin())
    and (is_super_admin() or facility is null or facility = current_user_facility())
  )
  with check (
    (is_clinical_staff() or is_admin())
    and (is_super_admin() or facility is null or facility = current_user_facility())
  );

-- No INSERT policy: only the Edge Function (service role, which bypasses RLS)
-- creates alerts, so a member can never fabricate one for someone else.
