"""Caregiver auth routes. Contract implemented; storage pending Supabase Auth."""

from __future__ import annotations

from fastapi import APIRouter, Depends

from app.core.persistence import require_persistence
from app.schemas.auth import AuthResponse, LoginRequest, SignUpRequest

router = APIRouter(prefix="/auth", tags=["auth"])


@router.post(
    "/sign-up",
    response_model=AuthResponse,
    status_code=201,
    dependencies=[Depends(require_persistence)],
    summary="Register a caregiver (pending Supabase Auth integration)",
)
def sign_up(request: SignUpRequest) -> AuthResponse:  # pragma: no cover - unreachable until wired
    raise AssertionError("unreachable: require_persistence always raises")


@router.post(
    "/login",
    response_model=AuthResponse,
    dependencies=[Depends(require_persistence)],
    summary="Log in a caregiver (pending Supabase Auth integration)",
)
def login(request: LoginRequest) -> AuthResponse:  # pragma: no cover - unreachable until wired
    raise AssertionError("unreachable: require_persistence always raises")
