# Requirements and Scope

## Project goal

Develop a longitudinal caregiver-observation and clinical decision-support prototype for ASD early risk screening in toddlers. The system will record timestamped free-text and guided observations, extract ASD-relevant behavioural cues, build a cumulative behavioural profile, estimate screening concern using machine learning, and produce separate explainable reports for caregivers and clinicians.

## Scope

Caregivers will record observations during a doctor-advised, configurable monitoring period (for example, seven days). The system is intended to retain the original observation, capture timestamp and optional context, derive structured behavioural events, and make longitudinal evidence reviewable.

## Safety boundary

- This is a screening and observation-support prototype, not a diagnostic system.
- The clinician remains the decision-maker. Outputs must not claim a confirmed diagnosis or a clinical probability of ASD.
- Original caregiver text must be retained with its NLP interpretation so source evidence can be reviewed.
- “Not observed” must remain distinct from “absent/reduced.”
- Student development must use de-identified or synthetic data unless required institutional/ethical approval and data-governance procedures exist.

## Major planned features

- Caregiver access and child-profile management.
- Doctor-defined observation periods.
- Spontaneous free-text diary and guided observations with optional notes/context.
- Timestamped longitudinal storage, observation timeline, and coverage indicator.
- NLP preprocessing, behavioural-domain extraction, status/negation detection, evidence phrases, and structured events.
- Longitudinal profile, temporal recurrence/context patterns, and adaptive observation prompts.
- Model-based screening-support estimate with explainability.
- Separate caregiver and clinician reports, dashboard, export/share, auditability, and robustness testing.

## Screening support versus diagnosis

The proposed model output is a documented, experimental screening-support signal. It is not a diagnosis, a substitute for clinical assessment, or a statement that a child has or does not have ASD. The planned reports must state this limitation and link conclusions to retained source observations.
