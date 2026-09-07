# NLP-Based Early Risk Screening for Autism Spectrum Disorder in Toddlers

## Purpose

This mini-project is a caregiver-observation and clinical decision-support prototype. It will record timestamped free-text and guided observations, derive structured ASD-relevant behavioural events, and support review over a doctor-advised monitoring period.

## Safety disclaimer

This is an early risk-screening and decision-support prototype, **not a diagnostic system**. It must not present output as a confirmed ASD diagnosis or as a clinical probability of ASD. Clinicians remain decision-makers. Student development uses only de-identified or synthetic data unless required ethical approvals and governance procedures are in place.

## Architecture overview

`Flutter → Supabase/PostgreSQL → FastAPI NLP/ML service → structured behavioural events → longitudinal profile → temporal analysis / ML → explainability + coverage → structured findings → LLM → caregiver and clinician reports`

The NLP/ML layers will create traceable structured findings. Any future LLM component is downstream and will only format or explain those findings; it is not the primary diagnostic engine.

## Repository structure

- `backend/` — FastAPI service skeleton and backend tests
- `frontend/` — Flutter application skeleton
- `docs/` — mentor-plan-derived requirements and technical design
- `data/` — placeholder for approved/de-identified experimental data
- `tests/` — reserved for cross-component tests

## Technology stack

- Flutter (mobile client)
- Supabase Auth, PostgreSQL, and Row-Level Security (planned)
- Python, FastAPI, and Pydantic (backend foundation)
- Pandas, NumPy, spaCy/NLTK, scikit-learn, sentence transformers, SHAP, and an approved/API LLM are planned for later phases only.

## Current status — Week 1 foundation

Implemented now:

- Mentor-plan-aligned requirements, architecture, API, database, taxonomy, and data/EDA documentation.
- A modular FastAPI application with an implemented `GET /health` endpoint, versioned API route module, configuration, CORS foundation, and health test.
- A minimal Flutter home screen and project configuration ready to extend.
- Git repository initialization and ignore rules.

Planned, not implemented:

- Supabase connection, authentication, persistence, and observation APIs.
- NLP extraction, ML models, longitudinal analysis, reports, dashboards, and LLM integration.

## Run the backend

```bash
cd backend
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload
```

Open <http://127.0.0.1:8000/health> for the health response and <http://127.0.0.1:8000/docs> for Swagger UI.

## Run the Flutter skeleton

Install Flutter, then run:

```bash
cd frontend
flutter pub get
flutter analyze
flutter run
```

If platform folders have not yet been generated for the target machine, run `flutter create .` once from `frontend/`; this preserves the hand-authored skeleton files and creates the standard platform runners.

## Documentation

- [Requirements](docs/requirements.md)
- [Architecture](docs/architecture.md)
- [API contract](docs/api-contract.md)
- [Database schema](docs/database-schema.md)
- [Behavioural taxonomy](docs/behavioural-taxonomy.md)
- [Dataset and EDA plan](docs/dataset-and-eda.md)
