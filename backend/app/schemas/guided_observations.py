"""Guided-observation schemas (docs/requirements.md guided-observation feature).

Creating a guided observation writes two linked rows: an observations row
(child, period, context, timestamp, optional note, source_type='guided')
and a guided_observation_responses row holding the structured answer. The
response below exposes observation_id so a guided answer can always be
traced back to its source observation, per the plan's auditability rule.

Storage pending Supabase/PostgreSQL integration (app/core/persistence.py).
"""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field

from app.schemas.common import BehaviouralDomain, GuidedObservationChoice, ObservationContext


class GuidedObservationCreateRequest(BaseModel):
    child_id: UUID
    observation_period_id: UUID
    domain: BehaviouralDomain
    choice: GuidedObservationChoice
    note: str | None = Field(default=None, max_length=2000)
    context: ObservationContext | None = None
    observed_at: datetime | None = None


class GuidedObservationResponse(BaseModel):
    id: UUID
    observation_id: UUID
    child_id: UUID
    observation_period_id: UUID
    domain: BehaviouralDomain
    choice: GuidedObservationChoice
    note: str | None
    context: ObservationContext | None
    observed_at: datetime
    created_at: datetime
