"""NLP text preprocessing: normalization, tokenization, sentence splitting.

Loads spaCy's small English pipeline once per process. Negation words
(e.g. "not", "n't", "never") are deliberately preserved through
normalization — they are the input to negation.py, not noise to strip.
"""

from __future__ import annotations

from functools import lru_cache

import spacy
from spacy.language import Language
from spacy.tokens import Doc, Span


@lru_cache(maxsize=1)
def get_pipeline() -> Language:
    return spacy.load("en_core_web_sm")


def analyze(text: str) -> Doc:
    """Tokenize, lemmatize, and sentence-segment observation text."""
    nlp = get_pipeline()
    return nlp(text)


def lemmatized_text(span: Span) -> str:
    """Lowercased, space-joined lemmas for one sentence, punctuation dropped.

    Used for simple lexicon substring/keyword matching (lexicon.py); this
    intentionally tolerates inflection (e.g. "pointed"/"points"/"pointing"
    all normalize to "point").
    """
    return " ".join(token.lemma_.lower() for token in span if not token.is_punct)
