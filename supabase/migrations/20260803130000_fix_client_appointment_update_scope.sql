-- Tighten the client self-update policy on appointments.
--
-- The original "Client cancels own appointment" policy only checked
-- `client_id = auth.uid()` in its WITH CHECK — despite the comment "may update
-- their own row only to cancel it." With no status constraint, a client could
-- PATCH their own row to status='confirmed', set scheduled_start, or reassign
-- provider_id — self-approving a request and bypassing the scheduler gate that
-- the whole telehealth design depends on. The app UI never exposes this, but
-- the REST API does.
--
-- Fix: the new row a client writes must be `cancelled`. That is the only
-- self-service transition a client is allowed; every other transition
-- (confirm, reschedule, reassign) must go through a scheduler/clinician under
-- the "Staff update facility appointments" policy.

drop policy if exists "Client cancels own appointment" on public.appointments;

create policy "Client cancels own appointment"
  on public.appointments for update to authenticated
  using (client_id = auth.uid())
  with check (client_id = auth.uid() and status = 'cancelled');

-- ── Close the NULL-facility cross-facility read leak ─────────────────────
-- The staff SELECT policy admitted `facility is null` for ANY facility's
-- staff. A super-admin who schedules a session directly (their own
-- adminFacility/facility are both null) creates a NULL-facility row — which
-- then leaked into every facility's staff view, violating the Ohio-only
-- scoping. The client and the assigned provider still see the row via their
-- own dedicated SELECT policies; a NULL-facility row should otherwise be
-- visible only to super-admins.
drop policy if exists "Facility staff read facility appointments" on public.appointments;

create policy "Facility staff read facility appointments"
  on public.appointments for select to authenticated
  using (
    (is_clinical_staff() or is_admin())
    and (is_super_admin() or facility = current_user_facility())
  );
