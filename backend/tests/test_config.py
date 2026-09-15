"""Configuration loading and secret-hygiene guards.

backend/.env is the documented place for local overrides. It used to be
silently ignored (nothing loaded it), so these check both that the wiring
exists and that the file stays out of git.
"""

import importlib
import subprocess
from pathlib import Path

import pytest

import app.core.config as config_module

BACKEND_DIR = Path(__file__).resolve().parents[1]
REPO_ROOT = BACKEND_DIR.parent


def _git_check_ignore(path: Path) -> bool:
    """True if git ignores `path`. Skips the test if git is unavailable."""
    try:
        result = subprocess.run(
            ["git", "check-ignore", "-q", str(path)],
            cwd=REPO_ROOT,
            capture_output=True,
        )
    except (FileNotFoundError, OSError):  # pragma: no cover - environment dependent
        pytest.skip("git not available")
    return result.returncode == 0


def test_env_file_points_at_the_backend_directory() -> None:
    # Resolved from the module path, not the working directory, so it loads
    # regardless of where uvicorn is started from.
    assert config_module.ENV_FILE == BACKEND_DIR / ".env"


def test_settings_read_values_from_the_environment(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("APP_NAME", "Name From Environment")
    try:
        reloaded = importlib.reload(config_module)
        assert reloaded.settings.app_name == "Name From Environment"
    finally:
        monkeypatch.undo()
        importlib.reload(config_module)


def test_settings_fall_back_to_defaults() -> None:
    assert config_module.settings.app_name == "ASD NLP Screening Support API"
    assert config_module.settings.environment == "development"


def test_development_allows_any_localhost_port() -> None:
    # Flutter's web dev server picks a new port per run.
    assert config_module.settings.cors_origin_regex == config_module.DEV_LOCALHOST_ORIGIN_REGEX


def test_dotenv_file_is_git_ignored() -> None:
    # It holds local configuration and must never be committed.
    assert _git_check_ignore(BACKEND_DIR / ".env")


def test_dotenv_example_is_not_git_ignored() -> None:
    # The safe template is committed so others know what to set.
    assert not _git_check_ignore(BACKEND_DIR / ".env.example")


def test_dotenv_example_contains_no_real_secrets() -> None:
    contents = (BACKEND_DIR / ".env.example").read_text().lower()
    for marker in ("password=", "secret=", "api_key=", "service_role", "supabase_key"):
        assert marker not in contents, f".env.example must not carry a real {marker!r} value"
