-- Facility-scope meetings.
--
-- Until now `meetings` had no facility column and the read policy was simply
-- `auth.uid() IS NOT NULL`, so every member of both facilities saw every
-- meeting — an Ohio member in Steubenville was shown in-person meetings at
-- Florida street addresses.
--
-- facility semantics (matches `announcements`):
--   'florida' / 'ohio' -> visible to that facility only
--   NULL               -> visible to BOTH facilities (used for shared virtual
--                         meetings; surfaced in the UI as "Both facilities")

alter table public.meetings
  add column if not exists facility text;

alter table public.meetings
  drop constraint if exists meetings_facility_check;

alter table public.meetings
  add constraint meetings_facility_check
  check (facility is null or facility in ('florida', 'ohio'));

-- Backfill the seeded meetings from their physical address / title.
-- Anything without a location stays NULL (both) rather than being guessed
-- into one facility and disappearing for the other.
update public.meetings
   set facility = 'ohio'
 where facility is null
   and (location_address ilike '%steubenville%'
        or location_address ilike '%jefferson%'
        or title ilike '%ohio%');

update public.meetings
   set facility = 'florida'
 where facility is null
   and (location_address ilike '%delray%'
        or location_address ilike '%milton recovery%'
        or title ilike '%florida%');

-- Facility-scoped read. Super admins see everything so they can administer
-- both facilities from one login. Uses the existing SECURITY DEFINER helpers
-- (current_user_facility / is_super_admin) rather than sub-selecting profiles
-- here, which would re-introduce the 42P17 recursion this schema hit before.
drop policy if exists "Authenticated users read meetings" on public.meetings;

create policy "Members read own-facility meetings"
  on public.meetings
  for select
  to authenticated
  using (
    facility is null
    or is_super_admin()
    or facility = current_user_facility()
  );

create index if not exists meetings_facility_idx on public.meetings (facility);
