"""Validate that synthetic narratives introduce no unsupported content.

Mechanically checks, for every generated row, that its `text` is a
rendering of one of the templates registered for its own (domain, status)
pair — and not a template belonging to any other status. This is the
concrete form of "validate that generated text does not introduce
symptoms absent from the source record" (docs/dataset-and-eda.md).
"""

from __future__ import annotations

import sys
from pathlib import Path

import pandas as pd

REPO_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO_ROOT / "backend"))

from ml.narratives.templates import CONTEXT_PHRASES, NARRATIVE_TEMPLATES  # noqa: E402

NARRATIVES_PATH = REPO_ROOT / "data" / "processed" / "synthetic_narratives.csv"


def _all_renderings(domain: str, status: str) -> set[str]:
    return {
        template.format(context=phrase)
        for template in NARRATIVE_TEMPLATES[domain][status]
        for phrase in CONTEXT_PHRASES.values()
    }


def validate(df: pd.DataFrame) -> list[str]:
    """Return a list of validation error messages (empty if all rows pass)."""

    errors: list[str] = []
    other_status = {"concern": "typical", "typical": "concern"}

    for row in df.itertuples(index=False):
        own_pool = _all_renderings(row.domain, row.status)
        if row.text not in own_pool:
            errors.append(
                f"case_no={row.case_no} domain={row.domain} status={row.status}: "
                "text does not match any registered template for its own status "
                f"({row.text!r})"
            )
            continue

        opposite_pool = _all_renderings(row.domain, other_status[row.status])
        if row.text in opposite_pool:
            errors.append(
                f"case_no={row.case_no} domain={row.domain} status={row.status}: "
                f"text also matches the opposite-status template pool ({row.text!r})"
            )

    return errors


def main() -> None:
    if not NARRATIVES_PATH.exists():
        raise FileNotFoundError(
            f"{NARRATIVES_PATH} not found. Run "
            "`python backend/ml/narratives/generate_narratives.py` first."
        )
    df = pd.read_csv(NARRATIVES_PATH)
    errors = validate(df)
    if errors:
        print(f"{len(errors)} validation error(s):")
        for error in errors[:20]:
            print(f"  - {error}")
        raise SystemExit(1)
    print(f"All {len(df)} synthetic narratives validated: each row's text traces "
          "back to a template registered for its own (domain, status).")


if __name__ == "__main__":
    main()
