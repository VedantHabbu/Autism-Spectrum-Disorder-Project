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


SPACY_MODEL = "en_core_web_sm"

MODEL_MISSING_MESSAGE = (
    f"The spaCy model '{SPACY_MODEL}' is not installed, but it is a required "
    "dependency of this service. Install it with:\n"
    "    pip install -r requirements.txt\n"
    f"or directly:  python -m spacy download {SPACY_MODEL}"
)


@lru_cache(maxsize=1)
def get_pipeline() -> Language:
    """Load the spaCy pipeline, or fail with an actionable message.

    Called during application startup (app/main.py) so a missing model
    stops the service immediately instead of letting it start and then
    return a 500 on the first /analyze-observation request.
    """
    try:
        return spacy.load(SPACY_MODEL)
    except OSError as exc:  # model not installed
        raise RuntimeError(MODEL_MISSING_MESSAGE) from exc


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
