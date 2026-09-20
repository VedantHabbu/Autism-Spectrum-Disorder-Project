-- 0003: create the caregiver row automatically at signup.
--
-- Signup happens in Flutter talking to Supabase Auth directly, so no
-- application code is guaranteed to run afterwards. A database trigger
-- also covers email-confirmation flows, OAuth, and users created from the
-- Supabase dashboard.
--
-- Depends on 0002, which added the gen_random_uuid() default for
-- caregivers.id.

-- SECURITY DEFINER so the insert runs as the function owner and is not
-- blocked by the row-level security added in 0004.
--
-- `set search_path = ''` is the hardened form: nothing is resolved from a
-- caller-controlled search path, so every object below is fully qualified.
--
-- The body is deliberately trivial and idempotent. A failure here would
-- fail the entire signup transaction, so it must not be able to error:
-- `on conflict do nothing` makes a repeated insert harmless.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    insert into public.caregivers (auth_user_id)
    values (new.id)
    on conflict (auth_user_id) do nothing;

    return new;
end;
$$;

create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_user();
