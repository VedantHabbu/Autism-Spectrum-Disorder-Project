from fastapi.testclient import TestClient

from app.main import app


def test_health_check_returns_service_metadata() -> None:
    response = TestClient(app).get("/health")

    assert response.status_code == 200
    assert response.json() == {
        "status": "ok",
        "service": "asd-nlp-backend",
        "version": "0.1.0",
    }


def test_swagger_ui_is_available() -> None:
    response = TestClient(app).get("/docs")

    assert response.status_code == 200
    assert "Swagger UI" in response.text
