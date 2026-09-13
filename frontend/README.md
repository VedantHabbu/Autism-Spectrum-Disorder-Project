# Flutter client

Caregiver-facing screens for the ASD screening-support prototype: account
(sign-up/log-in), child profile, observation period, free-text and guided
observation, and observation history. See `../docs/api-contract.md` for
which backend endpoints are fully implemented versus contract-only
pending Supabase configuration — screens for pending endpoints render a
clear "pending" banner instead of failing silently or faking data.

With Flutter installed and the backend running (`../backend/README.md` /
root `README.md`), run `flutter pub get`, `flutter analyze`, and
`flutter run` in this directory. If a local platform runner is needed,
use `flutter create .` to generate the standard Android/iOS/web/desktop
runner files.

## Connecting to the backend

The app calls `http://127.0.0.1:8000` by default (`lib/core/api_config.dart`),
which works for desktop/web builds against a locally started backend.
Override it with `--dart-define=API_BASE_URL=...`, e.g.:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000   # Android emulator
```

## Structure

- `lib/core/` — API client (`api_client.dart`), typed `ApiOutcome` result
  (success / pending-Supabase / failure), config, and a local UUID helper.
- `lib/models/` — Dart mirrors of the backend's shared enums and the
  analysis response shape.
- `lib/features/` — one folder per screen (`auth`, `child_profile`,
  `observation_period`, `observation`, `home`).
- `lib/widgets/` — shared `DisclaimerBanner`, `PendingBanner`, `ErrorBanner`.

Every screen accepts an optional injected `ApiClient` so widget tests can
supply `package:http/testing.dart`'s `MockClient` instead of making real
network calls — see `test/`.
