/// Backend base URL. The FastAPI service has no Supabase-backed
/// persistence yet (see docs/api-contract.md), so most endpoints beyond
/// /health and /analyze-observation intentionally respond 503.
///
/// 127.0.0.1 works for Linux/macOS/Windows desktop and web builds run
/// against a locally started backend. An Android emulator must use
/// 10.0.2.2 instead; a physical device needs the host machine's LAN IP.
const String apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8000',
);

/// Maximum observation length the backend accepts, mirroring
/// ObservationAnalysisRequest.text in backend/app/schemas/observations.py.
/// Keep these in sync: the client enforces it so the caregiver sees the
/// limit while typing rather than hitting a 422 on submit.
const int observationTextMaxLength = 4000;
