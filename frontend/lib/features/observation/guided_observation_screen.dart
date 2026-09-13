import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/api_outcome.dart';
import '../../core/uuid.dart';
import '../../models/behavioural_domain.dart';
import '../../models/guided_observation_choice.dart';
import '../../widgets/disclaimer_banner.dart';
import '../../widgets/pending_banner.dart';

/// Guided observation: one structured prompt per behavioural-taxonomy
/// domain, plus an optional free-text note (docs/requirements.md). Each
/// submission calls the backend contract, which returns 503 until
/// Supabase is configured (docs/api-contract.md).
class GuidedObservationScreen extends StatefulWidget {
  const GuidedObservationScreen({super.key, this.apiClient});

  final ApiClient? apiClient;

  @override
  State<GuidedObservationScreen> createState() => _GuidedObservationScreenState();
}

class _GuidedObservationScreenState extends State<GuidedObservationScreen> {
  final _childIdController = TextEditingController(text: generateUuidV4());
  final _periodIdController = TextEditingController(text: generateUuidV4());
  late final ApiClient _apiClient = widget.apiClient ?? ApiClient();

  final Map<BehaviouralDomain, GuidedObservationChoice?> _choices = {
    for (final domain in BehaviouralDomain.values) domain: null,
  };
  final Map<BehaviouralDomain, TextEditingController> _noteControllers = {
    for (final domain in BehaviouralDomain.values) domain: TextEditingController(),
  };
  final Map<BehaviouralDomain, bool> _submitting = {
    for (final domain in BehaviouralDomain.values) domain: false,
  };
  final Map<BehaviouralDomain, ApiOutcome<Map<String, dynamic>>?> _outcomes = {
    for (final domain in BehaviouralDomain.values) domain: null,
  };

  @override
  void dispose() {
    _childIdController.dispose();
    _periodIdController.dispose();
    for (final controller in _noteControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitDomain(BehaviouralDomain domain) async {
    final choice = _choices[domain];
    if (choice == null) return;

    setState(() => _submitting[domain] = true);

    final outcome = await _apiClient.createGuidedObservation(
      childId: _childIdController.text.trim(),
      observationPeriodId: _periodIdController.text.trim(),
      domain: domain.apiValue,
      choice: choice.apiValue,
      note: _noteControllers[domain]!.text.trim(),
    );

    if (mounted) {
      setState(() {
        _submitting[domain] = false;
        _outcomes[domain] = outcome;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Guided observation')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const DisclaimerBanner(),
          const SizedBox(height: 12),
          TextField(
            controller: _childIdController,
            decoration: const InputDecoration(
              labelText: 'Child ID',
              helperText: 'Generated locally — child creation is pending Supabase.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _periodIdController,
            decoration: const InputDecoration(
              labelText: 'Observation period ID',
              helperText: 'Generated locally — period creation is pending Supabase.',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          for (final domain in BehaviouralDomain.values) _DomainPrompt(
            domain: domain,
            choice: _choices[domain],
            noteController: _noteControllers[domain]!,
            submitting: _submitting[domain] ?? false,
            outcome: _outcomes[domain],
            onChoiceChanged: (choice) => setState(() => _choices[domain] = choice),
            onSubmit: () => _submitDomain(domain),
          ),
        ],
      ),
    );
  }
}

class _DomainPrompt extends StatelessWidget {
  const _DomainPrompt({
    required this.domain,
    required this.choice,
    required this.noteController,
    required this.submitting,
    required this.outcome,
    required this.onChoiceChanged,
    required this.onSubmit,
  });

  final BehaviouralDomain domain;
  final GuidedObservationChoice? choice;
  final TextEditingController noteController;
  final bool submitting;
  final ApiOutcome<Map<String, dynamic>>? outcome;
  final ValueChanged<GuidedObservationChoice?> onChoiceChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(domain.label, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final option in GuidedObservationChoice.values)
                  ChoiceChip(
                    label: Text(option.label),
                    selected: choice == option,
                    onSelected: (_) => onChoiceChanged(option),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Optional note',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: (choice == null || submitting) ? null : onSubmit,
                child: submitting
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Submit'),
              ),
            ),
            if (outcome case ApiPending(:final message)) PendingBanner(message: message),
            if (outcome case ApiFailure(:final message)) ErrorBanner(message: message),
          ],
        ),
      ),
    );
  }
}
