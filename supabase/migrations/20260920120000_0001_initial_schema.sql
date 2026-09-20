-- Planned PostgreSQL/Supabase schema draft. Not yet executed against a
-- database; no connection settings, credentials, RLS policies, or sample
-- patient data are included here.
--
-- Original caregiver text is retained in observations.source_text.
--
-- Free-text and guided observations share one observations table: the
-- mentor plan's architecture routes both entry types through a single
-- "OBSERVATION DATABASE", and the longitudinal-observation-database
-- feature requires "the complete sequence of caregiver observations"
-- rather than isolated per-feature tables. observations.source_type
-- distinguishes the two, and a guided entry's structured answer lives in
-- guided_observation_responses, linked 1:1 back to its observation row.

create table caregivers (
    id uuid primary key,
    auth_user_id uuid unique not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table children (
    id uuid primary key,
    caregiver_id uuid not null references caregivers(id),
    display_name text,
    date_of_birth date,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now()
);

create table observation_periods (
    id uuid primary key,
    child_id uuid not null references children(id),
    start_at timestamptz not null,
    end_at timestamptz,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    check (end_at is null or end_at >= start_at)
);

create table observations (
    id uuid primary key,
    child_id uuid not null references children(id),
    observation_period_id uuid references observation_periods(id),
    source_type text not null,
    -- Required for a free-text diary entry (that text IS the observation).
    -- Optional for a guided entry, where the plan makes the free-text note
    -- optional and the structured answer carries the meaning. Never an
    -- empty/whitespace string in either case.
    source_text text,
    context text,
    observed_at timestamptz not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    check (source_type in ('free_text', 'guided')),
    check (source_text is null or length(trim(source_text)) > 0),
    check (source_type <> 'free_text' or source_text is not null)
);

-- Structured answer for a guided observation, 1:1 with its observations
-- row (which carries the child, period, context, timestamp, and optional
-- free-text note). Storing `choice` verbatim is what keeps "not_observed"
-- distinct from "observed_with_concern" — the plan requires that
-- "behaviour not observed" never collapse into "behaviour absent/reduced".
create table guided_observation_responses (
    id uuid primary key,
    observation_id uuid unique not null references observations(id),
    -- Behavioural-taxonomy machine key. Intentionally not constrained to a
    -- fixed list (matching behavioural_events.domain): the taxonomy in
    -- docs/behavioural-taxonomy.md is provisional until clinical review.
    domain text not null,
    choice text not null,
    created_at timestamptz not null default now(),
    check (choice in ('observed_normally', 'observed_with_concern', 'not_observed', 'not_sure'))
);

create table behavioural_events (
    id uuid primary key,
    observation_id uuid not null references observations(id),
    domain text not null,
    status text not null,
    negation_detected boolean not null default false,
    evidence_phrase text,
    nlp_confidence numeric,
    created_at timestamptz not null default now(),
    check (nlp_confidence is null or (nlp_confidence >= 0 and nlp_confidence <= 1))
);

create table reports (
    id uuid primary key,
    child_id uuid not null references children(id),
    observation_period_id uuid references observation_periods(id),
    report_type text not null,
    content jsonb not null,
    created_at timestamptz not null default now()
);

create index observations_child_observed_at_idx on observations (child_id, observed_at);
create index behavioural_events_observation_id_idx on behavioural_events (observation_id);
-- Supports the planned observation-coverage indicator (which domains have
-- good/limited/insufficient coverage) without scanning every observation.
create index guided_observation_responses_domain_idx on guided_observation_responses (domain);
