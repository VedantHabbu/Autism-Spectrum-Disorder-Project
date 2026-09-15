import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/api_config.dart';
import '../../core/api_outcome.dart';
import '../../core/uuid.dart';
import '../../models/behavioural_event.dart';
import '../../models/observation_context.dart';
import '../../widgets/disclaimer_banner.dart';
import '../../widgets/pending_banner.dart';

/// Free-text observation diary entry.
///
/// "Analyze" calls the fully-implemented POST /api/v1/analyze-observation
/// (no persistence required) and displays the extracted behavioural
/// events — this is the working end-to-end Flutter -> FastAPI -> NLP path.
/// "Save to history" calls the observation-storage endpoint, which is
/// contract-complete but pending Supabase (docs/api-contract.md).
class FreeTextObservationScreen extends StatefulWidget {
  const FreeTextObservationScreen({super.key, this.apiClient});

  final ApiClient? apiClient;

  @override
  State<FreeTextObservationScreen> createState() => _FreeTextObservationScreenState();
}

class _FreeTextObservationScreenState extends State<FreeTextObservationScreen> {
  final _textController = TextEditingController();
  final _childIdController = TextEditingController(text: generateUuidV4());
  final _periodIdController = TextEditingController(text: generateUuidV4());
  late final ApiClient _apiClient = widget.apiClient ?? ApiClient();

  ObservationContext? _context;
  DateTime? _observedAt;
  bool _analyzing = false;
  bool _saving = false;
  ApiOutcome<ObservationAnalysisResult>? _analysisOutcome;
  ApiOutcome<Map<String, dynamic>>? _saveOutcome;

  @override
  void dispose() {
    _textController.dispose();
    _childIdController.dispose();
    _periodIdController.dispose();
    super.dispose();
  }

  Future<void> _analyze() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _analyzing = true;
      _analysisOutcome = null;
      _saveOutcome = null;
      _observedAt = DateTime.now(); // automatic timestamp
    });

    final outcome = await _apiClient.analyzeObservation(text);

    if (mounted) {
      setState(() {
        _analyzing = false;
        _analysisOutcome = outcome;
      });
    }
  }

  Future<void> _save() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _saving = true;
      _saveOutcome = null;
    });

    final outcome = await _apiClient.createObservation(
      childId: _childIdController.text.trim(),
      observationPeriodId: _periodIdController.text.trim(),
      text: text,
      context: _context?.apiValue,
      observedAt: _observedAt,
    );

    if (mounted) {
      setState(() {
        _saving = false;
        _saveOutcome = outcome;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Free-text observation')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const DisclaimerBanner(),
          const SizedBox(height: 12),
          TextField(
            controller: _textController,
            maxLines: 4,
            // Matches ObservationAnalysisRequest's server-side cap, so the
            // limit is visible while typing instead of surfacing as a 422.
            maxLength: observationTextMaxLength,
            decoration: const InputDecoration(
              labelText: 'What did you observe?',
              hintText: "e.g. He doesn't look towards me when I call his name.",
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<ObservationContext>(
            initialValue: _context,
            decoration: const InputDecoration(
              labelText: 'Context (optional)',
              border: OutlineInputBorder(),
            ),
            items: ObservationContext.values
                .map((c) => DropdownMenuItem(value: c, child: Text(c.label)))
                .toList(),
            onChanged: (value) => setState(() => _context = value),
          ),
          if (_observedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Recorded at: $_observedAt',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _analyzing ? null : _analyze,
            icon: _analyzing
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.psychology_outlined),
            label: const Text('Analyze'),
          ),
          const SizedBox(height: 16),
          if (_analysisOutcome case ApiFailure(:final message)) ErrorBanner(message: message),
          if (_analysisOutcome case ApiPending(:final message)) PendingBanner(message: message),
          if (_analysisOutcome case ApiSuccess(data: final result)) _AnalysisResultView(result: result),
          if (_analysisOutcome != null) ...[
            const Divider(height: 32),
            Text('Save to observation history', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
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
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save_outlined),
              label: const Text('Save observation'),
            ),
            const SizedBox(height: 8),
            if (_saveOutcome case ApiPending(:final message)) PendingBanner(message: message),
            if (_saveOutcome case ApiFailure(:final message)) ErrorBanner(message: message),
          ],
        ],
      ),
    );
  }
}

class _AnalysisResultView extends StatelessWidget {
  const _AnalysisResultView({required this.result});

  final ObservationAnalysisResult result;

  @override
  Widget build(BuildContext context) {
    if (result.events.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Text('No behavioural domain was recognized in this text.'),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final event in result.events) _EventCard(event: event),
        const SizedBox(height: 8),
        Text(
          result.disclaimer,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final BehaviouralEvent event;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (event.status) {
      'concern' => (Colors.orange, 'Concern'),
      'typical' => (Colors.green, 'Typical'),
      'uncertain' => (Colors.blueGrey, 'Uncertain'),
      _ => (Colors.grey, event.status),
    };
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    event.domain.replaceAll('_', ' '),
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Chip(
                  label: Text(label),
                  backgroundColor: color.withValues(alpha: 0.15),
                  labelStyle: TextStyle(color: color),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('"${event.evidence}"', style: const TextStyle(fontStyle: FontStyle.italic)),
            const SizedBox(height: 4),
            Text(
              'Negation detected: ${event.negationDetected ? "yes" : "no"} · '
              'Confidence: ${(event.confidence * 100).round()}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
