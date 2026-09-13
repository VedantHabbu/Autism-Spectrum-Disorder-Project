import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/api_outcome.dart';
import '../../widgets/pending_banner.dart';

enum _AuthMode { signUp, login }

/// Caregiver sign-up / log-in. Submits to the backend's auth contract,
/// which is fully validated but returns 503 until Supabase Auth is
/// configured (docs/api-contract.md) — this screen exists to demonstrate
/// the form, validation, and API wiring, not to authenticate anyone yet.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, this.apiClient});

  final ApiClient? apiClient;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final ApiClient _apiClient = widget.apiClient ?? ApiClient();

  _AuthMode _mode = _AuthMode.login;
  bool _submitting = false;
  ApiOutcome<Map<String, dynamic>>? _lastOutcome;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _lastOutcome = null;
    });

    final outcome = _mode == _AuthMode.signUp
        ? await _apiClient.signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          )
        : await _apiClient.login(
            email: _emailController.text.trim(),
            password: _passwordController.text,
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
      appBar: AppBar(title: const Text('Caregiver account')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<_AuthMode>(
                segments: const [
                  ButtonSegment(value: _AuthMode.login, label: Text('Log in')),
                  ButtonSegment(value: _AuthMode.signUp, label: Text('Sign up')),
                ],
                selected: {_mode},
                onSelectionChanged: (selection) => setState(() => _mode = selection.first),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || !value.contains('@')) {
                    return 'Enter a valid email address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
                validator: (value) {
                  if (value == null || value.length < 8) {
                    return 'Password must be at least 8 characters';
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
                    : Text(_mode == _AuthMode.signUp ? 'Sign up' : 'Log in'),
              ),
              const SizedBox(height: 16),
              if (_lastOutcome case ApiPending(:final message)) PendingBanner(message: message),
              if (_lastOutcome case ApiFailure(:final message)) ErrorBanner(message: message),
              if (_lastOutcome case ApiSuccess()) const ErrorBanner(message: 'Unexpected success from a pending endpoint.'),
            ],
          ),
        ),
      ),
    );
  }
}
