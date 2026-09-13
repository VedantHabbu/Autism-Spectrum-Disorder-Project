import 'package:flutter/material.dart';

/// Shown whenever a call hits the backend's 503 "Supabase not configured
/// yet" response (ApiPending) — a clearly-labelled pending state, not an
/// error, per the project's "clearly mark anything that requires Supabase
/// as pending" requirement.
class PendingBanner extends StatelessWidget {
  const PendingBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.hourglass_top, color: colors.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: colors.onSecondaryContainer)),
          ),
        ],
      ),
    );
  }
}

/// Shown when a call fails for a reason other than "pending" (network
/// error, validation error, unexpected server error).
class ErrorBanner extends StatelessWidget {
  const ErrorBanner({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: colors.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: TextStyle(color: colors.onErrorContainer)),
          ),
        ],
      ),
    );
  }
}
