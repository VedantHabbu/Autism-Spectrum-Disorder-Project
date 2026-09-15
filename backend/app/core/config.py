"""Environment-backed configuration with safe local defaults.

Values come from the process environment, falling back to backend/.env
(copy backend/.env.example to create it), falling back to the defaults
below. Real environment variables always win over .env, and .env is
gitignored — it is the place for local overrides, never for committed
secrets.
"""

from dataclasses import dataclass
from os import getenv
from pathlib import Path

from dotenv import load_dotenv

# backend/.env, resolved from this file rather than the working directory so
# it loads no matter where uvicorn is started from. Must run before the
# Settings class body below, whose defaults are read at import time.
ENV_FILE = Path(__file__).resolve().parents[2] / ".env"
load_dotenv(ENV_FILE)

DEV_LOCALHOST_ORIGIN_REGEX = r"^https?://(localhost|127\.0\.0\.1)(:\d+)?$"


def _cors_origins() -> list[str]:
    value = getenv("CORS_ORIGINS", "http://localhost,http://127.0.0.1")
    return [origin.strip() for origin in value.split(",") if origin.strip()]


@dataclass(frozen=True)
class Settings:
    app_name: str = getenv("APP_NAME", "ASD NLP Screening Support API")
    app_version: str = getenv("APP_VERSION", "0.1.0")
    environment: str = getenv("ENVIRONMENT", "development")
    cors_origins: list[str] | None = None
    # Flutter's web dev server (flutter run -d web-server/chrome) picks a
    # different localhost port per run, so a fixed CORS_ORIGINS list is
    # impractical in development. In development only, also allow any
    # localhost/127.0.0.1 port via allow_origin_regex; set CORS_ORIGIN_REGEX
    # explicitly (or ENVIRONMENT=production, which disables this default)
    # for any non-development deployment.
    cors_origin_regex: str | None = None

    def __post_init__(self) -> None:
        if self.cors_origins is None:
            object.__setattr__(self, "cors_origins", _cors_origins())
        if self.cors_origin_regex is None:
            env_value = getenv("CORS_ORIGIN_REGEX")
            if env_value is not None:
                object.__setattr__(self, "cors_origin_regex", env_value)
            elif self.environment == "development":
                object.__setattr__(self, "cors_origin_regex", DEV_LOCALHOST_ORIGIN_REGEX)


settings = Settings()
