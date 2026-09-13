"""Week 3: implemented NLP-analysis route.

No persistence is required to run the NLP pipeline on submitted text, so
this endpoint works end-to-end today, unlike the observation-storage
routes in observations.py.
"""

from __future__ import annotations

from fastapi import APIRouter

from app.nlp.cue_extraction import extract_events
from app.schemas.observations import (
    BehaviouralEventResponse,
    ObservationAnalysisRequest,
    ObservationAnalysisResponse,
)

router = APIRouter(tags=["analysis"])


@router.post(
    "/analyze-observation",
    response_model=ObservationAnalysisResponse,
    summary="Extract structured behavioural events from free text",
)
def analyze_observation(request: ObservationAnalysisRequest) -> ObservationAnalysisResponse:
    events = extract_events(request.text)
    return ObservationAnalysisResponse(
        events=[
            BehaviouralEventResponse(
                domain=event.domain,
                status=event.status,
                negation_detected=event.negation_detected,
                evidence=event.evidence,
                confidence=event.confidence,
            )
            for event in events
        ]
    )
