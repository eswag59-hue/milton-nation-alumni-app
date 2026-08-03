-- Phone changes must prove ownership of the NEW number.
--
-- `updateProfile` writes full_name AND phone in one statement, and the profiles
-- UPDATE policy lets a member update their own row. That means a modified or
-- replayed client could PATCH profiles.phone directly and skip the Twilio
-- verification entirely — turning "edit my profile" into an account-takeover
-- path, because the phone is where the login OTP is delivered.
--
-- The change-phone Edge Function runs with the service role, so it is allowed
-- through. Everything else is refused at the table.

create or replace function public.enforce_verified_phone_change()
returns trigger
language plpgsql
security definer
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
