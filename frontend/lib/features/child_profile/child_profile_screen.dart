import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/api_outcome.dart';
import '../../widgets/pending_banner.dart';

/// Create-child-profile form. Submits to the backend's child-profile
/// contract, which is fully validated but returns 503 until Supabase is
/// configured (docs/api-contract.md).
class ChildProfileScreen extends StatefulWidget {
  const ChildProfileScreen({super.key, this.apiClient});

  final ApiClient? apiClient;

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  late final ApiClient _apiClient = widget.apiClient ?? ApiClient();

  DateTime? _dateOfBirth;
  bool _submitting = false;
  ApiOutcome<Map<String, dynamic>>? _lastOutcome;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 6),
      lastDate: now,
      initialDate: DateTime(now.year - 2),
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _lastOutcome = null;
    });

    final outcome = await _apiClient.createChild(
      displayName: _nameController.text.trim(),
      dateOfBirthIso: _dateOfBirth != null
          ? '${_dateOfBirth!.year.toString().padLeft(4, '0')}-'
              '${_dateOfBirth!.month.toString().padLeft(2, '0')}-'
              '${_dateOfBirth!.day.toString().padLeft(2, '0')}'
          : null,
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
      appBar: AppBar(title: const Text('Child profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Display name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty) ? 'Enter a display name' : null,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDateOfBirth,
                icon: const Icon(Icons.cake_outlined),
                label: Text(
                  _dateOfBirth == null
                      ? 'Date of birth (optional)'
                      : 'Date of birth: ${_dateOfBirth!.toIso8601String().split('T').first}',
                ),
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
                    : const Text('Create child profile'),
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
