# NLP Preprocessing, Negation, and Cue Extraction (Week 3)

## Approach

`backend/app/nlp/` implements the Week 3 scope items — "NLP preprocessing,
negation handling and initial behavioural cue extraction" — as a rule-based
pipeline: a spaCy (`en_core_web_sm`) pass for tokenization, lemmatization,
and dependency parsing, plus a hand-authored per-domain trigger lexicon
(`lexicon.py`). This is deliberately the *initial* extractor described in
the mentor plan, not the TF-IDF/sentence-embedding classifier planned for
Week 4/6 (not started, per project scope for this phase).

## Pipeline

1. **`preprocessing.py`** — loads the spaCy pipeline once per process,
   sentence-segments the observation text, and exposes a lemmatized,
   lowercased representation of each sentence. Negation words are
   preserved (never stripped) since `negation.py` depends on them.
2. **`negation.py`** — flags a sentence as negated if spaCy's dependency
   parse tags any token `neg` (e.g. the "n't" in "doesn't"), or a
   negation-cue word ("never", "without", "lack", ...) appears. This is a
   **sentence-level** signal: a compound sentence with one negated and one
   affirmed clause will mark both — a known limitation, left for Week 9
   robustness work rather than solved now.
3. **`lexicon.py`** — for each of the 10 behavioural-taxonomy domains,
   defines fixed trigger phrases and/or keyword groups (lemma sets that
   must all co-occur in a sentence). Each domain is tagged with whether
   its *unnegated* presence is reassuring (`typical_when_present`, e.g.
   eye contact) or itself a concern indicator (`concern_when_present`,
   e.g. repetitive behaviour).
4. **`cue_extraction.py`** — combines the above: for each sentence, for
   each domain whose lexicon matches, emits a `BehaviouralEvent` with
   `domain`, `status` (`typical` / `concern` / `uncertain`),
   `negation_detected`, `evidence` (the matched sentence, verbatim from
   the caregiver's text), and a heuristic `confidence` in `[0, 1]`.
   `status` becomes `uncertain` when a hedge cue ("sometimes", "not sure",
   "maybe", ...) is present, overriding the negation-derived status.

`confidence` is an engineering heuristic (base score + bonuses for an
exact phrase match / a structurally-detected negation, penalty for a
hedge), **not a calibrated or clinical probability** — consistent with
the project's safety boundary.

## "Not observed"

This free-text extractor never infers "not observed" — a domain simply
absent from the text produces no event for it, which is the free-text
analogue of "not observed". The explicit "not observed" choice (distinct
from "absent/reduced") is a guided-observation-only concept; see
`docs/api-contract.md`.

## Self-check against the synthetic dataset

`backend/ml/evaluate_cue_extraction.py` samples 300 rows from the Week 2/3
synthetic narrative dataset and checks whether the extractor recovers each
row's known (domain, status). Latest run:

| Metric | Result |
| --- | --- |
| Domain recall | 89.3% |
| Domain + status accuracy | 74.3% |
| No event extracted | 8.3% |

These numbers describe a template-generated dataset built from the same
kind of literal phrasing the lexicon targets, so they should not be read
as an estimate of real caregiver free-text accuracy — informal language,
typos, and paraphrase robustness are explicitly Week 9 work, not
attempted here. The gap between "domain recall" (89%) and "domain +
status accuracy" (74%) is mostly the sentence-level negation-scoping
limitation described above.

## API endpoint

`POST /api/v1/analyze-observation` (implemented — see
`docs/api-contract.md`) runs this pipeline directly on submitted text and
returns the resulting events. It does not require persistence, so it
works end-to-end today even though Supabase/PostgreSQL integration is
still pending.
