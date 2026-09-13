# Dataset and EDA Foundation

## Intended workflow

1. Obtain an appropriate public structured ASD screening dataset for experimental work.
2. Perform initial exploratory data analysis and document dataset provenance, fields, missingness, class distribution, limitations, and permitted use.
3. Establish a structured-data baseline before attempting NLP-based prediction.
4. Generate caregiver-style narratives from structured records for NLP experimentation only.
5. Validate synthetic narratives to ensure they do not introduce symptoms absent from their source record.
6. Create separate training, validation, and test partitions.
7. Prevent leakage: variants generated from one original structured record must remain in the same split.

## Later evaluation plan

Later model work will evaluate accuracy, precision, recall/sensitivity, F1-score, ROC-AUC, and confusion matrices. It will include false-positive/false-negative error analysis and robustness checks for spelling errors, informal language, paraphrases, short entries, and negation. No dataset has been downloaded, no model has been trained, and no performance result is claimed in Week 1.

## Week 2 update: dataset selected and structured baseline trained

### Dataset

- **Source:** "Autism Screening for Toddlers", 1,054 de-identified records collected via the ASDTests mobile application and released for research/ML use (Thabtah et al.). Fetched from a public GitHub mirror of the Kaggle release (`fabdelja/autism-screening-for-toddlers`) by [`backend/ml/data/fetch_dataset.py`](../backend/ml/data/fetch_dataset.py); not committed to git (`data/raw/` is gitignored) — re-run the script to reproduce it.
- **Fields:** `A1`-`A10` (binary Q-CHAT-10 item scores, 1 = indicates more autistic traits), `Age_Mons`, `Qchat-10-Score` (sum of A1-A10), `Sex`, `Ethnicity`, `Jaundice`, `Family_mem_with_ASD`, `Who completed the test`, `Class/ASD Traits` (target label).
- **Missingness:** none — all 19 columns are fully populated across all 1,054 rows.
- **Duplicates:** none (`Case_No` and full-row duplicate checks both zero).
- **Class distribution:** `Yes` 728 (69.1%) / `No` 326 (30.9%) — moderately imbalanced; precision/recall/F1/ROC-AUC are tracked alongside accuracy for this reason.
- **Age range:** 12-36 months (mean 27.9, matches the toddler population this project targets).
- **Demographics:** `Sex` skews male (735 m / 319 f, consistent with reported ASD screening sex ratios in the literature); `Ethnicity` has 11 categories, largest being White European (334) and Asian (299).
- **Score consistency:** `Qchat-10-Score` equals `sum(A1..A10)` for all 1,054 rows (0 mismatches) — the structured fields are internally consistent.
- **Known limitation:** the `Class/ASD Traits` label agrees with the naive rule "`Qchat-10-Score >= 3`" for 90.9% of rows, i.e. the label is *closely related to* but not a pure function of the published Q-CHAT-10 referral threshold. This is very likely why the structured baseline below scores unusually high — the model is largely learning a threshold-like decision boundary already implicit in the ten input items, not a hard prediction problem. This must not be read as evidence that free-text/NLP-based screening will reach comparable accuracy; caregiver narratives (Week 3+) are a substantially noisier signal than ten pre-scored binary items.

### Q-CHAT-10 item to behavioural-taxonomy mapping

See [`backend/ml/data/domain_mapping.py`](../backend/ml/data/domain_mapping.py) for the full mapping with question wording and polarity. Summary:

| Item | Taxonomy domain |
| --- | --- |
| A1 | response_to_name |
| A2 | eye_contact |
| A3, A9 | gestures |
| A4, A6 | joint_attention |
| A5 | play_pretend_play |
| A7 | social_interaction |
| A8 | communication_language |
| A10 | sensory_behaviour |

`repetitive_behaviour` and `restricted_interests` have no corresponding Q-CHAT-10 item — the structured dataset carries no signal for them. This is a genuine coverage gap, not an oversight: it is the reason the guided-observation feature must actively prompt caregivers for those two domains rather than relying on a short screening form.

### Structured-data baseline (Week 2)

Trained per [`backend/ml/baseline/train_structured_baseline.py`](../backend/ml/baseline/train_structured_baseline.py): Logistic Regression and SVM (RBF kernel) on `A1`-`A10` + `Age_Mons` + one-hot `Sex`/`Ethnicity`/`Jaundice`/`Family_mem_with_ASD`, stratified 70/15/15 train/val/test split (`random_state=42`). Full metrics (including confusion matrices and false-positive/false-negative `Case_No` lists for error analysis) are written to `data/processed/structured_baseline_metrics.json` (gitignored, regenerate by running the script) each time it runs.

| Model | Split | Accuracy | Precision | Recall | F1 | ROC-AUC |
| --- | --- | --- | --- | --- | --- | --- |
| Logistic Regression | test | 1.000 | 1.000 | 1.000 | 1.000 | 1.000 |
| SVM (RBF) | test | 0.987 | 0.982 | 1.000 | 0.991 | 1.000 |

These numbers describe an experimental screening-support classifier on a public structured dataset, not a diagnostic accuracy claim, per the project's safety boundary. Given the near-ceiling scores and the label-threshold relationship noted above, this baseline's role is to validate the pipeline (loading, splitting, evaluation, error analysis) — not to represent the difficulty of the eventual NLP-based task.

### Synthetic caregiver narratives (begun Week 2, finalized Week 3)

Structured records are converted into caregiver-style free-text observations per domain using templated natural-language generation ([`backend/ml/narratives/templates.py`](../backend/ml/narratives/templates.py)), so that narrative polarity is generated directly from — and only from — that record's own item score. Pipeline:

1. `generate_narratives.py` — for each of the 1,054 records and each of the 8 mapped Q-CHAT-10 items, renders one caregiver-style sentence (paraphrase variant + optional observation-context phrase chosen deterministically, so re-runs are reproducible). Produces 1,054 × 8 = **10,540 synthetic narratives** (`data/processed/synthetic_narratives.csv`, gitignored). Status distribution: 5,494 `concern` / 5,046 `typical`.
2. `validate_narratives.py` — mechanically checks every row's text against the template pool registered for its own (domain, status) pair, and confirms it does **not** also match the opposite-status pool. All 10,540 rows pass. This is the concrete implementation of "validate that generated text does not introduce symptoms absent from the source record."
3. `split_dataset.py` — splits narratives into train/val/test (7,370 / 1,580 / 1,590 rows) using the **same Case_No partition** as the structured baseline, then asserts no `Case_No` appears in more than one split file. This prevents narrative variants generated from one record from leaking across splits.

Reproduce with (from the repo root, with `backend/.venv` active and `backend/requirements-ml.txt` installed):

```bash
python3 backend/ml/data/fetch_dataset.py
python3 backend/ml/narratives/generate_narratives.py
python3 backend/ml/narratives/validate_narratives.py
python3 backend/ml/narratives/split_dataset.py
```

## Data safeguards

Use public, de-identified, or synthetic data only. Do not collect identifiable real patient data without required institutional/ethical approvals and data-governance procedures.
