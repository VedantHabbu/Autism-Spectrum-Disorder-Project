"""Implemented Week 1 health route."""

from fastapi import APIRouter

from app.core.config import settings
from app.schemas.health import HealthResponse

router = APIRouter(tags=["health"])


@router.get("/health", response_model=HealthResponse, summary="Check service health")
def health_check() -> HealthResponse:
    """Return a minimal availability signal without exposing configuration."""
    return HealthResponse(
        status="ok",
        service="asd-nlp-backend",
        version=settings.app_version,
    )
