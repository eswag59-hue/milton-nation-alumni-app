-- Fix: the phone-change guard never fired.
--
-- enforce_verified_phone_change() was declared SECURITY DEFINER. Inside a
-- SECURITY DEFINER function `current_user` is the function OWNER (postgres),
-- not the role that issued the UPDATE — so the check
--     current_user not in ('service_role','postgres','supabase_admin')
-- was always false and the exception was never raised. A member could PATCH
-- profiles.phone directly with their own token, which is exactly the
-- account-takeover path the trigger existed to close. Confirmed by doing it
-- with a real member JWT.
--
-- SECURITY INVOKER is correct here: the function needs no elevated rights, it
-- only inspects the row and raises. As INVOKER, current_user is the role
-- PostgREST switched to — 'authenticated' for a member request, 'service_role'
-- for the change-phone Edge Function.

create or replace function public.enforce_verified_phone_change()
returns trigger
language plpgsql
security invoker
set search_path = public
as $$
begin
  if new.phone is distinct from old.phone
     and current_user not in ('service_role', 'postgres', 'supabase_admin')
  then
    raise exception
      'Phone changes must go through the verified change-phone flow'
      using errcode = '42501';
  end if;
  return new;
end;
$$;

drop trigger if exists enforce_verified_phone_change on public.profiles;

create trigger enforce_verified_phone_change
  before update of phone on public.profiles
  for each row
  execute function public.enforce_verified_phone_change();
