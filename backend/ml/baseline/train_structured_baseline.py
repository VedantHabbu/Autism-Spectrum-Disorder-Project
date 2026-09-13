"""Week 2: structured-data ML baseline, trained before any NLP model.

Trains Logistic Regression and SVM classifiers on the structured Q-CHAT-10
fields (A1-A10, age, sex, ethnicity, jaundice, family history) to predict
the dataset's screening-traits label. This is a documented, experimental
baseline used to validate the modelling pipeline (splitting, evaluation,
error analysis) before NLP-derived features are introduced in Week 4/6.

Output is not a diagnosis and the label ("Class/ASD Traits") reflects the
dataset's own screening-instrument scoring threshold, not a clinical
determination.

Usage (from the repo root, with backend/.venv active and
backend/requirements-ml.txt installed):
    python3 backend/ml/baseline/train_structured_baseline.py
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
import pandas as pd
from sklearn.compose import ColumnTransformer
from sklearn.linear_model import LogisticRegression
from sklearn.metrics import (
    accuracy_score,
    confusion_matrix,
    f1_score,
    precision_score,
    recall_score,
    roc_auc_score,
)
from sklearn.pipeline import Pipeline
from sklearn.preprocessing import OneHotEncoder, StandardScaler
from sklearn.svm import SVC

REPO_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO_ROOT / "backend"))

from ml.data.dataset_split import stratified_case_split  # noqa: E402
from ml.data.domain_mapping import STRUCTURED_FEATURE_COLUMNS, TARGET_COLUMN  # noqa: E402

RAW_DATASET_PATH = REPO_ROOT / "data" / "raw" / "toddler_autism_qchat10_2018.csv"
PROCESSED_DIR = REPO_ROOT / "data" / "processed"
METRICS_OUTPUT_PATH = PROCESSED_DIR / "structured_baseline_metrics.json"

NUMERIC_COLUMNS = [f"A{i}" for i in range(1, 11)] + ["Age_Mons"]
CATEGORICAL_COLUMNS = ["Sex", "Ethnicity", "Jaundice", "Family_mem_with_ASD"]

RANDOM_STATE = 42


def load_dataset() -> pd.DataFrame:
    if not RAW_DATASET_PATH.exists():
        raise FileNotFoundError(
            f"{RAW_DATASET_PATH} not found. Run "
            "`python backend/ml/data/fetch_dataset.py` first."
        )
    return pd.read_csv(RAW_DATASET_PATH)


def build_pipeline(model: str) -> Pipeline:
    preprocessor = ColumnTransformer(
        transformers=[
            ("numeric", StandardScaler(), NUMERIC_COLUMNS),
            (
                "categorical",
                OneHotEncoder(handle_unknown="ignore"),
                CATEGORICAL_COLUMNS,
            ),
        ]
    )
    if model == "logistic_regression":
        classifier = LogisticRegression(max_iter=1000, random_state=RANDOM_STATE)
    elif model == "svm":
        classifier = SVC(kernel="rbf", probability=True, random_state=RANDOM_STATE)
    else:
        raise ValueError(f"Unknown model: {model}")
    return Pipeline(steps=[("preprocess", preprocessor), ("classify", classifier)])


def evaluate(pipeline: Pipeline, X_test: pd.DataFrame, y_test: np.ndarray) -> dict:
    y_pred = pipeline.predict(X_test)
    y_proba = pipeline.predict_proba(X_test)[:, 1]
    cm = confusion_matrix(y_test, y_pred).tolist()
    return {
        "accuracy": accuracy_score(y_test, y_pred),
        "precision": precision_score(y_test, y_pred),
        "recall": recall_score(y_test, y_pred),
        "f1_score": f1_score(y_test, y_pred),
        "roc_auc": roc_auc_score(y_test, y_proba),
        "confusion_matrix": cm,
        "confusion_matrix_labels": ["No", "Yes"],
    }


def error_analysis(
    pipeline: Pipeline, X_test: pd.DataFrame, y_test: pd.Series, case_no_test: pd.Series
) -> dict:
    y_pred = pipeline.predict(X_test)
    false_positive_cases = case_no_test[(y_test == 0) & (y_pred == 1)].tolist()
    false_negative_cases = case_no_test[(y_test == 1) & (y_pred == 0)].tolist()
    return {
        "false_positive_case_numbers": false_positive_cases,
        "false_negative_case_numbers": false_negative_cases,
        "false_positive_count": len(false_positive_cases),
        "false_negative_count": len(false_negative_cases),
    }


def main() -> dict:
    df = load_dataset()
    df = df.copy()
    df["label"] = (df[TARGET_COLUMN].str.strip() == "Yes").astype(int)

    X = df[STRUCTURED_FEATURE_COLUMNS]
    y = df["label"]

    train_cases, val_cases, test_cases = stratified_case_split(df, label_col="label")
    train_mask = df["Case_No"].isin(train_cases)
    val_mask = df["Case_No"].isin(val_cases)
    test_mask = df["Case_No"].isin(test_cases)

    X_train, y_train = X[train_mask], y[train_mask]
    X_val, y_val = X[val_mask], y[val_mask]
    X_test, y_test, case_test = X[test_mask], y[test_mask], df.loc[test_mask, "Case_No"]

    results: dict = {
        "dataset": {
            "source": "toddler_autism_qchat10_2018.csv (see docs/dataset-and-eda.md)",
            "n_total": len(df),
            "n_train": len(X_train),
            "n_val": len(X_val),
            "n_test": len(X_test),
            "class_balance_overall": y.value_counts(normalize=True).round(3).to_dict(),
        },
        "models": {},
        "not_a_diagnosis": (
            "These metrics describe an experimental screening-support "
            "classifier trained on a public structured dataset. They are "
            "not a clinical accuracy claim and must not be presented as "
            "diagnostic performance."
        ),
    }

    for model_name in ("logistic_regression", "svm"):
        pipeline = build_pipeline(model_name)
        pipeline.fit(X_train, y_train)

        val_metrics = evaluate(pipeline, X_val, y_val)
        test_metrics = evaluate(pipeline, X_test, y_test)
        errors = error_analysis(pipeline, X_test, y_test, case_test)

        results["models"][model_name] = {
            "validation": val_metrics,
            "test": test_metrics,
            "error_analysis": errors,
        }

    PROCESSED_DIR.mkdir(parents=True, exist_ok=True)
    METRICS_OUTPUT_PATH.write_text(json.dumps(results, indent=2))
    return results


if __name__ == "__main__":
    output = main()
    print(json.dumps(output, indent=2))
