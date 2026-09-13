/// Mirrors backend app/schemas/common.py GuidedObservationChoice.
enum GuidedObservationChoice {
  observedNormally,
  observedWithConcern,
  notObserved,
  notSure;

  String get apiValue => switch (this) {
        GuidedObservationChoice.observedNormally => 'observed_normally',
        GuidedObservationChoice.observedWithConcern => 'observed_with_concern',
        GuidedObservationChoice.notObserved => 'not_observed',
        GuidedObservationChoice.notSure => 'not_sure',
      };

  String get label => switch (this) {
        GuidedObservationChoice.observedNormally => 'Observed normally',
        GuidedObservationChoice.observedWithConcern => 'Observed with concern',
        GuidedObservationChoice.notObserved => 'Not observed',
        GuidedObservationChoice.notSure => 'Not sure',
      };
}
