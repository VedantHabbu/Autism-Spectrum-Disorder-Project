"""Observation-storage and history routes. Contract implemented; storage
pending Supabase integration. See analysis.py for the implemented,
persistence-free NLP-analysis endpoint.
"""

from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends

from app.core.persistence import require_persistence
from app.schemas.observations import ObservationCreateRequest, ObservationResponse

router = APIRouter(prefix="/observations", tags=["observations"])


@router.post(
    "",
    response_model=ObservationResponse,
    status_code=201,
    dependencies=[Depends(require_persistence)],
    summary="Store a caregiver source observation (pending Supabase integration)",
)
def create_observation(request: ObservationCreateRequest) -> ObservationResponse:  # pragma: no cover
    raise AssertionError("unreachable: require_persistence always raises")


@router.get(
    "",
    response_model=list[ObservationResponse],
    dependencies=[Depends(require_persistence)],
    summary="List a child's observation history (pending Supabase integration)",
)
def list_observations(child_id: UUID) -> list[ObservationResponse]:  # pragma: no cover
    raise AssertionError("unreachable: require_persistence always raises")


@router.get(
    "/{observation_id}",
    response_model=ObservationResponse,
    dependencies=[Depends(require_persistence)],
    summary="Retrieve one observation (pending Supabase integration)",
)
def get_observation(observation_id: UUID) -> ObservationResponse:  # pragma: no cover
    raise AssertionError("unreachable: require_persistence always raises")
