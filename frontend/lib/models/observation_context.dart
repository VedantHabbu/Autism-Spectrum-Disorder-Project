/// Mirrors backend app/schemas/common.py ObservationContext.
enum ObservationContext {
  playing,
  eating,
  socialInteraction,
  outdoors,
  withFamily,
  withUnfamiliarPeople,
  other;

  /// Wire value expected by the FastAPI service.
  String get apiValue => switch (this) {
        ObservationContext.playing => 'playing',
        ObservationContext.eating => 'eating',
        ObservationContext.socialInteraction => 'social_interaction',
        ObservationContext.outdoors => 'outdoors',
        ObservationContext.withFamily => 'with_family',
        ObservationContext.withUnfamiliarPeople => 'with_unfamiliar_people',
        ObservationContext.other => 'other',
      };

  String get label => switch (this) {
        ObservationContext.playing => 'Playing',
        ObservationContext.eating => 'Eating',
        ObservationContext.socialInteraction => 'Social interaction',
        ObservationContext.outdoors => 'Outdoors',
        ObservationContext.withFamily => 'With family',
        ObservationContext.withUnfamiliarPeople => 'With unfamiliar people',
        ObservationContext.other => 'Other',
      };
}
