"""Shared enums used across observation-related schemas."""

from __future__ import annotations

from enum import Enum


class ObservationContext(str, Enum):
    """Optional observation context (docs/requirements.md feature list)."""

    PLAYING = "playing"
    EATING = "eating"
    SOCIAL_INTERACTION = "social_interaction"
    OUTDOORS = "outdoors"
    WITH_FAMILY = "with_family"
    WITH_UNFAMILIAR_PEOPLE = "with_unfamiliar_people"
    OTHER = "other"


class BehaviouralDomain(str, Enum):
    """Machine keys from docs/behavioural-taxonomy.md."""

    RESPONSE_TO_NAME = "response_to_name"
    EYE_CONTACT = "eye_contact"
    JOINT_ATTENTION = "joint_attention"
    GESTURES = "gestures"
    SOCIAL_INTERACTION = "social_interaction"
    COMMUNICATION_LANGUAGE = "communication_language"
    PLAY_PRETEND_PLAY = "play_pretend_play"
    REPETITIVE_BEHAVIOUR = "repetitive_behaviour"
    RESTRICTED_INTERESTS = "restricted_interests"
    SENSORY_BEHAVIOUR = "sensory_behaviour"


class GuidedObservationChoice(str, Enum):
    """The four guided-observation response options (docs/requirements.md)."""

    OBSERVED_NORMALLY = "observed_normally"
    OBSERVED_WITH_CONCERN = "observed_with_concern"
    NOT_OBSERVED = "not_observed"
    NOT_SURE = "not_sure"
