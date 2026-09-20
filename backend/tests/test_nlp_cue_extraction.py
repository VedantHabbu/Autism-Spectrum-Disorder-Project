from app.nlp.cue_extraction import extract_events
from app.nlp.negation import is_negated, signal_scope
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


def _status(text: str, domain: str) -> str:
    events = [event for event in extract_events(text) if event.domain == domain]
    return events[0].status if events else "NO EVENT"


# --- Status model: concern without a negation word (regression) -------------
# Previously status was decided purely by "is there a negation", so concern
# expressed lexically read as typical.


def test_difficulty_phrasing_is_a_concern_without_any_negation() -> None:
    assert _status("It's hard to get her to make eye contact", "eye_contact") == "concern"


def test_developmental_delay_phrasing_is_a_concern() -> None:
    assert _status("His language development seems behind.", "communication_language") == "concern"


def test_negative_frequency_is_a_concern() -> None:
    assert _status("He rarely looks me in the eye.", "eye_contact") == "concern"


# --- Status model: a negated difficulty cancels back to typical -------------
# "without"/"no"/"never" used to invert an unrelated positive statement.


def test_without_trouble_is_typical() -> None:
    assert _status("holds eye contact without trouble", "eye_contact") == "typical"


def test_no_problem_is_typical() -> None:
    assert _status("He has no problem making eye contact.", "eye_contact") == "typical"


def test_never_has_trouble_is_typical() -> None:
    assert (
        _status("He never has trouble responding when I call his name.", "response_to_name")
        == "typical"
    )


# --- Clause scoping (regression) -------------------------------------------


def test_negation_does_not_reach_a_later_clause_with_its_own_subject() -> None:
    # "he does flap" is its own clause, so the earlier "doesn't" must not
    # make the flapping read as typical.
    assert (
        _status("doesn't line up his toys, but he does flap his hands", "repetitive_behaviour")
        == "concern"
    )


def test_negation_is_shared_by_a_coordinated_verb_without_its_own_subject() -> None:
    # "or flap his hands" has no subject of its own, so it stays inside the
    # scope of "doesn't".
    assert (
        _status("He doesn't line up his toys or flap his hands.", "repetitive_behaviour")
        == "typical"
    )


def test_negation_attached_under_an_auxiliary_is_still_found() -> None:
    # The parser reads "blank" as the root verb here, pushing "does n't"
    # below the anchor rather than above it.
    assert (
        _status("She doesn't have blank staring episodes.", "sensory_behaviour") == "typical"
    )


# --- Hedges (regression) ----------------------------------------------------


def test_frequency_qualifier_does_not_erase_a_concern() -> None:
    assert (
        _status("Sometimes he doesn't respond to his name", "response_to_name") == "concern"
    )


def test_frequency_qualifier_still_softens_an_otherwise_typical_observation() -> None:
    assert _status("Sometimes she makes eye contact with me.", "eye_contact") == "uncertain"


def test_epistemic_hedge_marks_uncertain() -> None:
    assert _status("I'm not sure whether he makes eye contact.", "eye_contact") == "uncertain"


# --- Vocabulary regressions -------------------------------------------------


def test_showing_concern_for_others_is_not_itself_a_concern() -> None:
    # "concern" as a caring behaviour must not be read as a deficit marker.
    assert (
        _status("My toddler shows concern and tries to comfort us.", "social_interaction")
        == "typical"
    )


def test_sharing_interesting_things_is_joint_attention() -> None:
    assert (
        _status("My toddler doesn't try to share interesting things with me.", "joint_attention")
        == "concern"
    )


def test_signal_scope_terminates_at_root() -> None:
    # Guards the walk's ROOT check: spaCy returns a fresh Token wrapper on
    # every .head access, so an identity comparison never terminates.
    doc = analyze("He makes eye contact.")
    root = [token for token in doc if token.dep_ == "ROOT"][0]
    scope = signal_scope(root)
    assert root.i in {token.i for token in scope}


def test_is_negated_true_for_contraction() -> None:
    doc = analyze("He doesn't look at me.")
    sentence = next(doc.sents)
    assert is_negated(sentence) is True


def test_is_negated_false_for_affirmative_sentence() -> None:
    doc = analyze("He looks at me.")
    sentence = next(doc.sents)
    assert is_negated(sentence) is False
