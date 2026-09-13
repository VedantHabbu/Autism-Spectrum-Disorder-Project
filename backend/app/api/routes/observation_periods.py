"""Observation-period routes. Contract implemented; storage pending Supabase."""

from __future__ import annotations

from fastapi import APIRouter, Depends

from app.core.persistence import require_persistence
from app.schemas.observation_periods import (
    ObservationPeriodCreateRequest,
    ObservationPeriodResponse,
)

router = APIRouter(prefix="/observation-periods", tags=["observation-periods"])


@router.post(
    "",
    response_model=ObservationPeriodResponse,
    status_code=201,
    dependencies=[Depends(require_persistence)],
    summary="Start a monitoring/observation period (pending Supabase integration)",
)
def create_observation_period(
    request: ObservationPeriodCreateRequest,
) -> ObservationPeriodResponse:  # pragma: no cover
    raise AssertionError("unreachable: require_persistence always raises")
