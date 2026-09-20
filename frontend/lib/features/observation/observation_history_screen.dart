import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/api_outcome.dart';
import '../../core/uuid.dart';
import '../../models/observation.dart';
import '../../widgets/pending_banner.dart';

/// Chronological observation history for a child (docs/requirements.md).
/// Backed by the observation-storage contract, which returns 503 until
/// Supabase is configured — this screen shows that as a clear pending
/// state rather than an empty list or an error.
class ObservationHistoryScreen extends StatefulWidget {
  const ObservationHistoryScreen({super.key, this.apiClient});

  final ApiClient? apiClient;

  @override
  State<ObservationHistoryScreen> createState() => _ObservationHistoryScreenState();
}

class _ObservationHistoryScreenState extends State<ObservationHistoryScreen> {
  final _childIdController = TextEditingController(text: generateUuidV4());
  late final ApiClient _apiClient = widget.apiClient ?? ApiClient();

  bool _loading = false;
  ApiOutcome<List<dynamic>>? _outcome;

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _outcome = null;
    });

    final outcome = await _apiClient.listObservations(_childIdController.text.trim());

    if (mounted) {
      setState(() {
        _loading = false;
        _outcome = outcome;
      });
    }
  }

  @override
  void dispose() {
    _childIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Observation history')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _childIdController,
              decoration: const InputDecoration(
                labelText: 'Child ID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _loading ? null : _load,
              icon: _loading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search),
              label: const Text('Load history'),
            ),
            const SizedBox(height: 16),
            if (_outcome case ApiPending(:final message)) PendingBanner(message: message),
            if (_outcome case ApiFailure(:final message)) ErrorBanner(message: message),
            if (_outcome case ApiSuccess(data: final items))
              Expanded(
                child: items.isEmpty
                    ? const Center(child: Text('No observations recorded yet.'))
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) => _ObservationTile(
                          observation: Observation.fromJson(
                            items[index] as Map<String, dynamic>,
                          ),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

/// One observation rendered as structured fields (entry type, context,
/// timestamp, original text) rather than a raw map dump.
class _ObservationTile extends StatelessWidget {
  const _ObservationTile({required this.observation});

  final Observation observation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = observation.text;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(
                  label: Text(observation.sourceLabel),
                  visualDensity: VisualDensity.compact,
                ),
                const SizedBox(width: 8),
                if (observation.context != null)
                  Chip(
                    label: Text(observation.context!.label),
                    visualDensity: VisualDensity.compact,
                  ),
                const Spacer(),
                Text(
                  _formatTimestamp(observation.observedAt),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              (text == null || text.isEmpty)
                  ? 'No free-text note for this entry.'
                  : text,
              style: (text == null || text.isEmpty)
                  ? theme.textTheme.bodyMedium?.copyWith(fontStyle: FontStyle.italic)
                  : theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  static String _formatTimestamp(DateTime value) {
    final local = value.toLocal();
    String two(int n) => n.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
