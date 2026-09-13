import 'package:flutter/material.dart';

import 'core/api_client.dart';
import 'features/home/home_screen.dart';

void main() {
  runApp(const ScreeningSupportApp());
}

/// Application shell.
class ScreeningSupportApp extends StatelessWidget {
  const ScreeningSupportApp({super.key, this.apiClient});

  /// Injected in widget tests to avoid real network calls; defaults to a
  /// real [ApiClient] talking to [apiBaseUrl] at runtime.
  final ApiClient? apiClient;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASD Screening Support',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: HomeScreen(apiClient: apiClient),
    );
  }
}
