-- Planned PostgreSQL/Supabase schema draft. Not executed in Week 1.
-- Original caregiver text is retained in observations.source_text.

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
    source_text text not null,
    context text,
    observed_at timestamptz not null,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),
    check (length(trim(source_text)) > 0)
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
