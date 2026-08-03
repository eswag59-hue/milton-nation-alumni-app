-- Fix: facility scoping on meetings did not apply to admins or clinical staff.
--
-- "Admins manage meetings" and "Staff manage meetings" were both `FOR ALL`,
-- and ALL includes SELECT. RLS policies are PERMISSIVE, so they OR-combine:
-- any admin satisfied is_admin() and therefore read EVERY meeting, which
-- silently nullified "Members read own-facility meetings". An Ohio admin was
-- still shown Florida street addresses.
--
-- Verified by the Ohio admin in the running app, not by inspection.
--
-- Fix: the manage policies now cover only the write commands, so SELECT is
-- governed solely by the facility-scoped read policy (which already admits
-- super admins and NULL/both-facility rows). Writes additionally gain a
-- WITH CHECK so a Florida admin cannot author into Ohio.

drop policy if exists "Admins manage meetings" on public.meetings;
drop policy if exists "Staff manage meetings" on public.meetings;

-- Who may write, and into which facility.
-- NULL facility ("both") is allowed so staff can create shared virtual meetings.
create policy "Staff insert meetings in own facility"
  on public.meetings for insert to authenticated
  with check (
    (is_admin() or is_clinical_staff())
    and (is_super_admin() or facility is null or facility = current_user_facility())
  );

create policy "Staff update meetings in own facility"
  on public.meetings for update to authenticated
  using (
    (is_admin() or is_clinical_staff())
    and (is_super_admin() or facility is null or facility = current_user_facility())
  )
  with check (
    is_super_admin() or facility is null or facility = current_user_facility()
  );

create policy "Staff delete meetings in own facility"
  on public.meetings for delete to authenticated
  using (
    (is_admin() or is_clinical_staff())
    and (is_super_admin() or facility is null or facility = current_user_facility())
  );
