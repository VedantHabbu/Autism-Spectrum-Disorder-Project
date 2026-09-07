import 'package:flutter/material.dart';

/// Minimal Week 1 screen; it does not collect or analyse observations.
class FoundationHomeScreen extends StatelessWidget {
  const FoundationHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ASD Screening Support')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Week 1 foundation',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text(
                'This prototype supports observation and screening review. '
                'It does not diagnose autism spectrum disorder.',
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Authentication, child profiles, observations, NLP interpretation, '
                'and reports are planned for later stages.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
