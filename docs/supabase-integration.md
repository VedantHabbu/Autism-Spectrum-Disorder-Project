# Supabase Integration

The database, authentication backing, and access control for the project.
Everything here is reproducible from `supabase/migrations/` — the deployed
database is not hand-built dashboard state.

## Architecture decision

The caregiver client talks to **Supabase directly** for authentication and
persistence, with Row-Level Security as the enforcement boundary.
**FastAPI stays a stateless NLP service and holds no database
credential.**

This follows the mentor plan's technology stack, which gives FastAPI the
role "expose NLP/ML services to the Flutter application through
REST/JSON", names Supabase Auth for authentication, and names Supabase
Row-Level Security for access control.

The alternative — routing all data through FastAPI using a server-side
secret key — was rejected: the secret key bypasses RLS entirely, which
would make the policies decorative and turn every missing ownership check
in a route into a cross-caregiver data breach. If server-side writes are
ever needed, the caregiver's JWT should be passed through so RLS still
applies.

## Authentication

`auth.users.id` maps 1:1 to `caregivers.auth_user_id` (`uuid unique not
null`, foreign key with `ON DELETE RESTRICT` — a cascade would erase a
child's entire clinical record).

The caregiver row is created by an `AFTER INSERT` trigger on `auth.users`
(`0003`), not by application code: signup happens in the client against
Supabase Auth directly, so no application code is guaranteed to run. The
function is `SECURITY DEFINER` with an empty `search_path`, and is
idempotent because a failure there would fail the whole signup.

## Row-Level Security

Ownership chain:

```
auth.users → caregivers → children → observation_periods
                                   → observations → guided_observation_responses
                                                  → behavioural_events
                                   → reports
```

RLS is enabled on all 7 tables with **18 policies**, all scoped `TO
authenticated`. `anon` has no policy at all — and with RLS enabled, no
policy means no access, so unauthenticated denial is structural rather
than accidental.

| Table | SELECT | INSERT | UPDATE | DELETE |
| --- | --- | --- | --- | --- |
| `caregivers` | own | via trigger | own | — |
| `children` | ✓ | ✓ | ✓ | — |
| `observation_periods` | ✓ | ✓ | ✓ | — |
| `observations` | ✓ | ✓ | ✓ | — |
| `guided_observation_responses` | ✓ | ✓ | — | — |
| `behavioural_events` | ✓ | ✓ | — | — |
| `reports` | ✓ | ✓ | ✓ | — |

Design points:

- Every INSERT/UPDATE policy carries a `WITH CHECK` mirroring its
  `USING`, so a caregiver cannot attach rows to another caregiver's child.
- **No DELETE is granted or policied anywhere**, per the plan's
  requirement to preserve the source observation and its interpretation.
- Ownership helpers (`current_caregiver_id`, `owns_child`,
  `owns_observation`) live in a **non-exposed `private` schema** so
  PostgREST cannot publish them as RPC endpoints. They are
  `SECURITY DEFINER` so policy evaluation does not recurse into the
  tables being checked.
- Referential consistency between an observation's `child_id` and
  `observation_period_id` is enforced by a **composite foreign key**, not
  by RLS — RLS governs who may write, not whether the data is coherent,
  and it is bypassed by definer functions and service-role connections.

## Data API grants

"Automatically expose new tables" is off, so privileges are granted
explicitly (`0005`). Grants and RLS are independent layers and both are
required: a grant says which commands a role may attempt, a policy says
which rows it may touch.

`0006` exists because Supabase's default ACL for the `postgres` role
grants `Dxtm` (TRUNCATE, REFERENCES, TRIGGER, MAINTAIN) on every new
table in `public`. Migrations run as `postgres`, so `0001`'s
`CREATE TABLE`s silently handed those to `authenticated`. **TRUNCATE is
the significant one: RLS does not apply to it**, so an authenticated
session on a direct connection could have wiped all seven tables across
every caregiver. `0006` resets the privileges and clears the default ACL
so future migrations cannot reintroduce it.

## Verification

RLS was verified against the **live Data API with two real authenticated
users** — not by inspecting SQL, and not with `supabase db query`, which
uses a privileged connection that bypasses RLS.

Result: **43/44 assertions passed**; the single failure was a counting
bug in the test harness (it asserted a clean database while the harness
had been run twice), not a policy problem. Confirmed separately: every
row each user could see was owned by that user, with zero overlap.

Covered: sign-in for both users; the signup trigger creating exactly one
caregiver row each; user A creating a child, period, free-text
observation, guided observation, guided response, behavioural event and
report; A reading and updating their own rows with the original
observation text preserved; **B reading A's rows in all six categories →
0 rows**; **B updating A's rows → 0 rows affected**; **B inserting rows
referencing A's `child_id`/`observation_id`/`caregiver_id` → HTTP 403,
PostgreSQL code 42501**; B creating and reading its own data; and
**anon → HTTP 401 on all 7 tables** and on insert.

## Local setup

The Supabase CLI is pinned as a local dev dependency (`package.json`).

```bash
npx supabase migration list     # read-only: compare local and remote
npx supabase db push            # apply pending migrations (prompts for the DB password)
```

`supabase/config.toml` and `supabase/migrations/` are committed.
`supabase/.temp/` holds machine-local state including the pooler URL and
is gitignored, as is `node_modules/`. **No key material of any kind
belongs in the repository** — the publishable key is supplied at build
time, and the secret key is never used by the application.

## Outstanding

**The Flutter client is not yet connected to Supabase.** The database is
live and enforcing RLS, but the app still calls the FastAPI persistence
routes, which return `503` by design. Sign-up/login, child profiles,
observation periods, observation storage, guided-observation submission,
and history therefore do not function in the running app yet.
