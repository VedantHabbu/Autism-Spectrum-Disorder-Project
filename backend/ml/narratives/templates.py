"""Caregiver-style narrative templates, keyed by (domain, status).

Each template renders a single free-text observation sentence for one
behavioural domain. Templates are deliberately literal paraphrases of the
Q-CHAT-10 item they are derived from (see domain_mapping.py) so that a
generated narrative's status (concern/typical) is fully determined by —
and traceable back to — the source record's own item score. No template
asserts anything the corresponding item score does not support.

Multiple phrasings per (domain, status) exist to give the eventual NLP
model paraphrase variety (Week 3 finalisation), not to introduce new
clinical content.
"""

from __future__ import annotations

# {context} is optionally filled from CONTEXT_PHRASES; it varies setting,
# never the underlying behavioural claim.
NARRATIVE_TEMPLATES: dict[str, dict[str, list[str]]] = {
    "response_to_name": {
        "concern": [
            "He doesn't look towards me when I call his name{context}.",
            "She doesn't respond when we say her name{context}, even if we say it a few times.",
            "I've noticed my toddler doesn't turn around when called by name{context}.",
        ],
        "typical": [
            "He looks over right away when I call his name{context}.",
            "She turns to me as soon as I say her name{context}.",
            "My toddler responds to his name normally{context}.",
        ],
    },
    "eye_contact": {
        "concern": [
            "It's hard to get her to make eye contact with me{context}.",
            "He rarely looks me in the eye{context}, even when I'm talking directly to him.",
            "Getting eye contact from my toddler{context} is difficult most of the time.",
        ],
        "typical": [
            "She makes eye contact with me easily{context}.",
            "He looks at me and holds eye contact{context} without trouble.",
            "My toddler makes eye contact naturally{context}.",
        ],
    },
    "gestures": {
        "concern": [
            "He doesn't point at things he wants{context}, he just gets upset instead.",
            "She doesn't wave goodbye or use gestures like that{context}.",
            "My toddler doesn't use simple gestures{context}, like pointing or waving.",
        ],
        "typical": [
            "He points at what he wants{context} so I know what to get him.",
            "She waves goodbye on her own{context} now.",
            "My toddler uses gestures like pointing and waving{context} normally.",
        ],
    },
    "joint_attention": {
        "concern": [
            "He doesn't point things out to share them with me{context}, like an interesting sight.",
            "She doesn't seem to follow where I'm looking{context}.",
            "My toddler doesn't try to share interesting things with me{context} the way other kids do.",
        ],
        "typical": [
            "He points things out just to show me{context}, like something interesting he sees.",
            "She follows my gaze{context} and looks at what I'm looking at.",
            "My toddler shares interesting things with me{context} by pointing them out.",
        ],
    },
    "play_pretend_play": {
        "concern": [
            "He doesn't do any pretend play{context}, like feeding a doll or talking on a toy phone.",
            "She doesn't pretend with her toys{context}, she mostly just lines them up.",
            "My toddler doesn't engage in pretend play{context} at all.",
        ],
        "typical": [
            "He loves pretend play{context}, like feeding his stuffed animals.",
            "She pretends to talk on a toy phone{context} and cares for her dolls.",
            "My toddler engages in imaginative play{context} regularly.",
        ],
    },
    "social_interaction": {
        "concern": [
            "When someone in the family is upset{context}, he doesn't seem to notice or want to comfort them.",
            "She doesn't show signs of wanting to comfort us{context} when we're visibly upset.",
            "My toddler doesn't react when a family member is upset{context}.",
        ],
        "typical": [
            "When I'm visibly upset{context}, he comes over to comfort me.",
            "She notices when someone is upset{context} and tries to comfort them.",
            "My toddler shows concern and tries to comfort us{context} when we're upset.",
        ],
    },
    "communication_language": {
        "concern": [
            "His first words weren't really typical{context}; his language has been slow to develop.",
            "She doesn't use words the way other toddlers her age do{context}.",
            "My toddler's language development seems behind{context} compared to other kids his age.",
        ],
        "typical": [
            "His first words came in typically{context} and his language has been developing well.",
            "She talks and uses words the way I'd expect for her age{context}.",
            "My toddler's language development is on track{context}.",
        ],
    },
    "sensory_behaviour": {
        "concern": [
            "He sometimes stares off at nothing with no clear reason{context}.",
            "She has episodes of staring blankly{context} that don't seem tied to anything.",
            "My toddler zones out and stares at nothing{context} sometimes.",
        ],
        "typical": [
            "He doesn't really stare off at nothing{context}; he stays engaged with what's happening.",
            "She doesn't have blank staring episodes{context}.",
            "My toddler stays engaged and doesn't zone out{context}.",
        ],
    },
}

CONTEXT_PHRASES: dict[str, str] = {
    "playing": " while we're playing",
    "eating": " at mealtimes",
    "social_interaction": " when other people are around",
    "outdoors": " when we're outside",
    "with_family": " around the family",
    # Must not contain a negation word: this filler varies the setting only,
    # and a "doesn't"/"never" here would be picked up by negation detection
    # and flip the extracted status of an otherwise-positive sentence.
    # Enforced by test_context_phrases_introduce_no_negation.
    "with_unfamiliar_people": " around unfamiliar people",
    "other": "",
}
