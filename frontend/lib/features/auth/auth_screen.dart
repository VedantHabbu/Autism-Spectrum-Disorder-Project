import 'package:flutter/material.dart';

import '../../core/api_outcome.dart';
import '../../core/auth_service.dart';
import '../../widgets/pending_banner.dart';

enum _AuthMode { signUp, login }

/// Caregiver sign-up / log-in against Supabase Auth.
///
/// On success the session is persisted by the Supabase SDK and AuthGate
/// swaps this screen for the app. The caregiver's row in `caregivers` is
/// created by a database trigger at signup, not from here.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key, required this.authService});

  final AuthService authService;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  _AuthMode _mode = _AuthMode.login;
  bool _submitting = false;
  ApiOutcome<String>? _lastOutcome;

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
        ? await widget.authService.signUp(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          )
        : await widget.authService.signIn(
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
            ],
          ),
        ),
      ),
    );
  }
}
