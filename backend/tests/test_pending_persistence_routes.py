"""Routes that need Supabase/PostgreSQL are wired and clearly marked pending.

FastAPI evaluates the router-level `require_persistence` dependency before
body parsing, so these routes return 503 regardless of whether the body is
valid — see test_schema_validation.py for the request/response contract's
own validation rules, tested directly against the Pydantic models.
"""

from uuid import uuid4

import pytest
from fastapi.testclient import TestClient

from app.core.persistence import PERSISTENCE_PENDING_DETAIL
from app.main import app

client = TestClient(app)


@pytest.mark.parametrize(
    ("method", "path", "json_body"),
    [
        ("post", "/api/v1/auth/sign-up", {"email": "a@example.com", "password": "password123"}),
        ("post", "/api/v1/auth/login", {"email": "a@example.com", "password": "password123"}),
        ("post", "/api/v1/children", {"display_name": "Alex"}),
        ("get", f"/api/v1/children/{uuid4()}", None),
        (
            "post",
            "/api/v1/observation-periods",
            {"child_id": str(uuid4()), "start_at": "2026-09-01T00:00:00Z"},
        ),
        (
            "post",
            "/api/v1/observations",
            {
                "child_id": str(uuid4()),
                "observation_period_id": str(uuid4()),
                "text": "He waved goodbye.",
            },
        ),
        ("get", f"/api/v1/observations?child_id={uuid4()}", None),
        ("get", f"/api/v1/observations/{uuid4()}", None),
        (
            "post",
            "/api/v1/guided-observations",
            {
                "child_id": str(uuid4()),
                "observation_period_id": str(uuid4()),
                "domain": "eye_contact",
                "choice": "observed_normally",
            },
        ),
    ],
)
def test_persistence_backed_route_returns_503_pending(method, path, json_body) -> None:
    response = getattr(client, method)(path, json=json_body) if json_body is not None else getattr(client, method)(path)

    assert response.status_code == 503
    assert response.json() == {"detail": PERSISTENCE_PENDING_DETAIL}


def test_analyze_observation_is_not_pending() -> None:
    response = client.post("/api/v1/analyze-observation", json={"text": "He waved goodbye."})

    assert response.status_code == 200
