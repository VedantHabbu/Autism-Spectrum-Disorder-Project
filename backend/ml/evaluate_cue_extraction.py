"""Self-check: how well does the Week 3 rule-based extractor recover the
domain/status labels used to generate the synthetic narratives?

This is a sanity check for the initial lexicon-based extractor, not the
robustness/error-analysis suite planned for Week 9. Requires
synthetic_narratives.csv (see ml/narratives/generate_narratives.py) and
backend/requirements-ml.txt (pandas) in addition to the live API's spaCy
dependency.

Usage (from the repo root, backend/.venv active):
    python3 backend/ml/evaluate_cue_extraction.py
"""

from __future__ import annotations

import sys
from pathlib import Path

import pandas as pd

REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT / "backend"))

from app.nlp.cue_extraction import extract_events  # noqa: E402

NARRATIVES_PATH = REPO_ROOT / "data" / "processed" / "synthetic_narratives.csv"
SAMPLE_SIZE = 300
RANDOM_STATE = 1


def main() -> dict:
    if not NARRATIVES_PATH.exists():
        raise FileNotFoundError(
            f"{NARRATIVES_PATH} not found. Run "
            "`python3 backend/ml/narratives/generate_narratives.py` first."
        )
    df = pd.read_csv(NARRATIVES_PATH)
    sample = df.sample(min(SAMPLE_SIZE, len(df)), random_state=RANDOM_STATE)

    domain_correct = 0
    domain_and_status_correct = 0
    no_event = 0
    for row in sample.itertuples():
        events = extract_events(row.text)
        matching_domain_events = [e for e in events if e.domain == row.domain]
        if matching_domain_events:
            domain_correct += 1
            if any(e.status == row.status for e in matching_domain_events):
                domain_and_status_correct += 1
        if not events:
            no_event += 1

    n = len(sample)
    result = {
        "n_sampled": n,
        "domain_recall": round(domain_correct / n, 4),
        "domain_and_status_accuracy": round(domain_and_status_correct / n, 4),
        "no_event_extracted_rate": round(no_event / n, 4),
    }
    return result


if __name__ == "__main__":
    print(main())
