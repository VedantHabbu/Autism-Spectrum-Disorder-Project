# System Architecture

## Mentor-plan architecture

```text
Caregiver Flutter application
  ├─ Free-text observation
  └─ Guided observation (+ adaptive prompts and optional note)
                  ↓
           Timestamp + context
                  ↓
      Supabase/PostgreSQL observation database
                  ↓
       FastAPI NLP/ML service
  ├─ Behaviour-domain extraction
  ├─ Negation/status detection
  └─ Semantic representation
                  ↓
       Structured behavioural event
                  ↓
     Longitudinal behavioural profile
        ├─ Temporal pattern analysis
        └─ ML screening-concern model
                  ↓
       Explainability + coverage
                  ↓
          Structured findings
                  ↓
                 LLM
          ┌───────┴────────┐
     Caregiver report   Clinician report
```

## Responsibilities

- **Flutter:** caregiver-facing workflow for access, child profiles, observation period, observations, later history/dashboard/reports.
- **Supabase/PostgreSQL:** protected storage for source observations, profiles, structured events, longitudinal aggregates, and reports.
- **FastAPI:** REST/JSON boundary for planned NLP/ML processing.
- **Structured behavioural events:** preserve domain, status, timestamp, context, evidence phrase, confidence, and the relationship to source observation.
- **Longitudinal and ML layers:** planned later; aggregate repeated observations and provide documented screening support.
- **LLM:** planned later and downstream only. It receives structured findings to produce role-specific language. It is not the primary diagnostic engine and must not replace the NLP/ML evidence path.

## Implementation boundary

Implemented:

- FastAPI application foundation and health endpoint (Week 1).
- Structured-data ML baseline and synthetic-narrative dataset pipeline under `backend/ml/` (Week 2).
- Rule-based NLP preprocessing/negation/cue-extraction under `backend/app/nlp/` and its `POST /api/v1/analyze-observation` endpoint, plus Flutter screens for the caregiver-facing observation workflow (Week 3).
- **Supabase PostgreSQL database**: all 7 tables, Row-Level Security on every table, 18 ownership policies, Data API grants, and the signup trigger that creates a caregiver row — applied from `supabase/migrations/` and verified against the live Data API with two real users. See [supabase-integration.md](supabase-integration.md).

Data-path decision: the caregiver client talks to **Supabase directly** for authentication and persistence, with RLS as the enforcement boundary, while **FastAPI remains a stateless NLP service** holding no database credential. This follows the mentor plan's stack, which assigns FastAPI the role of "expose NLP/ML services to the Flutter application through REST/JSON" and names Supabase Row-Level Security as the access-control layer.

Still outstanding:

- **Flutter is not yet connected to Supabase.** The database is live and enforcing RLS, but the app still calls the FastAPI persistence routes, which return `503` by design. Until that client integration lands, sign-up/login, child profiles, observation periods, observation storage, guided-observation submission, and history do not function in the running app.
- Longitudinal aggregation, the TF-IDF/embedding ML screening-concern model (Week 4+), explainability, and LLM-based report generation.
