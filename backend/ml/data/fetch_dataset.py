"""Download the public structured toddler ASD screening dataset.

Source: "Autism Screening for Toddlers" (Q-CHAT-10), 1,054 de-identified
records collected via the ASDTests mobile application and released for
research/ML use by Fadi Fayez Thabtah. Mirrored as a plain CSV (no auth
wall) at the GitHub location below; original distribution is the Kaggle
dataset "fabdelja/autism-screening-for-toddlers".

The raw CSV is intentionally not committed to git (see data/raw/ in
.gitignore) — re-run this script to reproduce it locally.
"""

from __future__ import annotations

import sys
import urllib.request
from pathlib import Path

DATASET_URL = (
    "https://raw.githubusercontent.com/whytheevanssoftware/"
    "Machine-Learning-Compendium/master/"
    "Toddler%20Autism%20dataset%20July%202018.csv"
)

REPO_ROOT = Path(__file__).resolve().parents[3]
OUTPUT_PATH = REPO_ROOT / "data" / "raw" / "toddler_autism_qchat10_2018.csv"

EXPECTED_MIN_ROWS = 1000  # sanity check; source has 1,054 data rows


def fetch(destination: Path = OUTPUT_PATH, url: str = DATASET_URL) -> Path:
    destination.parent.mkdir(parents=True, exist_ok=True)
    with urllib.request.urlopen(url, timeout=30) as response:
        payload = response.read()
    destination.write_bytes(payload)
    row_count = payload.count(b"\n")
    if row_count < EXPECTED_MIN_ROWS:
        raise ValueError(
            f"Downloaded file only has {row_count} lines; expected at least "
            f"{EXPECTED_MIN_ROWS}. The source may have changed or the "
            "download may be incomplete."
        )
    return destination


if __name__ == "__main__":
    path = fetch()
    print(f"Saved dataset to {path}")
    sys.exit(0)
