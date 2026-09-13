/// Mirrors backend app/schemas/observations.py BehaviouralEventResponse.
/// Not a diagnostic output; confidence is a heuristic score, not a
/// clinical probability (see docs/nlp-pipeline.md).
class BehaviouralEvent {
  const BehaviouralEvent({
    required this.domain,
    required this.status,
    required this.negationDetected,
    required this.evidence,
    required this.confidence,
  });

  factory BehaviouralEvent.fromJson(Map<String, dynamic> json) {
    return BehaviouralEvent(
      domain: json['domain'] as String,
      status: json['status'] as String,
      negationDetected: json['negation_detected'] as bool,
      evidence: json['evidence'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  final String domain;
  final String status;
  final bool negationDetected;
  final String evidence;
  final double confidence;
}

class ObservationAnalysisResult {
  const ObservationAnalysisResult({required this.events, required this.disclaimer});

  factory ObservationAnalysisResult.fromJson(Map<String, dynamic> json) {
    return ObservationAnalysisResult(
      events: (json['events'] as List<dynamic>)
          .map((e) => BehaviouralEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      disclaimer: json['disclaimer'] as String,
    );
  }

  final List<BehaviouralEvent> events;
  final String disclaimer;
}
