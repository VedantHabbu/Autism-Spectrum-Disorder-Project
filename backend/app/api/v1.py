"""Versioned API router reserved for future observation endpoints."""

from fastapi import APIRouter

api_v1_router = APIRouter(prefix="/api/v1")

# The observation and analysis contracts are documented but intentionally not
# registered until their persistence and NLP implementations begin.
