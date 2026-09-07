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

## Data safeguards

Use public, de-identified, or synthetic data only. Do not collect identifiable real patient data without required institutional/ethical approvals and data-governance procedures.
