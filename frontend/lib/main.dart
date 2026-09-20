import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/api_client.dart';
import 'core/auth_service.dart';
import 'core/supabase_config.dart';
import 'features/auth/auth_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (!hasSupabaseConfig) {
    // Show the requirement rather than crashing on a null URL.
    runApp(const ScreeningSupportApp(configured: false));
    return;
  }

  await Supabase.initialize(
    url: supabaseUrl,
    // The modern name for the publishable key; `anonKey` is deprecated.
    publishableKey: supabasePublishableKey,
  );

  runApp(const ScreeningSupportApp());
}

/// Application shell.
class ScreeningSupportApp extends StatelessWidget {
  const ScreeningSupportApp({
    super.key,
    this.apiClient,
    this.authService,
    this.configured = true,
  });

  /// Injected in widget tests to avoid real network calls; defaults to a
  /// real [ApiClient] talking to [apiBaseUrl] at runtime.
  final ApiClient? apiClient;

  /// Injected in widget tests; defaults to Supabase Auth at runtime.
  final AuthService? authService;

  /// False only when the app was built without Supabase configuration.
  final bool configured;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASD Screening Support',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: configured
          ? AuthGate(
              authService: authService ?? SupabaseAuthService(),
              apiClient: apiClient,
            )
          : const SupabaseConfigMissingScreen(
              message: supabaseConfigMissingMessage,
            ),
    );
  }
}
