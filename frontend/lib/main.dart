import 'package:flutter/material.dart';

import 'features/home/foundation_home_screen.dart';

void main() {
  runApp(const ScreeningSupportApp());
}

/// Week 1 application shell. Feature workflows are intentionally deferred.
class ScreeningSupportApp extends StatelessWidget {
  const ScreeningSupportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASD Screening Support',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: const FoundationHomeScreen(),
    );
  }
}
