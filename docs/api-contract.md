# Initial API Contract

Base path: `/api/v1`. All JSON requests and responses use `application/json`. The only implemented endpoint in Week 1 is `GET /health`; the versioned observation and analysis endpoints below are agreed contracts for subsequent work, not current functionality.

## `GET /health`

**Purpose:** confirm that the FastAPI service is running.

**Request:** no body.

**Response (`200`):**

```json
{"status":"ok","service":"asd-nlp-backend","version":"0.1.0"}
```

**Validation:** none.

**Expected errors:** `500` only for an unexpected service failure.

## `POST /api/v1/observations` — planned

**Purpose:** create and persist a caregiver source observation. Persistence will be introduced with the Supabase/PostgreSQL integration.

**Request:**

```json
{
  "child_id": "uuid",
  "observation_period_id": "uuid",
  "text": "He looked at me during breakfast.",
  "context": "eating",
  "observed_at": "2026-09-05T10:30:00Z"
}
```

`context` and `observed_at` are optional in the planned request; the application will automatically record the timestamp when it is omitted.

**Response (`201`, planned):** source observation identifier, child and period identifiers, preserved text, context, and timestamps.

**Validation:** valid UUIDs; non-empty text; text length limits to be finalized; context must be an approved value when supplied; period must belong to the specified child and authorized caregiver.

**Expected errors:** `400` invalid input, `401` unauthenticated, `403` unauthorized, `404` child/period not found, `422` schema validation, `500` unexpected failure.

## `GET /api/v1/observations/{observation_id}` — planned

**Purpose:** retrieve one original observation and, when available, its linked structured behavioural events.

**Request:** path parameter `observation_id` (UUID); no body.

**Response (`200`, planned):** preserved source observation metadata plus zero or more linked events. The original text must always be returned to authorized reviewers.

**Validation:** `observation_id` is a UUID and caller is authorized to access its child record.

**Expected errors:** `401` unauthenticated, `403` unauthorized, `404` not found, `422` invalid UUID, `500` unexpected failure.

## `POST /api/v1/analyze-observation` — planned

**Purpose:** submit source text for future NLP interpretation. It does not diagnose ASD. At the implemented stage, this endpoint is intentionally absent until the extraction approach and persistence workflow are introduced.

**Request:**

```json
{
  "text": "He doesn't look towards me when I call his name."
}
```

**Planned response (`200`):**

```json
{
  "domain": "response_to_name",
  "status": "concern",
  "negation_detected": true,
  "evidence": "doesn't look towards me when I call his name",
  "confidence": 0.91
}
```

The response is illustrative contract data only; it is not implemented NLP logic and the confidence value is not a clinical probability.

**Validation:** non-empty text; text length limit to be finalized; content must be handled as de-identified/synthetic data in student development.

**Expected errors:** `400` invalid input, `401`/`403` when future access control applies, `422` schema validation, `503` analysis service unavailable, `500` unexpected failure.
