"""Request-schema validation, tested directly against the Pydantic models.

The persistence-backed routes always return 503 before body validation
runs (test_pending_persistence_routes.py), so this is where the
contract's own validation rules are actually exercised.
"""

from datetime import datetime
from uuid import uuid4

import pytest
from pydantic import ValidationError

from app.schemas.auth import LoginRequest, SignUpRequest
from app.schemas.children import ChildCreateRequest
from app.schemas.guided_observations import GuidedObservationCreateRequest
from app.schemas.observation_periods import ObservationPeriodCreateRequest
from app.schemas.observations import ObservationCreateRequest


def test_sign_up_rejects_short_password() -> None:
    with pytest.raises(ValidationError):
        SignUpRequest(email="a@example.com", password="short")


def test_sign_up_rejects_invalid_email() -> None:
    with pytest.raises(ValidationError):
        SignUpRequest(email="not-an-email", password="password123")


def test_sign_up_accepts_valid_input() -> None:
    request = SignUpRequest(email="a@example.com", password="password123")
    assert request.email == "a@example.com"


def test_login_rejects_short_password() -> None:
    with pytest.raises(ValidationError):
        LoginRequest(email="a@example.com", password="short")


def test_child_rejects_empty_display_name() -> None:
    with pytest.raises(ValidationError):
        ChildCreateRequest(display_name="")


def test_child_accepts_valid_input() -> None:
    request = ChildCreateRequest(display_name="Alex")
    assert request.display_name == "Alex"


def test_observation_period_rejects_end_before_start() -> None:
    with pytest.raises(ValidationError):
        ObservationPeriodCreateRequest(
            child_id=uuid4(),
            start_at=datetime(2026, 9, 8),
            end_at=datetime(2026, 9, 1),
        )


def test_observation_period_accepts_end_after_start() -> None:
    request = ObservationPeriodCreateRequest(
        child_id=uuid4(),
        start_at=datetime(2026, 9, 1),
        end_at=datetime(2026, 9, 8),
    )
    assert request.end_at is not None


def test_observation_rejects_empty_text() -> None:
    with pytest.raises(ValidationError):
        ObservationCreateRequest(
            child_id=uuid4(),
            observation_period_id=uuid4(),
            text="",
        )


def test_observation_rejects_invalid_context() -> None:
    with pytest.raises(ValidationError):
        ObservationCreateRequest(
            child_id=uuid4(),
            observation_period_id=uuid4(),
            text="He waved goodbye.",
            context="not-a-real-context",
        )


def test_guided_observation_rejects_invalid_domain() -> None:
    with pytest.raises(ValidationError):
        GuidedObservationCreateRequest(
            child_id=uuid4(),
            observation_period_id=uuid4(),
            domain="not-a-real-domain",
            choice="observed_normally",
        )


def test_guided_observation_rejects_invalid_choice() -> None:
    with pytest.raises(ValidationError):
        GuidedObservationCreateRequest(
            child_id=uuid4(),
            observation_period_id=uuid4(),
            domain="eye_contact",
            choice="not-a-real-choice",
        )


def test_guided_observation_accepts_valid_input() -> None:
    request = GuidedObservationCreateRequest(
        child_id=uuid4(),
        observation_period_id=uuid4(),
        domain="eye_contact",
        choice="observed_normally",
    )
    assert request.choice == "observed_normally"
