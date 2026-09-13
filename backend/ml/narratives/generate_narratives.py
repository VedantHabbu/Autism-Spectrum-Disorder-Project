"""Generate synthetic caregiver narratives from the structured dataset.

Week 2: begins narrative generation. Week 3: finalised alongside
validate_narratives.py and split_dataset.py (leakage-safe split).

Each output row is one synthetic free-text observation for one
(source record, domain) pair. The narrative's status is deterministically
derived from that record's own Q-CHAT-10 item score — see
ml/data/domain_mapping.py — so no generated text can assert a symptom the
source record does not support. validate_narratives.py checks this
mechanically rather than assuming it.
"""

from __future__ import annotations

import sys
from pathlib import Path

import pandas as pd

REPO_ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(REPO_ROOT / "backend"))

from ml.data.domain_mapping import QCHAT_ITEM_DOMAIN_MAP  # noqa: E402
from ml.narratives.templates import CONTEXT_PHRASES, NARRATIVE_TEMPLATES  # noqa: E402

RAW_DATASET_PATH = REPO_ROOT / "data" / "raw" / "toddler_autism_qchat10_2018.csv"
OUTPUT_PATH = REPO_ROOT / "data" / "processed" / "synthetic_narratives.csv"

CONTEXT_ROTATION = list(CONTEXT_PHRASES.keys())


def render(domain: str, status: str, variant_index: int, context: str | None) -> str:
    templates = NARRATIVE_TEMPLATES[domain][status]
    template = templates[variant_index % len(templates)]
    context_phrase = CONTEXT_PHRASES.get(context, "") if context else ""
    return template.format(context=context_phrase)


def generate(df: pd.DataFrame) -> pd.DataFrame:
    rows: list[dict] = []
    for _, record in df.iterrows():
        case_no = int(record["Case_No"])
        for item_index, mapping in enumerate(QCHAT_ITEM_DOMAIN_MAP):
            score = int(record[mapping.item])
            status = "concern" if score == mapping.concern_when else "typical"
            context = CONTEXT_ROTATION[(case_no + item_index) % len(CONTEXT_ROTATION)]
            # Rotate variant deterministically so the same (case, item) always
            # renders the same text on re-runs (reproducibility).
            variant_index = (case_no * 7 + item_index) % 3
            text = render(mapping.domain, status, variant_index, context)
            rows.append(
                {
                    "case_no": case_no,
                    "source_item": mapping.item,
                    "domain": mapping.domain,
                    "status": status,
                    "context": context,
                    "text": text,
                    "label_class_asd_traits": record["Class/ASD Traits "].strip(),
                }
            )
    return pd.DataFrame(rows)


def main() -> pd.DataFrame:
    if not RAW_DATASET_PATH.exists():
        raise FileNotFoundError(
            f"{RAW_DATASET_PATH} not found. Run "
            "`python backend/ml/data/fetch_dataset.py` first."
        )
    df = pd.read_csv(RAW_DATASET_PATH)
    narratives = generate(df)
    OUTPUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    narratives.to_csv(OUTPUT_PATH, index=False)
    return narratives


if __name__ == "__main__":
    result = main()
    print(f"Generated {len(result)} synthetic narratives -> {OUTPUT_PATH}")
    print(result["domain"].value_counts())
    print(result["status"].value_counts())
