-- 0006: reset `authenticated` to exactly the privileges 0005 intended.
--
-- Supabase configures a default ACL for the `postgres` role granting Dxtm
-- (TRUNCATE, REFERENCES, TRIGGER, MAINTAIN) on every new table in public.
-- Migrations run as `postgres`, so each `create table` in 0001 silently
-- handed those to anon and authenticated; 0005's grants were added on top
-- of that inheritance rather than replacing it.
--
-- TRUNCATE is the one that matters: ROW LEVEL SECURITY DOES NOT APPLY TO
-- TRUNCATE. An authenticated session on a direct Postgres connection could
-- have wiped all seven tables across every caregiver — contradicting the
-- requirement to preserve the source observation and its interpretation.
-- (It was never reachable through PostgREST, which does not issue TRUNCATE.)
--
-- Revoke-then-regrant rather than revoking named privileges: it states the
-- exact end state regardless of what the defaults added, and avoids naming
-- MAINTAIN, which only exists on PostgreSQL 15+.
--
-- Not destructive: no data is touched, no object is dropped. `service_role`
-- is intentionally left alone — it is meant to be privileged.

revoke all on public.caregivers from authenticated;
grant select, update on public.caregivers to authenticated;

revoke all on public.children from authenticated;
grant select, insert, update on public.children to authenticated;

revoke all on public.observation_periods from authenticated;
grant select, insert, update on public.observation_periods to authenticated;

revoke all on public.observations from authenticated;
grant select, insert, update on public.observations to authenticated;

revoke all on public.reports from authenticated;
grant select, insert, update on public.reports to authenticated;

-- Point-in-time records: insert and read, never rewrite.
revoke all on public.guided_observation_responses from authenticated;
grant select, insert on public.guided_observation_responses to authenticated;

revoke all on public.behavioural_events from authenticated;
grant select, insert on public.behavioural_events to authenticated;

-- Prevent recurrence: stop future tables in public from inheriting these
-- privileges, so a later migration does not silently reintroduce TRUNCATE.
alter default privileges for role postgres in schema public
    revoke all on tables from anon, authenticated;
