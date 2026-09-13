"""Caregiver authentication schemas.

Contract only — auth is planned to be delegated to Supabase Auth
(docs/database-schema.md); no password handling or session issuance is
implemented here. Routes using these schemas return 503 pending Supabase
integration (see app/core/persistence.py).
"""

from pydantic import BaseModel, EmailStr, Field


class SignUpRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)


class LoginRequest(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8, max_length=128)


class AuthResponse(BaseModel):
    caregiver_id: str
    access_token: str
    token_type: str = "bearer"
