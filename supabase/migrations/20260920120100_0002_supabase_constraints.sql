-- 0002: Supabase/PostgreSQL adaptations for the Week 1-3 schema.
--
-- Additive only: no DROP, no TRUNCATE, no DELETE, no column removals.
-- Every statement either adds a default, a constraint, an index, or a
-- trigger. The application's API contracts are unchanged.

-- ---------------------------------------------------------------------
-- UUID primary-key defaults
--
-- Required: the create-contracts (ChildCreateRequest,
-- ObservationPeriodCreateRequest, GuidedObservationCreateRequest) accept
-- no `id`, so without a default every insert would fail on a NOT NULL
-- primary key. gen_random_uuid() is built into PostgreSQL 13+, so no
-- extension is needed on Supabase.
-- ---------------------------------------------------------------------
alter table public.caregivers                   alter column id set default gen_random_uuid();
alter table public.children                     alter column id set default gen_random_uuid();
alter table public.observation_periods          alter column id set default gen_random_uuid();
alter table public.observations                 alter column id set default gen_random_uuid();
alter table public.guided_observation_responses alter column id set default gen_random_uuid();
alter table public.behavioural_events           alter column id set default gen_random_uuid();
alter table public.reports                      alter column id set default gen_random_uuid();

-- ---------------------------------------------------------------------
-- Link caregivers to Supabase Auth
--
-- ON DELETE RESTRICT (approved): a cascade here would attempt to delete
-- the caregiver row, which children.caregiver_id already blocks, and a
-- full cascade down the chain would erase a child's entire clinical
-- record. Deleting an auth user is therefore a deliberate, auditable act.
-- ---------------------------------------------------------------------
alter table public.caregivers
    add constraint caregivers_auth_user_id_fkey
    foreign key (auth_user_id) references auth.users (id)
    on delete restrict;

-- ---------------------------------------------------------------------
-- Ownership indexes
--
-- Every RLS policy resolves ownership by walking these foreign keys.
-- observations.child_id is already covered by the leading column of
-- observations_child_observed_at_idx, and the observation_id columns are
-- already indexed, so only these five are missing.
-- ---------------------------------------------------------------------
create index if not exists children_caregiver_id_idx
    on public.children (caregiver_id);
create index if not exists observation_periods_child_id_idx
    on public.observation_periods (child_id);
create index if not exists observations_observation_period_id_idx
    on public.observations (observation_period_id);
create index if not exists reports_child_id_idx
    on public.reports (child_id);
create index if not exists reports_observation_period_id_idx
    on public.reports (observation_period_id);

-- ---------------------------------------------------------------------
-- An observation's period must belong to the same child
--
-- observations carries both child_id and observation_period_id, and
-- nothing previously tied them together: a row could reference one child
-- while pointing at a period belonging to a different child.
--
-- Enforced with a composite foreign key rather than an RLS predicate,
-- deliberately. RLS constrains who may write; it does not guarantee
-- referential consistency, and it is bypassed by SECURITY DEFINER
-- functions and by any service-role connection. A foreign key binds every
-- writer, now and later, without changing the architecture.
--
-- The composite key needs a matching unique constraint to reference. `id`
-- is already the primary key, so (id, child_id) is trivially unique; this
-- exists only to serve as the FK target.
--
-- Default MATCH SIMPLE semantics are exactly what is wanted here: when
-- observation_period_id is NULL the constraint is skipped, so observations
-- recorded outside a monitoring window remain valid.
--
-- The original single-column FK from 0001 is intentionally left in place.
-- It is now redundant but dropping it would be a destructive change to the
-- agreed base schema for no benefit.
-- ---------------------------------------------------------------------
alter table public.observation_periods
    add constraint observation_periods_id_child_id_key
    unique (id, child_id);

alter table public.observations
    add constraint observations_period_belongs_to_child_fkey
    foreign key (observation_period_id, child_id)
    references public.observation_periods (id, child_id);

-- reports has the same child_id/observation_period_id pairing and the same
-- latent inconsistency, so it gets the same guarantee. (Dormant until the
-- Week 7 report work, but cheaper to constrain now than to backfill later.)
alter table public.reports
    add constraint reports_period_belongs_to_child_fkey
    foreign key (observation_period_id, child_id)
    references public.observation_periods (id, child_id);

-- ---------------------------------------------------------------------
-- updated_at maintenance
--
-- The columns default to now() on insert but were never updated, so they
-- silently equalled created_at forever. Only the four tables that have an
-- updated_at column get the trigger.
--
-- Returns `trigger`, so PostgREST cannot expose it as an RPC endpoint;
-- it can safely live in the public schema.
-- ---------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
    new.updated_at = now();
    return new;
end;
$$;

create trigger caregivers_set_updated_at
    before update on public.caregivers
    for each row execute function public.set_updated_at();

create trigger children_set_updated_at
    before update on public.children
    for each row execute function public.set_updated_at();

create trigger observation_periods_set_updated_at
    before update on public.observation_periods
    for each row execute function public.set_updated_at();

create trigger observations_set_updated_at
    before update on public.observations
    for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------
-- Consistency constraints (approved)
--
-- These align the database with contracts the API already enforces.
-- `domain` columns are deliberately left unconstrained: the behavioural
-- taxonomy is provisional until clinical review (docs/behavioural-taxonomy.md).
-- ---------------------------------------------------------------------

-- Matches ObservationContext in app/schemas/common.py.
alter table public.observations
    add constraint observations_context_check
    check (
        context is null
        or context in (
            'playing',
            'eating',
            'social_interaction',
            'outdoors',
            'with_family',
            'with_unfamiliar_people',
            'other'
        )
    );

-- The NLP extractor currently emits typical/concern/uncertain. 'not_observed'
-- is included because the mentor plan names four status values for
-- negation/status detection, so adding it later needs no migration.
alter table public.behavioural_events
    add constraint behavioural_events_status_check
    check (status in ('typical', 'concern', 'uncertain', 'not_observed'));

-- ChildCreateRequest requires a non-empty display_name; the column was
-- nullable, leaving the database looser than the contract.
alter table public.children
    alter column display_name set not null;
