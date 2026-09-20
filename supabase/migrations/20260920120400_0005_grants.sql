-- 0005: Data API grants.
--
-- The project has "Automatically expose new tables" switched OFF, so
-- nothing in public is reachable through the Data API until granted here.
--
-- Grants and RLS are independent layers and BOTH are required: a grant
-- says which commands a role may attempt, the policy in 0004 says which
-- rows it may touch. Neither alone is sufficient.

-- Already present on Supabase projects; restated so the requirement is
-- explicit rather than assumed.
grant usage on schema public to authenticated;

-- Needed so policy expressions can call the ownership helpers. The
-- `private` schema is NOT in the Data API's exposed schema list, so this
-- does not make the functions callable as RPC endpoints.
grant usage on schema private to authenticated;
grant execute on function private.current_caregiver_id() to authenticated;
grant execute on function private.owns_child(uuid) to authenticated;
grant execute on function private.owns_observation(uuid) to authenticated;

-- ---------------------------------------------------------------------
-- Table privileges for `authenticated`
--
-- DELETE is deliberately granted nowhere. The mentor plan requires the
-- source observation and its interpretation to be preserved so findings
-- can be traced back to evidence; a soft-delete/retention policy can be
-- added later if needed.
-- ---------------------------------------------------------------------

-- INSERT is not granted: the caregiver row is created by the signup
-- trigger in 0003, which runs as SECURITY DEFINER.
grant select, update on public.caregivers to authenticated;

grant select, insert, update on public.children            to authenticated;
grant select, insert, update on public.observation_periods to authenticated;
grant select, insert, update on public.observations        to authenticated;
grant select, insert, update on public.reports             to authenticated;

-- Point-in-time records: insert and read, never rewrite.
grant select, insert on public.guided_observation_responses to authenticated;
grant select, insert on public.behavioural_events           to authenticated;

-- ---------------------------------------------------------------------
-- Lock out `anon`
--
-- With auto-expose off these grants should never have been created, so
-- this asserts the end state rather than assuming it. Schema USAGE is
-- intentionally left alone: revoking it changes PostgREST's behaviour for
-- anonymous requests in confusing ways, and with no table privileges and
-- no policies, anon already has no path to application data.
-- ---------------------------------------------------------------------
revoke all on public.caregivers                   from anon;
revoke all on public.children                     from anon;
revoke all on public.observation_periods          from anon;
revoke all on public.observations                 from anon;
revoke all on public.guided_observation_responses from anon;
revoke all on public.behavioural_events           from anon;
revoke all on public.reports                      from anon;

revoke all on schema private from anon;
