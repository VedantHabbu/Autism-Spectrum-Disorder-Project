"""Initial rule-based behavioural cue extraction (Week 3).

extract_events(text) maps free-text caregiver observations to structured
behavioural events: domain, status, negation_detected, evidence phrase,
and a heuristic confidence score. This is a lexicon + spaCy-dependency-
parse rule engine, not the TF-IDF/embedding classifier planned for
Week 4/6, and confidence is not a calibrated or clinical probability.

"not_observed" is not inferred here — free text that never mentions a
domain simply produces no event for it, which is the free-text analogue
of "not observed". The explicit "not observed" choice is a guided-
observation-only concept (see docs/api-contract.md).
"""

from __future__ import annotations

from dataclasses import dataclass

from spacy.tokens import Span

from app.nlp.lexicon import DOMAIN_LEXICON, HEDGE_CUES, DomainLexicon
from app.nlp.negation import is_negated
from app.nlp.preprocessing import analyze, lemmatized_text

STATUS_TYPICAL = "typical"
STATUS_CONCERN = "concern"
STATUS_UNCERTAIN = "uncertain"

BASE_CONFIDENCE = 0.55
PHRASE_MATCH_BONUS = 0.20
STRUCTURAL_NEGATION_BONUS = 0.15
HEDGE_PENALTY = 0.15
MIN_CONFIDENCE = 0.05
MAX_CONFIDENCE = 0.98


@dataclass(frozen=True)
class BehaviouralEvent:
    domain: str
    status: str
    negation_detected: bool
    evidence: str
    confidence: float


def _matches(lexicon: DomainLexicon, lemma_text: str, lemma_set: set[str]) -> bool:
    if any(phrase in lemma_text for phrase in lexicon.phrases):
        return True
    return any(
        all(keyword in lemma_set for keyword in group) for group in lexicon.keyword_groups
    )


def _is_phrase_match(lexicon: DomainLexicon, lemma_text: str) -> bool:
    return any(phrase in lemma_text for phrase in lexicon.phrases)


def _has_hedge(lemma_text: str) -> bool:
    return any(cue in lemma_text for cue in HEDGE_CUES)


def _score(negated_structurally: bool, phrase_match: bool, hedged: bool) -> float:
    score = BASE_CONFIDENCE
    if phrase_match:
        score += PHRASE_MATCH_BONUS
    if negated_structurally:
        score += STRUCTURAL_NEGATION_BONUS
    if hedged:
        score -= HEDGE_PENALTY
    return max(MIN_CONFIDENCE, min(MAX_CONFIDENCE, round(score, 2)))


def _events_for_sentence(sentence: Span) -> list[BehaviouralEvent]:
    lemma_text = lemmatized_text(sentence)
    lemma_set = set(lemma_text.split())
    negated = is_negated(sentence)
    negated_structurally = any(token.dep_ == "neg" for token in sentence)
    hedged = _has_hedge(lemma_text)
    evidence = sentence.text.strip()

    events: list[BehaviouralEvent] = []
    for lexicon in DOMAIN_LEXICON:
        if not _matches(lexicon, lemma_text, lemma_set):
            continue

        if lexicon.polarity == "typical_when_present":
            status = STATUS_CONCERN if negated else STATUS_TYPICAL
        else:
            status = STATUS_TYPICAL if negated else STATUS_CONCERN
        if hedged:
            status = STATUS_UNCERTAIN

        events.append(
            BehaviouralEvent(
                domain=lexicon.domain,
                status=status,
                negation_detected=negated,
                evidence=evidence,
                confidence=_score(
                    negated_structurally, _is_phrase_match(lexicon, lemma_text), hedged
                ),
            )
        )
    return events


def extract_events(text: str) -> list[BehaviouralEvent]:
    if not text or not text.strip():
        return []
    doc = analyze(text)
    events: list[BehaviouralEvent] = []
    for sentence in doc.sents:
        events.extend(_events_for_sentence(sentence))
    return events
