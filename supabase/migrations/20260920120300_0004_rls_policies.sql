-- 0004: Row Level Security for all 7 tables.
--
-- Ownership chain:
--   auth.users -> caregivers -> children -> observation_periods
--                                        -> observations -> guided_observation_responses
--                                                        -> behavioural_events
--                                        -> reports
--
-- Every policy is scoped TO authenticated. `anon` therefore has no policy
-- at all, and with RLS enabled "no policy" means "no access" — so
-- unauthenticated users are denied structurally, not by omission.

-- ---------------------------------------------------------------------
-- Ownership helpers
--
-- These live in a NON-EXPOSED schema. They return boolean/uuid, so if they
-- were in `public` PostgREST would publish them as callable RPC endpoints.
-- `private` is not in the Data API's exposed schema list, so they are
-- reachable only from inside policy expressions.
--
-- SECURITY DEFINER is deliberate: it lets the lookup read the ownership
-- tables without re-entering their own RLS policies, which keeps the deep
-- policies simple and avoids recursive evaluation. Each function discloses
-- nothing beyond "does the CURRENT user own this row", so the elevated
-- privilege cannot be used to read another caregiver's data.
--
-- (select auth.uid()) rather than auth.uid() so PostgreSQL evaluates it
-- once as an InitPlan instead of once per row.
-- ---------------------------------------------------------------------
create schema if not exists private;

create or replace function private.current_caregiver_id()
returns uuid
language sql
stable
security definer
set search_path = ''
as $$
    select c.id
    from public.caregivers c
    where c.auth_user_id = (select auth.uid());
$$;

create or replace function private.owns_child(target_child_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1
        from public.children ch
        join public.caregivers c on c.id = ch.caregiver_id
        where ch.id = target_child_id
          and c.auth_user_id = (select auth.uid())
    );
$$;

create or replace function private.owns_observation(target_observation_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1
        from public.observations o
        join public.children ch on ch.id = o.child_id
        join public.caregivers c on c.id = ch.caregiver_id
        where o.id = target_observation_id
          and c.auth_user_id = (select auth.uid())
    );
$$;

-- ---------------------------------------------------------------------
-- Enable RLS
--
-- Stated explicitly rather than relying on the project's "Automatic RLS"
-- setting, which applies to tables created through the dashboard table
-- editor rather than to migration SQL. These statements are idempotent
-- and make the state provable.
-- ---------------------------------------------------------------------
alter table public.caregivers                   enable row level security;
alter table public.children                     enable row level security;
alter table public.observation_periods          enable row level security;
alter table public.observations                 enable row level security;
alter table public.guided_observation_responses enable row level security;
alter table public.behavioural_events           enable row level security;
alter table public.reports                      enable row level security;

-- ---------------------------------------------------------------------
-- caregivers — reached directly through auth.uid()
--
-- No INSERT policy: the row is created by the SECURITY DEFINER trigger in
-- 0003. No DELETE policy anywhere in this file (auditability).
-- ---------------------------------------------------------------------
create policy caregivers_select_own on public.caregivers
    for select to authenticated
    using (auth_user_id = (select auth.uid()));

create policy caregivers_update_own on public.caregivers
    for update to authenticated
    using (auth_user_id = (select auth.uid()))
    with check (auth_user_id = (select auth.uid()));

-- ---------------------------------------------------------------------
-- children — one hop
--
-- WITH CHECK mirrors USING on every INSERT/UPDATE below. Without it a
-- caregiver could attach a new row to another caregiver's child, which is
-- the most likely way to get ownership wrong.
-- ---------------------------------------------------------------------
create policy children_select_own on public.children
    for select to authenticated
    using (caregiver_id = private.current_caregiver_id());

create policy children_insert_own on public.children
    for insert to authenticated
    with check (caregiver_id = private.current_caregiver_id());

create policy children_update_own on public.children
    for update to authenticated
    using (caregiver_id = private.current_caregiver_id())
    with check (caregiver_id = private.current_caregiver_id());

-- ---------------------------------------------------------------------
-- observation_periods — via child
-- ---------------------------------------------------------------------
create policy observation_periods_select_own on public.observation_periods
    for select to authenticated
    using (private.owns_child(child_id));

create policy observation_periods_insert_own on public.observation_periods
    for insert to authenticated
    with check (private.owns_child(child_id));

create policy observation_periods_update_own on public.observation_periods
    for update to authenticated
    using (private.owns_child(child_id))
    with check (private.owns_child(child_id));

-- ---------------------------------------------------------------------
-- observations — via child. Holds the caregiver's original text.
-- ---------------------------------------------------------------------
create policy observations_select_own on public.observations
    for select to authenticated
    using (private.owns_child(child_id));

create policy observations_insert_own on public.observations
    for insert to authenticated
    with check (private.owns_child(child_id));

create policy observations_update_own on public.observations
    for update to authenticated
    using (private.owns_child(child_id))
    with check (private.owns_child(child_id));

-- ---------------------------------------------------------------------
-- guided_observation_responses — via observation
--
-- No UPDATE policy: a guided answer records what the caregiver selected at
-- a point in time. Correcting it means recording a new observation.
-- ---------------------------------------------------------------------
create policy guided_observation_responses_select_own on public.guided_observation_responses
    for select to authenticated
    using (private.owns_observation(observation_id));

create policy guided_observation_responses_insert_own on public.guided_observation_responses
    for insert to authenticated
    with check (private.owns_observation(observation_id));

-- ---------------------------------------------------------------------
-- behavioural_events — via observation
--
-- No UPDATE policy: these are machine-generated NLP output. A changed
-- interpretation is a new extraction run, not an edit.
-- ---------------------------------------------------------------------
create policy behavioural_events_select_own on public.behavioural_events
    for select to authenticated
    using (private.owns_observation(observation_id));

create policy behavioural_events_insert_own on public.behavioural_events
    for insert to authenticated
    with check (private.owns_observation(observation_id));

-- ---------------------------------------------------------------------
-- reports — via child
-- ---------------------------------------------------------------------
create policy reports_select_own on public.reports
    for select to authenticated
    using (private.owns_child(child_id));

create policy reports_insert_own on public.reports
    for insert to authenticated
    with check (private.owns_child(child_id));

create policy reports_update_own on public.reports
    for update to authenticated
    using (private.owns_child(child_id))
    with check (private.owns_child(child_id));
