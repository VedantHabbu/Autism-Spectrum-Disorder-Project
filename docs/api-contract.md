# API Contract

Base path: `/api/v1`. All JSON requests and responses use `application/json`.

**Implemented and working (no Supabase needed):** `GET /health`, `POST /api/v1/analyze-observation`.

**Implemented as contract only (routes, schemas, validation) — return `503`** until Supabase/PostgreSQL is configured (`app/core/persistence.py`): `POST /api/v1/auth/sign-up`, `POST /api/v1/auth/login`, `POST /api/v1/children`, `GET /api/v1/children/{child_id}`, `POST /api/v1/observation-periods`, `POST /api/v1/observations`, `GET /api/v1/observations`, `GET /api/v1/observations/{observation_id}`, `POST /api/v1/guided-observations`. Each 503 response body is `{"detail": "Persistence is not configured yet: Supabase/PostgreSQL integration is pending ..."}`. This is a deliberate decision — see the note at the end of this document.

## `GET /health`

**Purpose:** confirm that the FastAPI service is running.

**Request:** no body.

**Response (`200`):**

```json
{"status":"ok","service":"asd-nlp-backend","version":"0.1.0"}
```

## `POST /api/v1/analyze-observation` — implemented (Week 3)

**Purpose:** run the rule-based NLP pipeline (`docs/nlp-pipeline.md`) on submitted caregiver text and return structured behavioural events. Does not diagnose ASD and does not require persistence.

**Request:**

```json
{"text": "He doesn't look towards me when I call his name."}
```

**Response (`200`):**

```json
{
  "events": [
    {
      "domain": "response_to_name",
      "status": "concern",
      "negation_detected": true,
      "evidence": "He doesn't look towards me when I call his name.",
      "confidence": 0.7
    }
  ],
  "disclaimer": "This output is an experimental NLP screening-support signal. It is not a diagnosis of ASD and does not replace clinical assessment."
}
```

An observation can produce zero, one, or several events (one per matched domain per sentence). `confidence` is a heuristic, not a calibrated or clinical probability.

**Validation:** `text` 1-4000 characters.

**Expected errors:** `422` invalid input, `500` unexpected failure.

## `POST /api/v1/auth/sign-up`, `POST /api/v1/auth/login` — contract only

**Purpose:** caregiver authentication, delegated to Supabase Auth once configured.

**Request (`SignUpRequest`/`LoginRequest`):** `{"email": "...", "password": "..."}` (password 8-128 chars).

**Planned response (`AuthResponse`):** `{"caregiver_id": "...", "access_token": "...", "token_type": "bearer"}`.

**Current behaviour:** `503` — see note below.

## `POST /api/v1/children`, `GET /api/v1/children/{child_id}` — contract only

**Request (`ChildCreateRequest`):** `{"display_name": "...", "date_of_birth": "YYYY-MM-DD"}` (`date_of_birth` optional).

**Planned response (`ChildResponse`):** id, `caregiver_id`, `display_name`, `date_of_birth`, `created_at`, `updated_at`.

**Current behaviour:** `503`.

## `POST /api/v1/observation-periods` — contract only

**Request (`ObservationPeriodCreateRequest`):** `{"child_id": "uuid", "start_at": "...", "end_at": "..."}` or `duration_days` (1-90) instead of `end_at`.

The monitoring window can be expressed three ways:

| Supplied | Result |
| --- | --- |
| `end_at` only | Used as-is. |
| `duration_days` only | Resolved to `end_at = start_at + duration_days` (the plan's "configurable monitoring window such as 7 days"), so consumers only ever read `end_at`. |
| Both | Accepted only if they agree; a conflicting pair is rejected rather than silently preferring one. |
| Neither | Open-ended period (`end_at` stays null, as the schema allows). |

Validation also rejects `end_at` before `start_at`.

**Current behaviour:** `503`.

## `POST /api/v1/observations`, `GET /api/v1/observations`, `GET /api/v1/observations/{observation_id}` — contract only

**Request (`ObservationCreateRequest`):**

```json
{
  "child_id": "uuid",
  "observation_period_id": "uuid",
  "text": "He looked at me during breakfast.",
  "context": "eating",
  "observed_at": "2026-09-05T10:30:00Z"
}
```

`context` must be one of the approved `ObservationContext` values (`playing`, `eating`, `social_interaction`, `outdoors`, `with_family`, `with_unfamiliar_people`, `other`); `observed_at` is optional and will be recorded automatically when omitted, once persistence exists.

The request deliberately carries **no `source_type`** — this route always records a free-text diary entry, and the server assigns `source_type: "free_text"`, so a client cannot record a guided entry as free text. `ObservationResponse` does return `source_type` (`free_text` | `guided`), because these endpoints read back both entry types from the shared `observations` table (see [database-schema.md](database-schema.md)). Its `text` field is nullable for that reason: a guided entry's note is optional, while a free-text entry always has text.

**Current behaviour:** `503`.

## `POST /api/v1/guided-observations` — contract only

**Request (`GuidedObservationCreateRequest`):**

```json
{
  "child_id": "uuid",
  "observation_period_id": "uuid",
  "domain": "eye_contact",
  "choice": "observed_with_concern",
  "note": "optional free-text note",
  "context": "playing"
}
```

`domain` must be one of the 10 behavioural-taxonomy keys; `choice` must be one of `observed_normally`, `observed_with_concern`, `not_observed`, `not_sure`. `not_observed` is stored verbatim and never collapsed into a concern — the plan requires "behaviour not observed" to stay distinct from "behaviour absent/reduced".

One call will write two linked rows: an `observations` row (`source_type: "guided"`, carrying child, period, context, timestamp, and the optional note) and a `guided_observation_responses` row holding the structured answer. `GuidedObservationResponse` therefore returns **`observation_id`** alongside `id`, so a guided answer can always be traced back to its source observation.

**Current behaviour:** `503`.

## Status update: the database now exists

The Supabase database is applied and enforcing RLS (see
[supabase-integration.md](supabase-integration.md)), but **these FastAPI
routes still return `503`, now by architectural choice rather than
absence.** The caregiver client talks to Supabase directly for
persistence so that RLS is the enforcement boundary, while FastAPI stays
a stateless NLP service holding no database credential.

The routes are retained as a documented, validated contract: they capture
the request/response shapes the data layer must satisfy, and they are the
place to wire server-side persistence later if it is ever needed (by
forwarding the caregiver's JWT, never a service-role key).

The section below records the original reasoning.

## Why these routes return 503 instead of using a local database

No Supabase project/credentials exist yet for this student prototype. Rather than build a SQLite or in-memory substitute that would need to be rewritten once Supabase is configured (and could mask persistence-layer bugs behind fake data), every persistence-backed route's request/response contract, validation, and routing is fully implemented and tested (`backend/tests/test_schema_validation.py`, `backend/tests/test_pending_persistence_routes.py`), and the route itself returns a clear `503` via the shared `require_persistence` dependency (`app/core/persistence.py`) until real Supabase/PostgreSQL credentials are wired in. At that point, only the repository/data-access layer needs to be added — no API contract changes.
