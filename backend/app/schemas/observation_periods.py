"""Doctor-defined observation-period schemas (docs/database-schema.md).

Storage pending Supabase/PostgreSQL integration (app/core/persistence.py).
"""

from datetime import datetime, timedelta
from uuid import UUID

from pydantic import BaseModel, Field, model_validator


class ObservationPeriodCreateRequest(BaseModel):
    """Doctor-defined monitoring window.

    The window may be given as an explicit `end_at`, as a `duration_days`
    count (the plan's "configurable monitoring window such as 7 days"), or
    as neither for an open-ended period. `duration_days` is resolved into
    `end_at` here, so every consumer reads one field rather than
    re-deriving the window.
    """

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
    def _resolve_window(self) -> "ObservationPeriodCreateRequest":
        if self.end_at is not None and self.end_at < self.start_at:
            raise ValueError("end_at must not be before start_at")

        if self.duration_days is None:
            return self

        derived_end_at = self.start_at + timedelta(days=self.duration_days)
        if self.end_at is None:
            self.end_at = derived_end_at
        elif self.end_at != derived_end_at:
            # Both supplied and disagreeing: silently preferring one would
            # discard what the caller asked for.
            raise ValueError(
                "end_at and duration_days disagree; supply one, or make them consistent "
                f"(duration_days={self.duration_days} implies end_at={derived_end_at.isoformat()})"
            )
        return self


class ObservationPeriodResponse(BaseModel):
    id: UUID
    child_id: UUID
    start_at: datetime
    end_at: datetime | None
    created_at: datetime
    updated_at: datetime
