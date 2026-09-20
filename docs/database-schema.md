# Planned PostgreSQL / Supabase Database Schema

This is a design for later Supabase/PostgreSQL implementation. No database connection or credentials are included in Week 1. UUID primary keys and `timestamptz` timestamps are proposed.

## Entities and relationships

```text
caregivers/users 1 ── * children 1 ── * observation_periods
                                      └── * observations 1 ── * behavioural_events
                                                         └── 0..1 guided_observation_responses
children 1 ── * reports
observation_periods 1 ── * reports
```

## One observations table for both entry types

Free-text diary entries and guided observations are both stored as `observations` rows, distinguished by `source_type` (`free_text` | `guided`). This follows the mentor plan's architecture, which routes both entry types through a single "OBSERVATION DATABASE", and its longitudinal-observation-database requirement to "maintain the complete sequence of caregiver observations rather than treating each entry as an isolated sample" — a separate guided-only table would split that sequence in two.

A guided entry's structured answer (which domain was prompted, and which of the four choices the caregiver picked) lives in `guided_observation_responses`, linked 1:1 to its `observations` row. Storing `choice` verbatim is what keeps **`not_observed` distinct from `observed_with_concern`**, as the plan's safety boundary requires.

`source_type` is assigned by the server from the route used (`POST /api/v1/observations` → `free_text`, `POST /api/v1/guided-observations` → `guided`), never accepted from the client.

## Tables

| Table | Primary key | Important fields | Relationships |
| --- | --- | --- | --- |
| `caregivers` | `id uuid` | `auth_user_id uuid`, `created_at`, `updated_at` | Maps a permitted app user to child records. In Supabase, `auth_user_id` will reference `auth.users`. |
| `children` | `id uuid` | `caregiver_id uuid`, editable basic profile fields, `created_at`, `updated_at` | `caregiver_id → caregivers.id`; owns periods, observations, and reports. |
| `observation_periods` | `id uuid` | `child_id uuid`, `start_at`, `end_at`, `created_at`, `updated_at` | `child_id → children.id`; supports a configurable doctor-defined monitoring window. `end_at` is nullable for an open-ended period; the API resolves a `duration_days` request into a concrete `end_at`. |
| `observations` | `id uuid` | `child_id uuid`, `observation_period_id uuid`, `source_type`, `source_text`, `context`, `observed_at`, `created_at`, `updated_at` | Retains original caregiver observation. References child and period. `source_type` is constrained to `free_text`/`guided`. `source_text` is required for `free_text` rows and optional for `guided` rows (the plan makes the guided note optional), and is never an empty/whitespace string. |
| `guided_observation_responses` | `id uuid` | `observation_id uuid` (unique), `domain`, `choice`, `created_at` | `observation_id → observations.id`, 1:1. Holds the structured guided answer; `choice` is constrained to `observed_normally`/`observed_with_concern`/`not_observed`/`not_sure`. `domain` is deliberately unconstrained (like `behavioural_events.domain`) because the taxonomy is provisional until clinical review. |
| `behavioural_events` | `id uuid` | `observation_id uuid`, `domain`, `status`, `negation_detected`, `evidence_phrase`, `nlp_confidence`, `created_at` | `observation_id → observations.id`; many events can be linked to one source observation. |
| `reports` | `id uuid` | `child_id uuid`, `observation_period_id uuid`, `report_type`, `content`, `created_at` | References child and optional period; later stores role-specific generated reports. |

## Source evidence rule

`observations.source_text` is the authoritative source record and must be preserved. `behavioural_events` stores the interpretation and exact evidence phrase, never replaces the source observation. A clinician-facing retrieval must link every event back to its original observation.

For a guided entry, the authoritative record is the pair of rows: the caregiver's selected `choice` plus their optional note in `source_text`. Because `guided_observation_responses.observation_id` is a unique foreign key, a guided answer can always be traced back to the observation (and therefore the child, period, context, and timestamp) it came from.

## Access and audit foundation

Supabase Row-Level Security is planned to restrict each caregiver to authorized child records. Timestamps support traceability; a later audit design will preserve the source observation, interpretation, and generated reports.

## Schema draft and applied migrations

[`../backend/sql/001_initial_schema.sql`](../backend/sql/001_initial_schema.sql) remains the portable plain-PostgreSQL definition of the tables above. It contains no connection settings, credentials, policies, or sample patient data.

**`supabase/migrations/` is now authoritative for the deployed database.** It is applied to the Supabase project and reproducible from the repository:

| Migration | Adds |
| --- | --- |
| `0001_initial_schema` | byte-identical copy of `backend/sql/001_initial_schema.sql` |
| `0002_supabase_constraints` | UUID PK defaults; `caregivers.auth_user_id → auth.users(id)` (`ON DELETE RESTRICT`); five ownership indexes; `updated_at` trigger; `context`/`status` CHECKs; `display_name NOT NULL`; composite FKs binding an observation's (and report's) period to the same child |
| `0003_auth_caregiver_trigger` | creates the caregiver row on signup |
| `0004_rls_policies` | RLS on all 7 tables + 18 ownership policies |
| `0005_grants` / `0006_tighten_authenticated_grants` | Data API grants; removes privileges inherited from Supabase's default ACL |

Access control is described in [supabase-integration.md](supabase-integration.md).
