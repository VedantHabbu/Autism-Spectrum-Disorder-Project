"""Negation detection for one sentence.

Combines spaCy's dependency parse (tokens tagged `neg`, e.g. "n't"/"not"
attached to a verb) with a small negation-cue word list, so cues the
parser doesn't tag explicitly (e.g. "never", "rarely", "without") are
still caught. This is a sentence-level signal — a compound sentence with
one negated and one affirmed clause will mark both as negated, which is a
known limitation of this initial rule-based extractor (see README).
"""

from __future__ import annotations

from spacy.tokens import Span

from app.nlp.lexicon import NEGATION_CUES


def is_negated(sentence: Span) -> bool:
    if any(token.dep_ == "neg" for token in sentence):
        return True
    lemmas = {token.lemma_.lower() for token in sentence}
    tokens_lower = {token.text.lower() for token in sentence}
    return any(cue in lemmas or cue in tokens_lower for cue in NEGATION_CUES)
