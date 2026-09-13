import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/api_outcome.dart';
import '../../core/uuid.dart';
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
                        itemBuilder: (context, index) => Card(
                          child: ListTile(title: Text(items[index].toString())),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}
