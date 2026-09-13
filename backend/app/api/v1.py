"""Versioned API router."""

from fastapi import APIRouter

from app.api.routes.analysis import router as analysis_router
from app.api.routes.auth import router as auth_router
from app.api.routes.children import router as children_router
from app.api.routes.guided_observations import router as guided_observations_router
from app.api.routes.observation_periods import router as observation_periods_router
from app.api.routes.observations import router as observations_router

api_v1_router = APIRouter(prefix="/api/v1")

# analyze-observation is fully implemented (no persistence needed). The
# remaining routers implement their request/response contract and
# validation but return 503 until Supabase/PostgreSQL is configured
# (app/core/persistence.py) — see docs/api-contract.md.
api_v1_router.include_router(analysis_router)
api_v1_router.include_router(auth_router)
api_v1_router.include_router(children_router)
api_v1_router.include_router(observation_periods_router)
api_v1_router.include_router(observations_router)
api_v1_router.include_router(guided_observations_router)
