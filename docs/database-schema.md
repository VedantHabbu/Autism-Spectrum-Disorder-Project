# Planned PostgreSQL / Supabase Database Schema

This is a design for later Supabase/PostgreSQL implementation. No database connection or credentials are included in Week 1. UUID primary keys and `timestamptz` timestamps are proposed.

## Entities and relationships

```text
caregivers/users 1 ── * children 1 ── * observation_periods
                                      └── * observations 1 ── * behavioural_events
children 1 ── * reports
observation_periods 1 ── * reports
```

## Tables

| Table | Primary key | Important fields | Relationships |
| --- | --- | --- | --- |
| `caregivers` | `id uuid` | `auth_user_id uuid`, `created_at`, `updated_at` | Maps a permitted app user to child records. In Supabase, `auth_user_id` will reference `auth.users`. |
| `children` | `id uuid` | `caregiver_id uuid`, editable basic profile fields, `created_at`, `updated_at` | `caregiver_id → caregivers.id`; owns periods, observations, and reports. |
| `observation_periods` | `id uuid` | `child_id uuid`, `start_at`, `end_at`, `created_at`, `updated_at` | `child_id → children.id`; supports a configurable doctor-defined monitoring window. |
| `observations` | `id uuid` | `child_id uuid`, `observation_period_id uuid`, `source_type`, `source_text`, `context`, `observed_at`, `created_at`, `updated_at` | Retains original caregiver observation. References child and period. |
| `behavioural_events` | `id uuid` | `observation_id uuid`, `domain`, `status`, `negation_detected`, `evidence_phrase`, `nlp_confidence`, `created_at` | `observation_id → observations.id`; many events can be linked to one source observation. |
| `reports` | `id uuid` | `child_id uuid`, `observation_period_id uuid`, `report_type`, `content`, `created_at` | References child and optional period; later stores role-specific generated reports. |

## Source evidence rule

`observations.source_text` is the authoritative source record and must be preserved. `behavioural_events` stores the interpretation and exact evidence phrase, never replaces the source observation. A clinician-facing retrieval must link every event back to its original observation.

## Access and audit foundation

Supabase Row-Level Security is planned to restrict each caregiver to authorized child records. Timestamps support traceability; a later audit design will preserve the source observation, interpretation, and generated reports.

## Schema draft

See [`../backend/sql/001_initial_schema.sql`](../backend/sql/001_initial_schema.sql) for a non-executed PostgreSQL draft. It intentionally contains no connection settings, credentials, policies, or sample patient data.
