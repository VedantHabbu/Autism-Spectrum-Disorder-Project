"""Guided-observation routes. Contract implemented; storage pending Supabase."""

from __future__ import annotations

from fastapi import APIRouter, Depends

from app.core.persistence import require_persistence
from app.schemas.guided_observations import (
    GuidedObservationCreateRequest,
    GuidedObservationResponse,
)

router = APIRouter(prefix="/guided-observations", tags=["guided-observations"])


@router.post(
    "",
    response_model=GuidedObservationResponse,
    status_code=201,
    dependencies=[Depends(require_persistence)],
    summary="Record a guided-observation response (pending Supabase integration)",
)
def create_guided_observation(
    request: GuidedObservationCreateRequest,
) -> GuidedObservationResponse:  # pragma: no cover
    raise AssertionError("unreachable: require_persistence always raises")
