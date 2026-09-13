"""Doctor-defined observation-period schemas (docs/database-schema.md).

Storage pending Supabase/PostgreSQL integration (app/core/persistence.py).
"""

from datetime import datetime
from uuid import UUID

from pydantic import BaseModel, Field, model_validator


class ObservationPeriodCreateRequest(BaseModel):
    child_id: UUID
    start_at: datetime
    end_at: datetime | None = None
    duration_days: int | None = Field(
        default=None,
        ge=1,
        le=90,
        description="Convenience alternative to end_at, e.g. 7 for a 7-day window.",
    )

    @model_validator(mode="after")
    def _check_end_after_start(self) -> "ObservationPeriodCreateRequest":
        if self.end_at is not None and self.end_at < self.start_at:
            raise ValueError("end_at must not be before start_at")
        return self


class ObservationPeriodResponse(BaseModel):
    id: UUID
    child_id: UUID
    start_at: datetime
    end_at: datetime | None
    created_at: datetime
    updated_at: datetime
