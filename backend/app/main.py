"""FastAPI application entry point for the Week 1 foundation."""

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.v1 import api_v1_router
from app.api.routes.health import router as health_router
from app.core.config import settings

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description=(
        "Week 1 backend foundation for an ASD screening-support prototype. "
        "This service does not diagnose ASD."
    ),
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins or [],
    allow_credentials=False,
    allow_methods=["GET", "POST", "OPTIONS"],
    allow_headers=["Content-Type", "Authorization"],
)

app.include_router(health_router)
app.include_router(api_v1_router)

# Planned routes are documented in docs/api-contract.md. They are intentionally
# not registered until persistence and NLP implementation begin in later weeks.
