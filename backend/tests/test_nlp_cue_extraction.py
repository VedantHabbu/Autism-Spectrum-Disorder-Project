from app.nlp.cue_extraction import extract_events
from app.nlp.negation import is_negated
from app.nlp.preprocessing import analyze


def test_prototype_1_example_matches_documented_contract() -> None:
    events = extract_events("He doesn't look towards me when I call his name.")

    assert len(events) == 1
    event = events[0]
    assert event.domain == "response_to_name"
    assert event.status == "concern"
    assert event.negation_detected is True
    assert "doesn't look towards me" in event.evidence
    assert 0.0 <= event.confidence <= 1.0


def test_typical_when_present_domain_without_negation_is_typical() -> None:
    events = extract_events("She makes eye contact with me easily.")

    assert len(events) == 1
    assert events[0].domain == "eye_contact"
    assert events[0].status == "typical"
    assert events[0].negation_detected is False


def test_concern_when_present_domain_without_negation_is_concern() -> None:
    events = extract_events("He lines up his toys for long stretches.")

    assert len(events) == 1
    assert events[0].domain == "repetitive_behaviour"
    assert events[0].status == "concern"
    assert events[0].negation_detected is False


def test_concern_when_present_domain_negated_is_typical() -> None:
    events = extract_events("He doesn't line up his toys or flap his hands.")

    assert len(events) == 1
    assert events[0].domain == "repetitive_behaviour"
    assert events[0].status == "typical"
    assert events[0].negation_detected is True


def test_hedge_cue_marks_status_uncertain() -> None:
    events = extract_events("Sometimes she makes eye contact with me.")

    assert len(events) == 1
    assert events[0].status == "uncertain"


def test_unrelated_text_produces_no_events() -> None:
    assert extract_events("The weather was nice today.") == []


def test_empty_text_produces_no_events() -> None:
    assert extract_events("") == []
    assert extract_events("   ") == []


def test_multiple_domains_in_one_sentence_each_produce_an_event() -> None:
    events = extract_events("She makes eye contact with me easily and waves goodbye when we leave.")

    domains = {event.domain for event in events}
    assert domains == {"eye_contact", "gestures"}


def test_confidence_is_bounded() -> None:
    for text in (
        "He doesn't look towards me when I call his name.",
        "She makes eye contact with me easily.",
        "Sometimes she makes eye contact with me.",
    ):
        for event in extract_events(text):
            assert 0.0 <= event.confidence <= 1.0


def _domains(text: str) -> set[str]:
    return {event.domain for event in extract_events(text)}


# --- Overly broad single-word triggers (regression) -------------------------
# A bare verb that is incidental to another domain's activity must not claim
# a domain of its own.


def test_engage_in_pretend_play_does_not_trigger_social_interaction() -> None:
    domains = _domains("My toddler doesn't engage in pretend play at all.")

    assert "play_pretend_play" in domains
    assert "social_interaction" not in domains


def test_engage_in_imaginative_play_does_not_trigger_social_interaction() -> None:
    # Same rule as pretend play, different wording.
    domains = _domains("My toddler engages in imaginative play regularly.")

    assert "play_pretend_play" in domains
    assert "social_interaction" not in domains


def test_talk_on_a_toy_phone_does_not_trigger_communication_language() -> None:
    domains = _domains("She pretends to talk on a toy phone and cares for her dolls.")

    assert "play_pretend_play" in domains
    assert "communication_language" not in domains


def test_bare_talk_still_matches_ordinary_language_observations() -> None:
    # Guard against over-suppression: the exclusion is scoped to toy-phone
    # pretend play, not to the word "talk" in general.
    assert "communication_language" in _domains("He doesn't talk yet.")


def test_engage_with_people_still_matches_even_alongside_pretend_play() -> None:
    # "engage with" is specific enough to survive the pretend-play exclusion.
    assert "social_interaction" in _domains("He engages with other kids during pretend play.")


# --- Lexicon/phrase gaps (regression) --------------------------------------


def test_blank_staring_wording_is_recognized() -> None:
    assert "sensory_behaviour" in _domains("She doesn't have blank staring episodes.")


def test_existing_staring_wording_still_recognized() -> None:
    assert "sensory_behaviour" in _domains("He stares at nothing for long periods.")


def test_reacting_to_an_upset_family_member_is_social_interaction() -> None:
    assert "social_interaction" in _domains(
        "My toddler doesn't react when a family member is upset."
    )


def test_is_negated_true_for_contraction() -> None:
    doc = analyze("He doesn't look at me.")
    sentence = next(doc.sents)
    assert is_negated(sentence) is True


def test_is_negated_false_for_affirmative_sentence() -> None:
    doc = analyze("He looks at me.")
    sentence = next(doc.sents)
    assert is_negated(sentence) is False
