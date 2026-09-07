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

## Week 1 implementation boundary

Only the FastAPI application foundation and its health endpoint are implemented. Database connectivity, source-observation persistence, NLP/ML processing, longitudinal functions, LLM reports, and Flutter feature flows remain planned.
