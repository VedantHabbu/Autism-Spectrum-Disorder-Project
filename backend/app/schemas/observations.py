"""Future observation API schemas; routes are not implemented in Week 1."""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field


class ObservationCreateRequest(BaseModel):
    """Planned request schema for source-observation persistence."""

    child_id: UUID
    observation_period_id: UUID
    text: str = Field(min_length=1, description="Original caregiver observation text.")
    context: str | None = None
    observed_at: datetime | None = None


class ObservationResponse(BaseModel):
    """Planned response schema; no persistence route exists yet."""

    id: UUID
    child_id: UUID
    observation_period_id: UUID | None
    text: str
    context: str | None
    observed_at: datetime
    created_at: datetime


class ObservationAnalysisRequest(BaseModel):
    """Planned NLP-analysis request schema; no NLP logic exists yet."""

    text: str = Field(min_length=1, description="Observation text to be analysed later.")


class BehaviouralEventResponse(BaseModel):
    """Planned structured-event contract, not a diagnostic output."""

    domain: str
    status: str
    negation_detected: bool
    evidence: str
    confidence: float = Field(ge=0, le=1)
