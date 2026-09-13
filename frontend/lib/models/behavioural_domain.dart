/// Mirrors backend app/schemas/common.py BehaviouralDomain and
/// docs/behavioural-taxonomy.md.
enum BehaviouralDomain {
  responseToName,
  eyeContact,
  jointAttention,
  gestures,
  socialInteraction,
  communicationLanguage,
  playPretendPlay,
  repetitiveBehaviour,
  restrictedInterests,
  sensoryBehaviour;

  String get apiValue => switch (this) {
        BehaviouralDomain.responseToName => 'response_to_name',
        BehaviouralDomain.eyeContact => 'eye_contact',
        BehaviouralDomain.jointAttention => 'joint_attention',
        BehaviouralDomain.gestures => 'gestures',
        BehaviouralDomain.socialInteraction => 'social_interaction',
        BehaviouralDomain.communicationLanguage => 'communication_language',
        BehaviouralDomain.playPretendPlay => 'play_pretend_play',
        BehaviouralDomain.repetitiveBehaviour => 'repetitive_behaviour',
        BehaviouralDomain.restrictedInterests => 'restricted_interests',
        BehaviouralDomain.sensoryBehaviour => 'sensory_behaviour',
      };

  String get label => switch (this) {
        BehaviouralDomain.responseToName => 'Response to name',
        BehaviouralDomain.eyeContact => 'Eye contact',
        BehaviouralDomain.jointAttention => 'Joint attention / pointing to share interest',
        BehaviouralDomain.gestures => 'Gestures',
        BehaviouralDomain.socialInteraction => 'Social interaction / shared enjoyment',
        BehaviouralDomain.communicationLanguage => 'Communication / language',
        BehaviouralDomain.playPretendPlay => 'Play and pretend play',
        BehaviouralDomain.repetitiveBehaviour => 'Repetitive behaviours',
        BehaviouralDomain.restrictedInterests => 'Restricted interests',
        BehaviouralDomain.sensoryBehaviour => 'Sensory responses',
      };
}
