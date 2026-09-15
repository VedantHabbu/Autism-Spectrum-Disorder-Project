"""Tests for the synthetic-narrative generation/validation logic.

Uses the template module directly — no dataset download required, so
these run fast and don't depend on network access.
"""

import pytest

pd = pytest.importorskip(
    "pandas", reason="backend/requirements-ml.txt not installed"
)
pytest.importorskip("sklearn", reason="backend/requirements-ml.txt not installed")

from app.nlp.negation import is_negated  # noqa: E402
from app.nlp.preprocessing import analyze  # noqa: E402
from ml.data.dataset_split import stratified_case_split  # noqa: E402
from ml.data.domain_mapping import (  # noqa: E402
    DOMAINS_WITHOUT_STRUCTURED_SIGNAL,
    QCHAT_ITEM_DOMAIN_MAP,
)
from ml.narratives.generate_narratives import render  # noqa: E402
from ml.narratives.templates import CONTEXT_PHRASES, NARRATIVE_TEMPLATES  # noqa: E402
from ml.narratives.validate_narratives import validate  # noqa: E402


def test_every_mapped_domain_has_templates_for_both_statuses() -> None:
    for item in QCHAT_ITEM_DOMAIN_MAP:
        assert item.domain in NARRATIVE_TEMPLATES
        assert "concern" in NARRATIVE_TEMPLATES[item.domain]
        assert "typical" in NARRATIVE_TEMPLATES[item.domain]
        assert len(NARRATIVE_TEMPLATES[item.domain]["concern"]) >= 2
        assert len(NARRATIVE_TEMPLATES[item.domain]["typical"]) >= 2


def test_domains_without_structured_signal_have_no_qchat_item() -> None:
    mapped_domains = {item.domain for item in QCHAT_ITEM_DOMAIN_MAP}
    for domain in DOMAINS_WITHOUT_STRUCTURED_SIGNAL:
        assert domain not in mapped_domains


def test_render_is_deterministic() -> None:
    first = render("eye_contact", "concern", variant_index=0, context="playing")
    second = render("eye_contact", "concern", variant_index=0, context="playing")
    assert first == second


def test_validate_accepts_correctly_generated_rows() -> None:
    rows = [
        {
            "case_no": 1,
            "domain": "eye_contact",
            "status": "concern",
            "context": "playing",
            "text": render("eye_contact", "concern", variant_index=0, context="playing"),
        },
        {
            "case_no": 2,
            "domain": "gestures",
            "status": "typical",
            "context": "outdoors",
            "text": render("gestures", "typical", variant_index=1, context="outdoors"),
        },
    ]
    df = pd.DataFrame(rows)
    assert validate(df) == []


def test_validate_rejects_status_mismatched_text() -> None:
    concern_text = render("eye_contact", "concern", variant_index=0, context="playing")
    df = pd.DataFrame(
        [
            {
                "case_no": 1,
                "domain": "eye_contact",
                # Mislabelled: this is a concern-template rendering tagged typical.
                "status": "typical",
                "context": "playing",
                "text": concern_text,
            }
        ]
    )
    errors = validate(df)
    assert len(errors) == 1
    assert "case_no=1" in errors[0]


def test_validate_rejects_fabricated_text() -> None:
    df = pd.DataFrame(
        [
            {
                "case_no": 1,
                "domain": "eye_contact",
                "status": "concern",
                "context": "playing",
                "text": "He has been diagnosed with autism.",
            }
        ]
    )
    errors = validate(df)
    assert len(errors) == 1


def test_context_phrases_never_change_domain_or_status() -> None:
    # All context fillers must be pure setting/time phrases, never assert a
    # behavioural claim of their own.
    forbidden_fragments = ["always", "never", "diagnos", "autis"]
    for phrase in CONTEXT_PHRASES.values():
        lowered = phrase.lower()
        for fragment in forbidden_fragments:
            assert fragment not in lowered


def test_context_phrases_introduce_no_negation() -> None:
    """A context filler must not carry a negation of its own.

    Regression test: the `with_unfamiliar_people` filler was once " around
    people he doesn't know", whose "doesn't" was picked up by sentence-level
    negation detection and flipped the extracted status of otherwise-positive
    narratives. Checked against the real detector rather than a word list, so
    any future phrasing the pipeline would read as negated also fails.
    """
    for key, phrase in CONTEXT_PHRASES.items():
        if not phrase.strip():
            continue
        doc = analyze(f"He plays with his toys{phrase}.")
        for sentence in doc.sents:
            assert not is_negated(sentence), (
                f"context phrase {key!r} ({phrase!r}) introduces a negation, which would "
                "invert the extracted status of narratives that use it"
            )


def test_context_phrases_use_no_gendered_pronoun() -> None:
    # The dataset's records carry a Sex field; a filler hardcoding one gender
    # would contradict the source record for roughly half of them.
    for key, phrase in CONTEXT_PHRASES.items():
        words = set(phrase.lower().replace(".", "").split())
        assert not (words & {"he", "she", "his", "her", "him", "hers"}), (
            f"context phrase {key!r} ({phrase!r}) hardcodes a gendered pronoun"
        )


def test_stratified_case_split_has_no_overlap_and_covers_all_cases() -> None:
    df = pd.DataFrame(
        {
            "Case_No": range(1, 101),
            "label": ([0] * 30) + ([1] * 70),
        }
    )
    train, val, test = stratified_case_split(df, label_col="label", random_state=0)

    assert train & val == set()
    assert train & test == set()
    assert val & test == set()
    assert train | val | test == set(range(1, 101))
