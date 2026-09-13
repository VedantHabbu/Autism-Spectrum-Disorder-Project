"""Child-profile routes. Contract implemented; storage pending Supabase."""

from __future__ import annotations

from uuid import UUID

from fastapi import APIRouter, Depends

from app.core.persistence import require_persistence
from app.schemas.children import ChildCreateRequest, ChildResponse

router = APIRouter(prefix="/children", tags=["children"])


@router.post(
    "",
    response_model=ChildResponse,
    status_code=201,
    dependencies=[Depends(require_persistence)],
    summary="Create a child profile (pending Supabase integration)",
)
def create_child(request: ChildCreateRequest) -> ChildResponse:  # pragma: no cover
    raise AssertionError("unreachable: require_persistence always raises")


@router.get(
    "/{child_id}",
    response_model=ChildResponse,
    dependencies=[Depends(require_persistence)],
    summary="Retrieve a child profile (pending Supabase integration)",
)
def get_child(child_id: UUID) -> ChildResponse:  # pragma: no cover
    raise AssertionError("unreachable: require_persistence always raises")
