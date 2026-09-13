"""Shared, leakage-safe train/val/test split by Case_No.

Used by both the structured baseline and the synthetic-narrative dataset so
that a given source record's Case_No falls in the same split everywhere —
required so that narrative variants generated from one record never leak
across splits (docs/dataset-and-eda.md, "Prevent leakage").
"""

from __future__ import annotations

import pandas as pd
from sklearn.model_selection import train_test_split

RANDOM_STATE = 42


def stratified_case_split(
    df: pd.DataFrame,
    label_col: str,
    case_col: str = "Case_No",
    test_size: float = 0.30,
    val_fraction_of_temp: float = 0.50,
    random_state: int = RANDOM_STATE,
) -> tuple[set[int], set[int], set[int]]:
    """Return (train_cases, val_cases, test_cases) as disjoint Case_No sets."""

    cases = df[[case_col, label_col]].drop_duplicates(subset=[case_col])
    train_cases, temp_cases = train_test_split(
        cases[case_col],
        test_size=test_size,
        random_state=random_state,
        stratify=cases[label_col],
    )
    temp_labels = cases.set_index(case_col).loc[temp_cases, label_col]
    val_cases, test_cases = train_test_split(
        temp_cases,
        test_size=val_fraction_of_temp,
        random_state=random_state,
        stratify=temp_labels,
    )
    return set(train_cases), set(val_cases), set(test_cases)
