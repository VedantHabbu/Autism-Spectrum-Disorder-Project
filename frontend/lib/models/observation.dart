import 'observation_context.dart';

/// Mirrors backend app/schemas/observations.py ObservationResponse.
///
/// `text` is nullable because a guided entry's free-text note is optional
/// (a free-text diary entry always has text) — see docs/api-contract.md.
class Observation {
  const Observation({
    required this.id,
    required this.childId,
    required this.observationPeriodId,
    required this.sourceType,
    required this.text,
    required this.context,
    required this.observedAt,
    required this.createdAt,
  });

  factory Observation.fromJson(Map<String, dynamic> json) {
    return Observation(
      id: json['id'] as String,
      childId: json['child_id'] as String,
      observationPeriodId: json['observation_period_id'] as String?,
      sourceType: json['source_type'] as String? ?? 'free_text',
      text: json['text'] as String?,
      context: _contextFromApi(json['context'] as String?),
      observedAt: DateTime.parse(json['observed_at'] as String),
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  final String id;
  final String childId;
  final String? observationPeriodId;
  final String sourceType;
  final String? text;
  final ObservationContext? context;
  final DateTime observedAt;
  final DateTime createdAt;

  bool get isGuided => sourceType == 'guided';

  /// Label for the entry type, for display.
  String get sourceLabel => isGuided ? 'Guided' : 'Free text';

  static ObservationContext? _contextFromApi(String? value) {
    if (value == null) return null;
    for (final candidate in ObservationContext.values) {
      if (candidate.apiValue == value) return candidate;
    }
    return null;
  }
}
