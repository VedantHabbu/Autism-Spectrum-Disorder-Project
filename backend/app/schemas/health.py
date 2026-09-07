"""Schemas for service health responses."""

from pydantic import BaseModel


class HealthResponse(BaseModel):
    """Public service availability response."""

    status: str
    service: str
    version: str
