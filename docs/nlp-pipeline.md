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
2. **`negation.py`** — works at **clause level**, not sentence level.
   `signal_scope(trigger)` walks up from a matched trigger through its
   ancestors, collecting each ancestor and that ancestor's *direct*
   children (plus one extra level through `prep`/`aux` children, where
   negation and prepositional objects hang). Two rules make this precise:

   - The walk **stops at a coordinated clause that has its own subject**.
     That is the difference between "doesn't line up his toys **or flap
     his hands**" (no subject of its own → shares the negation → typical)
     and "doesn't line up his toys, **but he does flap his hands**" (its
     own subject → the earlier negation does not reach it → concern).
   - Collecting *direct children* rather than whole subtrees means a
     sibling clause's negation is never picked up.

   `polarity_of()` then reports two independent signals for that scope:
   whether it is **negated**, and whether a **concern marker** is present
   (a lexical difficulty/deficit word — "hard", "trouble", "rarely",
   "behind", "struggles").
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

   For a domain whose behaviour is *expected* (`typical_when_present`),
   status is **concern when exactly one of negation / concern-marker
   holds**. Both together cancel, which is what makes these read
   correctly:

   | Caregiver text | negated | marker | status |
   | --- | --- | --- | --- |
   | "doesn't make eye contact" | ✓ | — | concern |
   | "it's hard to get eye contact" | — | ✓ | concern |
   | "holds eye contact **without trouble**" | ✓ | ✓ | typical |
   | "has **no problem** making eye contact" | ✓ | ✓ | typical |
   | "makes eye contact easily" | — | — | typical |

   For a `concern_when_present` domain (e.g. repetitive behaviour) only
   negation matters — the trigger itself is the concern.

   Status is decided **per trigger occurrence** and aggregated per domain
   with **concern taking precedence**, so a sentence reporting one typical
   and one concerning behaviour surfaces the concern.

5. **Hedges** are split by what they actually qualify:
   - **Epistemic** ("not sure", "hard to tell", "maybe") — the caregiver
     is unsure *what they saw*. This outranks everything → `uncertain`.
   - **Frequency** ("sometimes", "occasionally") — the caregiver is sure,
     but it happens only some of the time. This **never erases a
     concern**: "sometimes he doesn't respond to his name" stays
     `concern`, while "sometimes she makes eye contact" (otherwise
     typical) softens to `uncertain`.

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

| Metric | Result | Before status-model rework | Before lexicon scoping | Original |
| --- | --- | --- | --- | --- |
| Domain recall | 93.7% | 93.7% | 89.3% | 89.3% |
| Domain + status accuracy | **92.0%** | 83.3% | 79.0% | 74.3% |
| No event extracted | 4.0% | 4.0% | 8.3% | 8.3% |

The latest column reflects the clause-scoped status model described
above (concern markers, polarity cancellation, clause-level negation,
and hedges split by what they qualify). Domain recall and the no-event
rate are unchanged by that work, as expected — it changes how status is
decided, not what matches.

The "Before status-model rework" column reflects two earlier lexicon
fixes: scoping overly broad
single-lemma triggers (a bare "engage"/"talk" no longer claims a domain
when the sentence is describing another domain's activity, e.g. "engages
in pretend play", "talks on a toy phone"), and filling phrase gaps that
missed legitimate wordings ("blank staring episodes", "doesn't react when
a family member is upset"). Multi-word phrases and multi-lemma groups are
never suppressed, so "engages with other kids during pretend play" still
matches social_interaction.

The "Original" column reflects a defect in the narrative templates, not in
the extractor: the `with_unfamiliar_people` context filler used to read
" around people he doesn't know", and that "doesn't" was picked up by
sentence-level negation detection, flipping the extracted status of
otherwise-positive narratives in 14.3% of rows. The filler is now
" around unfamiliar people" and carries no behavioural claim of its own
(regression test: `test_context_phrases_introduce_no_negation`).

Note that the context-filler fix never affected domain matching, only
status.

These numbers describe a template-generated dataset built from the same
kind of literal phrasing the lexicon targets, so they should not be read
as an estimate of real caregiver free-text accuracy — informal language,
typos, and paraphrase robustness are explicitly Week 9 work, not
attempted here.

The remaining gap between domain recall (93.7%) and domain + status
accuracy (92.0%) is no longer dominated by the status model. What is
still open:

1. **Subject attribution.** "He rarely looks me in the eye, even when I'm
   talking directly to him" still raises a `communication_language`
   event: the extractor cannot tell that the *parent*, not the child, is
   the one talking. This needs the trigger bound to its subject.
2. **Parser dependence.** Scoping is only as good as spaCy's parse. The
   small English model mis-tags "blank" as a verb in "doesn't have blank
   staring episodes"; the scope walk compensates by expanding through
   `aux` children, but other mis-parses will mis-scope.
3. **Robustness to real caregiver writing** — typos, informal language,
   and paraphrase are explicitly Week 9 work and are not attempted here.

## API endpoint

`POST /api/v1/analyze-observation` (implemented — see
`docs/api-contract.md`) runs this pipeline directly on submitted text and
returns the resulting events. It does not require persistence, so it
works end-to-end today even though Supabase/PostgreSQL integration is
still pending.
