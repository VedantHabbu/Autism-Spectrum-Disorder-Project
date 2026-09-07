"""Environment-backed configuration with safe local defaults."""

from dataclasses import dataclass
from os import getenv


def _cors_origins() -> list[str]:
    value = getenv("CORS_ORIGINS", "http://localhost,http://127.0.0.1")
    return [origin.strip() for origin in value.split(",") if origin.strip()]


@dataclass(frozen=True)
class Settings:
    app_name: str = getenv("APP_NAME", "ASD NLP Screening Support API")
    app_version: str = getenv("APP_VERSION", "0.1.0")
    environment: str = getenv("ENVIRONMENT", "development")
    cors_origins: list[str] | None = None

    def __post_init__(self) -> None:
        if self.cors_origins is None:
            object.__setattr__(self, "cors_origins", _cors_origins())


settings = Settings()
