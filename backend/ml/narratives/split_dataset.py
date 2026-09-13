"""Week 3: finalise the synthetic-text dataset with a leakage-safe split.

Splits synthetic_narratives.csv into train/val/test using the same
Case_No-based partition as the structured baseline (ml/data/dataset_split),
so a given source record's narrative rows always fall in exactly one
split — no variant generated from one record can appear in two splits.
"""

from __future__ import annotations

import sys
from pathlib import Path

import pandas as pd

REPO_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO_ROOT / "backend"))

from ml.data.dataset_split import stratified_case_split  # noqa: E402

RAW_DATASET_PATH = REPO_ROOT / "data" / "raw" / "toddler_autism_qchat10_2018.csv"
NARRATIVES_PATH = REPO_ROOT / "data" / "processed" / "synthetic_narratives.csv"
PROCESSED_DIR = REPO_ROOT / "data" / "processed"


def main() -> dict[str, int]:
    if not RAW_DATASET_PATH.exists() or not NARRATIVES_PATH.exists():
        raise FileNotFoundError(
            "Run fetch_dataset.py and generate_narratives.py before splitting."
        )

    raw_df = pd.read_csv(RAW_DATASET_PATH)
    raw_df["label"] = (raw_df["Class/ASD Traits "].str.strip() == "Yes").astype(int)
    train_cases, val_cases, test_cases = stratified_case_split(raw_df, label_col="label")

    narratives = pd.read_csv(NARRATIVES_PATH)
    assert set(train_cases) & set(val_cases) == set()
    assert set(train_cases) & set(test_cases) == set()
    assert set(val_cases) & set(test_cases) == set()

    splits = {"train": train_cases, "val": val_cases, "test": test_cases}
    counts: dict[str, int] = {}
    for split_name, cases in splits.items():
        subset = narratives[narratives["case_no"].isin(cases)]
        subset.to_csv(PROCESSED_DIR / f"synthetic_narratives_{split_name}.csv", index=False)
        counts[split_name] = len(subset)

    # Leakage check: no case_no appears in more than one output split.
    case_to_splits: dict[int, set[str]] = {}
    for split_name, cases in splits.items():
        for case in cases:
            case_to_splits.setdefault(case, set()).add(split_name)
    leaked = {case: s for case, s in case_to_splits.items() if len(s) > 1}
    if leaked:
        raise AssertionError(f"Case_No leakage across splits detected: {leaked}")

    return counts


if __name__ == "__main__":
    result = main()
    print(f"Split synthetic narratives (no leakage) -> {result}")
