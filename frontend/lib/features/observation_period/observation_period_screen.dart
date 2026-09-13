import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/api_outcome.dart';
import '../../core/uuid.dart';
import '../../widgets/pending_banner.dart';

/// Start a doctor-defined observation period (configurable window, e.g. 7
/// days — docs/requirements.md). Submits to the backend contract, which
/// returns 503 until Supabase is configured (docs/api-contract.md).
///
/// child_id has no real source yet (child-profile creation is itself
/// pending), so this screen generates one locally and lets the caregiver
/// paste in a real one once child profiles are backed by Supabase.
class ObservationPeriodScreen extends StatefulWidget {
  const ObservationPeriodScreen({super.key, this.apiClient});

  final ApiClient? apiClient;

  @override
  State<ObservationPeriodScreen> createState() => _ObservationPeriodScreenState();
}

class _ObservationPeriodScreenState extends State<ObservationPeriodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _childIdController = TextEditingController(text: generateUuidV4());
  final _durationController = TextEditingController(text: '7');
  late final ApiClient _apiClient = widget.apiClient ?? ApiClient();

  DateTime _startAt = DateTime.now();
  bool _submitting = false;
  ApiOutcome<Map<String, dynamic>>? _lastOutcome;

  @override
  void dispose() {
    _childIdController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _lastOutcome = null;
    });

    final outcome = await _apiClient.createObservationPeriod(
      childId: _childIdController.text.trim(),
      startAt: _startAt,
      durationDays: int.tryParse(_durationController.text.trim()),
    );

    if (mounted) {
      setState(() {
        _submitting = false;
        _lastOutcome = outcome;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Observation period')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _childIdController,
                decoration: const InputDecoration(
                  labelText: 'Child ID',
                  helperText: 'Generated locally — child creation is pending Supabase.',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Enter a child ID' : null,
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Start date'),
                subtitle: Text(_startAt.toIso8601String().split('T').first),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 30)),
                    initialDate: _startAt,
                  );
                  if (picked != null) setState(() => _startAt = picked);
                },
              ),
              TextFormField(
                controller: _durationController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Monitoring window (days)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final days = int.tryParse(value?.trim() ?? '');
                  if (days == null || days < 1 || days > 90) {
                    return 'Enter a duration between 1 and 90 days';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Start observation period'),
              ),
              const SizedBox(height: 16),
              if (_lastOutcome case ApiPending(:final message)) PendingBanner(message: message),
              if (_lastOutcome case ApiFailure(:final message)) ErrorBanner(message: message),
            ],
          ),
        ),
      ),
    );
  }
}
