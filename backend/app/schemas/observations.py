"""Observation and NLP-analysis API schemas.

ObservationAnalysisRequest/Response back the implemented, persistence-free
POST /api/v1/analyze-observation endpoint (Week 3). The remaining
schemas here describe the observation-storage contract, which is
implemented as request/response shapes and validation only — the routes
that use them return 503 pending Supabase/PostgreSQL integration (see
app/core/persistence.py).
"""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.schemas.common import ObservationContext

NOT_A_DIAGNOSIS_DISCLAIMER = (
    "This output is an experimental NLP screening-support signal. It is "
    "not a diagnosis of ASD and does not replace clinical assessment."
)


class ObservationCreateRequest(BaseModel):
    """Request schema for source-observation persistence (storage pending)."""

    child_id: UUID
    observation_period_id: UUID
    text: str = Field(min_length=1, description="Original caregiver observation text.")
    context: ObservationContext | None = None
    observed_at: datetime | None = None


class ObservationResponse(BaseModel):
    """Response schema for a persisted observation (storage pending)."""

    id: UUID
    child_id: UUID
    observation_period_id: UUID | None
    text: str
    context: ObservationContext | None
    observed_at: datetime
    created_at: datetime


class ObservationAnalysisRequest(BaseModel):
    """Request schema for the implemented NLP-analysis endpoint."""

    text: str = Field(min_length=1, max_length=4000, description="Observation text to analyse.")


class BehaviouralEventResponse(BaseModel):
    """One structured behavioural event; not a diagnostic output."""

    domain: str
    status: str
    negation_detected: bool
    evidence: str
    confidence: float = Field(ge=0, le=1)


class ObservationAnalysisResponse(BaseModel):
    """Response schema for the implemented NLP-analysis endpoint."""

    events: list[BehaviouralEventResponse]
    disclaimer: str = NOT_A_DIAGNOSIS_DISCLAIMER
