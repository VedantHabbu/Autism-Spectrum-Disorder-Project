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

## Implementation boundary (updated Week 3)

Implemented: the FastAPI application foundation and health endpoint (Week 1); the structured-data ML baseline and synthetic-narrative dataset pipeline under `backend/ml/` (Week 2); the rule-based NLP preprocessing/negation/cue-extraction pipeline under `backend/app/nlp/` and its `POST /api/v1/analyze-observation` endpoint, plus Flutter screens for the caregiver-facing observation workflow (Week 3).

Still planned: Supabase/PostgreSQL connectivity and Row-Level Security, real caregiver authentication, source-observation and guided-observation persistence, longitudinal aggregation, the TF-IDF/embedding-based ML screening-concern model (Week 4+), explainability, and LLM-based report generation. Every persistence-backed API route already has its request/response contract and validation implemented but returns `503` until Supabase is configured — see docs/api-contract.md.
