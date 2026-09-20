"""Initial rule-based behavioural cue extraction (Week 3).

extract_events(text) maps free-text caregiver observations to structured
behavioural events: domain, status, negation_detected, evidence phrase,
and a heuristic confidence score. This is a lexicon + spaCy-dependency-
parse rule engine, not the TF-IDF/embedding classifier planned for
Week 4/6, and confidence is not a calibrated or clinical probability.

Status is decided per *trigger occurrence*, using the clause that trigger
belongs to (see negation.signal_scope), then aggregated per domain with
concern taking precedence — a sentence that reports one typical and one
concerning behaviour should surface the concern rather than average it
away.

"not_observed" is not inferred here — free text that never mentions a
domain simply produces no event for it, which is the free-text analogue
of "not observed". The explicit "not observed" choice is a guided-
observation-only concept (see docs/api-contract.md).
"""

from __future__ import annotations

from dataclasses import dataclass

from spacy.tokens import Span, Token

from app.nlp.lexicon import (
    DOMAIN_LEXICON,
    EPISTEMIC_HEDGES,
    FREQUENCY_QUALIFIERS,
    DomainLexicon,
)
from app.nlp.negation import polarity_of
from app.nlp.preprocessing import lemmatized_text

STATUS_TYPICAL = "typical"
STATUS_CONCERN = "concern"
STATUS_UNCERTAIN = "uncertain"

MATCH_PHRASE = "phrase"
MATCH_SPECIFIC = "specific"
MATCH_BROAD = "broad"

BASE_CONFIDENCE = 0.55
PHRASE_MATCH_BONUS = 0.20
STRUCTURAL_NEGATION_BONUS = 0.15
HEDGE_PENALTY = 0.15
MIN_CONFIDENCE = 0.05
MAX_CONFIDENCE = 0.98

# Ranked so that a concern in any clause wins over a typical reading.
_STATUS_PRECEDENCE = {STATUS_CONCERN: 2, STATUS_UNCERTAIN: 1, STATUS_TYPICAL: 0}


@dataclass(frozen=True)
class BehaviouralEvent:
    domain: str
    status: str
    negation_detected: bool
    evidence: str
    confidence: float


def _content_tokens(sentence: Span) -> list[Token]:
    return [token for token in sentence if not token.is_punct]


def _phrase_anchors(tokens: list[Token], phrase: str) -> list[Token]:
    """Tokens starting each occurrence of a lemma phrase."""
    words = phrase.split()
    lemmas = [token.lemma_.lower() for token in tokens]
    anchors = []
    for start in range(len(lemmas) - len(words) + 1):
        if lemmas[start : start + len(words)] == words:
            anchors.append(tokens[start])
    return anchors


def _group_anchors(tokens: list[Token], group: tuple[str, ...]) -> list[Token]:
    """Anchors for a keyword group, if every keyword is present.

    Anchored on the group's first keyword, which is the semantic head in
    every entry (the verb in ("react", "upset"), ("flap", "hand"), ...).
    """
    lemmas = {token.lemma_.lower() for token in tokens}
    if not all(keyword in lemmas for keyword in group):
        return []
    return [token for token in tokens if token.lemma_.lower() == group[0]]


def _matches(
    lexicon: DomainLexicon, tokens: list[Token], lemma_text: str
) -> tuple[str, list[Token]] | None:
    """Best match kind for this domain plus the tokens that triggered it."""
    phrase_anchors: list[Token] = []
    for phrase in lexicon.phrases:
        phrase_anchors.extend(_phrase_anchors(tokens, phrase))
    if phrase_anchors:
        return MATCH_PHRASE, phrase_anchors

    specific_anchors: list[Token] = []
    broad_anchors: list[Token] = []
    for group in lexicon.keyword_groups:
        anchors = _group_anchors(tokens, group)
        if not anchors:
            continue
        (specific_anchors if len(group) > 1 else broad_anchors).extend(anchors)

    if specific_anchors:
        return MATCH_SPECIFIC, specific_anchors
    if broad_anchors:
        return MATCH_BROAD, broad_anchors
    return None


def _is_suppressed(lexicon: DomainLexicon, kind: str, lemma_text: str) -> bool:
    return kind == MATCH_BROAD and any(excl in lemma_text for excl in lexicon.exclusions)


def _has_epistemic_hedge(lemma_text: str) -> bool:
    return any(cue in lemma_text for cue in EPISTEMIC_HEDGES)


def _has_frequency_qualifier(lemma_text: str) -> bool:
    return any(cue in lemma_text for cue in FREQUENCY_QUALIFIERS)


def _score(structurally_negated: bool, phrase_match: bool, hedged: bool) -> float:
    score = BASE_CONFIDENCE
    if phrase_match:
        score += PHRASE_MATCH_BONUS
    if structurally_negated:
        score += STRUCTURAL_NEGATION_BONUS
    if hedged:
        score -= HEDGE_PENALTY
    return max(MIN_CONFIDENCE, min(MAX_CONFIDENCE, round(score, 2)))


def _status_for_anchor(lexicon: DomainLexicon, anchor: Token) -> tuple[str, bool, bool]:
    """(status, negation_detected, structurally_negated) for one trigger."""
    polarity = polarity_of(anchor)

    if lexicon.polarity == "typical_when_present":
        # The behaviour is expected, so concern means it is absent or hard.
        status = STATUS_CONCERN if polarity.indicates_concern else STATUS_TYPICAL
    else:
        # The behaviour is itself a possible concern indicator; only whether
        # it is denied matters.
        status = STATUS_TYPICAL if polarity.negated else STATUS_CONCERN

    return status, polarity.negated, polarity.structurally_negated


def _events_for_sentence(sentence: Span) -> list[BehaviouralEvent]:
    tokens = _content_tokens(sentence)
    lemma_text = lemmatized_text(sentence)
    evidence = sentence.text.strip()

    epistemic = _has_epistemic_hedge(lemma_text)
    frequency = _has_frequency_qualifier(lemma_text)

    events: list[BehaviouralEvent] = []
    for lexicon in DOMAIN_LEXICON:
        match = _matches(lexicon, tokens, lemma_text)
        if match is None:
            continue
        kind, anchors = match
        if _is_suppressed(lexicon, kind, lemma_text):
            continue

        best: tuple[str, bool, bool] | None = None
        for anchor in anchors:
            candidate = _status_for_anchor(lexicon, anchor)
            if best is None or _STATUS_PRECEDENCE[candidate[0]] > _STATUS_PRECEDENCE[best[0]]:
                best = candidate
        if best is None:  # pragma: no cover - anchors is never empty here
            continue

        status, negated, structurally_negated = best

        if epistemic:
            # The caregiver is unsure what they saw; that outranks everything.
            status = STATUS_UNCERTAIN
        elif frequency and status == STATUS_TYPICAL:
            # "Sometimes she makes eye contact" — happens, but inconsistently.
            # A frequency qualifier never downgrades a concern.
            status = STATUS_UNCERTAIN

        events.append(
            BehaviouralEvent(
                domain=lexicon.domain,
                status=status,
                negation_detected=negated,
                evidence=evidence,
                confidence=_score(
                    structurally_negated,
                    kind == MATCH_PHRASE,
                    epistemic or frequency,
                ),
            )
        )
    return events


def extract_events(text: str) -> list[BehaviouralEvent]:
    if not text or not text.strip():
        return []
    from app.nlp.preprocessing import analyze

    doc = analyze(text)
    events: list[BehaviouralEvent] = []
    for sentence in doc.sents:
        events.extend(_events_for_sentence(sentence))
    return events
