"""Maps Q-CHAT-10 structured items to the mentor-plan behavioural taxonomy.

This mapping is a student engineering choice for building the structured
baseline and synthetic narratives; it is not a clinical interpretation. Two
taxonomy domains — repetitive_behaviour and restricted_interests — have no
corresponding Q-CHAT-10 item, so the structured dataset carries no signal
for them. That gap is intentional: it mirrors why the app's guided
observation feature must actively prompt caregivers for those domains
rather than relying on a short screening form alone.

Each entry describes:
- item: the Q-CHAT-10 column name (A1..A10), scored 1 when the response
  indicates more autistic traits and 0 otherwise, per the published
  Q-CHAT-10 instrument and this dataset's release notes.
- domain: the matching behavioural-taxonomy machine key
  (see docs/behavioural-taxonomy.md).
- question: the paraphrased caregiver-facing item wording.
- concern_when: whether the *concerning* status corresponds to the item
  being scored 1 or 0. Most items are worded so that 1 = concerning
  (typical developmental behaviour is absent/hard); this is recorded
  explicitly rather than assumed uniform, since it drives synthetic
  narrative polarity.
"""

from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class QChatItem:
    item: str
    domain: str
    question: str
    concern_when: int  # 1 -> item score 1 means concerning; 0 -> item score 0 means concerning


QCHAT_ITEM_DOMAIN_MAP: tuple[QChatItem, ...] = (
    QChatItem(
        item="A1",
        domain="response_to_name",
        question="Does your child look at you when you call his/her name?",
        concern_when=1,
    ),
    QChatItem(
        item="A2",
        domain="eye_contact",
        question="How easy is it for you to get eye contact with your child?",
        concern_when=1,
    ),
    QChatItem(
        item="A3",
        domain="gestures",
        question="Does your child point to indicate that they want something?",
        concern_when=1,
    ),
    QChatItem(
        item="A4",
        domain="joint_attention",
        question="Does your child point to share interest with you?",
        concern_when=1,
    ),
    QChatItem(
        item="A5",
        domain="play_pretend_play",
        question="Does your child pretend, e.g. care for dolls or talk on a toy phone?",
        concern_when=1,
    ),
    QChatItem(
        item="A6",
        domain="joint_attention",
        question="Does your child follow where you are looking?",
        concern_when=1,
    ),
    QChatItem(
        item="A7",
        domain="social_interaction",
        question="If someone in the family is visibly upset, does your child show signs of wanting to comfort them?",
        concern_when=1,
    ),
    QChatItem(
        item="A8",
        domain="communication_language",
        question="Would you describe your child's first words as typical?",
        concern_when=1,
    ),
    QChatItem(
        item="A9",
        domain="gestures",
        question="Does your child use simple gestures, e.g. wave goodbye?",
        concern_when=1,
    ),
    QChatItem(
        item="A10",
        domain="sensory_behaviour",
        question="Does your child stare at nothing with no apparent purpose?",
        concern_when=1,
    ),
)

DOMAINS_WITHOUT_STRUCTURED_SIGNAL = ("repetitive_behaviour", "restricted_interests")

STRUCTURED_FEATURE_COLUMNS = [item.item for item in QCHAT_ITEM_DOMAIN_MAP] + [
    "Age_Mons",
    "Sex",
    "Ethnicity",
    "Jaundice",
    "Family_mem_with_ASD",
]

TARGET_COLUMN = "Class/ASD Traits "
