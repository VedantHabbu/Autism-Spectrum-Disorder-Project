import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/auth_service.dart';
import '../home/home_screen.dart';
import 'auth_screen.dart';

/// Chooses between the sign-in screen and the app, and switches as soon as
/// the caregiver signs in or out.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, required this.authService, this.apiClient});

  final AuthService authService;

  /// Passed through to HomeScreen for the FastAPI health check.
  final ApiClient? apiClient;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final bool _signedIn = widget.authService.isSignedIn;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: widget.authService.signedInChanges,
      initialData: _signedIn,
      builder: (context, snapshot) {
        final signedIn = snapshot.data ?? false;
        if (!signedIn) {
          return AuthScreen(authService: widget.authService);
        }
        return HomeScreen(
          apiClient: widget.apiClient,
          authService: widget.authService,
        );
      },
    );
  }
}

/// Shown when the app was built without Supabase configuration, instead of
/// crashing on startup.
class SupabaseConfigMissingScreen extends StatelessWidget {
  const SupabaseConfigMissingScreen({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.settings_outlined, size: 40),
              const SizedBox(height: 12),
              const Text(
                'Configuration required',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }
}
