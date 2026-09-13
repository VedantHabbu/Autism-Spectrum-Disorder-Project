"""Child-profile schemas (docs/database-schema.md `children` table).

Storage pending Supabase/PostgreSQL integration (app/core/persistence.py).
"""

from datetime import date, datetime
from uuid import UUID

from pydantic import BaseModel, Field


class ChildCreateRequest(BaseModel):
    display_name: str = Field(min_length=1, max_length=200)
    date_of_birth: date | None = None


class ChildResponse(BaseModel):
    id: UUID
    caregiver_id: UUID
    display_name: str
    date_of_birth: date | None
    created_at: datetime
    updated_at: datetime
