"""Shared "persistence not configured yet" dependency.

Per project decision: no SQLite/in-memory substitute is used for
Supabase-backed endpoints. Their request/response contracts (schemas,
validation, routing) are implemented; the dependency below is what makes
that explicit at request time rather than silently faking storage.
"""

from __future__ import annotations

from fastapi import HTTPException, status

PERSISTENCE_PENDING_DETAIL = (
    "Persistence is not configured yet: Supabase/PostgreSQL integration is "
    "pending (see docs/database-schema.md). This endpoint's request and "
    "response contract is implemented; only storage is pending."
)


def require_persistence() -> None:
    """FastAPI dependency for routes that need Supabase/PostgreSQL.

    Always raises until a real repository implementation is wired in.
    """
    raise HTTPException(
        status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
        detail=PERSISTENCE_PENDING_DETAIL,
    )
