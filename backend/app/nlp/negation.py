"""Negation and polarity analysis.

Two levels are available:

- `is_negated(sentence)` — the original sentence-wide check, kept for
  callers that only need "does this sentence contain a negation".
- `signal_scope(token)` / `polarity_of(token)` — clause-scoped analysis
  used by cue_extraction. This is what stops a negation in one clause from
  being applied to a different clause, and what lets a negated
  concern-marker ("without trouble") cancel back to typical.
"""

from __future__ import annotations

from dataclasses import dataclass

from spacy.tokens import Span, Token

from app.nlp.lexicon import CONCERN_MARKERS, NEGATION_CUES, NEGATORS

SUBJECT_DEPS = frozenset({"nsubj", "nsubjpass"})


def is_negated(sentence: Span) -> bool:
    """True if the sentence contains any negation at all (sentence-wide)."""
    if any(token.dep_ == "neg" for token in sentence):
        return True
    lemmas = {token.lemma_.lower() for token in sentence}
    tokens_lower = {token.text.lower() for token in sentence}
    return any(cue in lemmas or cue in tokens_lower for cue in NEGATION_CUES)


def signal_scope(trigger: Token) -> list[Token]:
    """Tokens whose negation/concern words apply to `trigger`.

    Walks from the trigger up through its ancestors, collecting each
    ancestor and that ancestor's *direct* children. Direct children (rather
    than whole subtrees) is the key: it picks up the words that attach to a
    governing verb — the "n't" in "doesn't respond", the "hard" in "it's
    hard to...", the "no" in "no problem" — without dragging in a sibling
    clause's own negation.

    The walk stops at a coordinated clause that has its own subject. That
    is the difference between:

        "doesn't line up his toys or flap his hands"
            -> "flap" has no subject of its own, so it shares the negation.
        "doesn't line up his toys, but he does flap his hands"
            -> "he does flap" is its own clause; the earlier "doesn't"
               does not reach it.
    """
    scope: dict[int, Token] = {}
    node = trigger

    while True:
        scope[node.i] = node
        for child in node.children:
            scope[child.i] = child
            # Expand one level through children that carry the clause's
            # own function words:
            #  - "prep": in "holds eye contact without trouble", "without"
            #    attaches to the verb but "trouble" hangs off it.
            #  - "aux"/"auxpass": negation usually attaches to the
            #    auxiliary ("does n't have"), and when the parser mis-reads
            #    the head — it tags "blank" as the root verb in "doesn't
            #    have blank staring episodes" — the whole "does n't" group
            #    ends up *below* the anchor instead of above it.
            if (
                child.dep_ in ("prep", "aux", "auxpass")
                or child.lemma_.lower() in NEGATORS
            ):
                for grandchild in child.children:
                    scope[grandchild.i] = grandchild

        if node.dep_ == "conj" and any(c.dep_ in SUBJECT_DEPS for c in node.children):
            break  # coordinated clause with its own subject: stop here
        # spaCy returns a fresh Token wrapper on every .head access, so ROOT
        # must be detected by index, never by `is` identity.
        if node.head.i == node.i:
            break
        node = node.head

    return list(scope.values())


@dataclass(frozen=True)
class Polarity:
    """Signals found in one trigger's scope."""

    negated: bool
    structurally_negated: bool  # negation the parser tagged, not just a word match
    concern_marker: bool

    @property
    def indicates_concern(self) -> bool:
        """For a behaviour that is *expected* (eye contact, responding to name).

        Concern when exactly one of "this is negated" / "a difficulty word
        is present" holds. Both together cancel: "no problem making eye
        contact", "without trouble", "never has trouble" all describe a
        child who is doing fine.
        """
        return self.negated != self.concern_marker


def polarity_of(trigger: Token) -> Polarity:
    scope = signal_scope(trigger)

    structurally_negated = any(token.dep_ == "neg" for token in scope)
    negated = structurally_negated or any(
        token.lemma_.lower() in NEGATORS or token.text.lower() in NEGATORS
        for token in scope
    )
    concern_marker = any(token.lemma_.lower() in CONCERN_MARKERS for token in scope)

    return Polarity(
        negated=negated,
        structurally_negated=structurally_negated,
        concern_marker=concern_marker,
    )
