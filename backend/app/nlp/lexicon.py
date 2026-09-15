"""Behavioural-domain trigger lexicon for rule-based cue extraction.

Each domain (docs/behavioural-taxonomy.md) has:
- `phrases`: fixed multi-word phrases matched as a substring of the
  sentence's lemmatized, lowercased token text (see preprocessing.py).
  Used for phrases that don't depend on a pronoun (e.g. "eye contact").
- `keyword_groups`: each group is a set of lemmas that must ALL appear
  somewhere in the sentence (in any order) for the group to match; the
  domain matches if ANY group matches. Used where phrasing varies with
  the subject/pronoun (e.g. "call his name" vs "call her name" vs "call
  their name" all lemmatize differently for the possessive, but all
  contain the lemmas {"call", "name"}).

Substring/lemma matching tolerates inflection (e.g. "pointed", "points",
"pointing" all lemmatize to "point") but is intentionally simple — this is
the Week 3 "initial" extractor, not the Week 4 embedding-based model.

`polarity` records what the *unnegated* presence of a match means:
- "typical_when_present": the trigger describes an expected/typical
  behaviour, so seeing it (no negation) is reassuring and negation
  indicates concern (e.g. "makes eye contact" vs "doesn't make eye
  contact").
- "concern_when_present": the trigger itself describes a possible concern
  indicator, so seeing it (no negation) is a concern and negation is
  reassuring (e.g. "lines up his toys" vs "doesn't line up his toys").
"""

from __future__ import annotations

from dataclasses import dataclass, field


@dataclass(frozen=True)
class DomainLexicon:
    domain: str
    polarity: str  # "typical_when_present" | "concern_when_present"
    phrases: tuple[str, ...] = field(default_factory=tuple)
    keyword_groups: tuple[tuple[str, ...], ...] = field(default_factory=tuple)
    # Phrases that suppress a match found *only* through a single-lemma
    # keyword group. A bare verb like "engage" or "talk" is ambiguous: it
    # names this domain's behaviour in "engages with other kids", but is
    # incidental in "engages in pretend play", where the sentence is
    # describing a different domain's activity. A multi-word phrase or a
    # multi-lemma group is specific enough to stand on its own and is never
    # suppressed — so "engages with other kids during pretend play" still
    # matches social_interaction. See cue_extraction._match_kind.
    exclusions: tuple[str, ...] = field(default_factory=tuple)


DOMAIN_LEXICON: tuple[DomainLexicon, ...] = (
    DomainLexicon(
        domain="response_to_name",
        polarity="typical_when_present",
        keyword_groups=(
            ("call", "name"),
            ("respond", "name"),
            ("answer", "name"),
            ("react", "name"),
            ("turn", "name"),
        ),
    ),
    DomainLexicon(
        domain="eye_contact",
        polarity="typical_when_present",
        phrases=("eye contact",),
        keyword_groups=(("look", "eye"),),
    ),
    DomainLexicon(
        domain="joint_attention",
        polarity="typical_when_present",
        phrases=("joint attention", "share interest", "point out"),
        keyword_groups=(
            ("point", "share"),
            ("follow", "gaze"),
            ("follow", "look"),
        ),
    ),
    DomainLexicon(
        domain="gestures",
        polarity="typical_when_present",
        phrases=("wave goodbye",),
        keyword_groups=(
            ("gesture",),
            ("point",),
            ("nod", "head"),
            ("shake", "head"),
        ),
    ),
    DomainLexicon(
        domain="social_interaction",
        polarity="typical_when_present",
        phrases=("shared enjoyment",),
        keyword_groups=(
            ("comfort",),
            ("smile",),
            ("interact",),
            ("engage",),
            # Specific enough to survive the pretend-play exclusion below.
            ("engage", "with"),
            ("interact", "with"),
            # "doesn't react when a family member is upset" — reacting to
            # someone else's distress is a social-interaction observation.
            ("react", "upset"),
        ),
        exclusions=("pretend play", "imaginative play"),
    ),
    DomainLexicon(
        domain="communication_language",
        polarity="typical_when_present",
        phrases=("first word", "language development"),
        keyword_groups=(
            ("use", "word"),
            ("talk",),
            ("speak",),
            ("babble",),
        ),
        # "talks on a toy phone" is pretend play, not a language observation.
        # Bare "talk"/"speak" are kept so ordinary phrasings like "he doesn't
        # talk yet" still match.
        exclusions=("toy phone",),
    ),
    DomainLexicon(
        domain="play_pretend_play",
        polarity="typical_when_present",
        phrases=("pretend play", "imaginative play", "toy phone"),
        keyword_groups=(("pretend",), ("care", "doll")),
    ),
    DomainLexicon(
        domain="repetitive_behaviour",
        polarity="concern_when_present",
        phrases=(
            "spin in circle",
            "rock back and forth",
            "over and over",
        ),
        keyword_groups=(
            ("line", "up", "toy"),
            ("flap", "hand"),
            ("repetitive",),
        ),
    ),
    DomainLexicon(
        domain="restricted_interests",
        polarity="concern_when_present",
        phrases=("only interested in", "narrow interest", "only play with"),
        keyword_groups=(("obsess",), ("fixate",)),
    ),
    DomainLexicon(
        domain="sensory_behaviour",
        polarity="concern_when_present",
        phrases=(
            "stare at nothing",
            # spaCy's small English model inconsistently lemmatizes
            # "stares"/"staring" as the noun "star" depending on context;
            # both variants are matched to compensate.
            "star at nothing",
            "stare blankly",
            "star blankly",
            # "blank staring episodes" — same behaviour, different word order,
            # and "staring" here lemmatizes to the noun "star" (see above).
            "blank stare",
            "blank star",
            "sensitive to loud noise",
            "sensitive to texture",
            "zone out",
        ),
        keyword_groups=(("cover", "ear"),),
    ),
)

HEDGE_CUES: tuple[str, ...] = (
    "sometimes",
    "occasionally",
    "not sure",
    "unsure",
    "hard to tell",
    "maybe",
    "possibly",
    "i think",
    "seems like",
    "not certain",
)

NEGATION_CUES: tuple[str, ...] = (
    "not",
    "n't",
    "no",
    "never",
    "hardly",
    "rarely",
    "barely",
    "without",
    "lack",
    "lacks",
    "lacking",
)
