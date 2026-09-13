import 'package:flutter/material.dart';

/// The project's safety-boundary disclaimer, shown on every screen that
/// touches observations or screening output (docs/requirements.md).
class DisclaimerBanner extends StatelessWidget {
  const DisclaimerBanner({
    super.key,
    this.text = 'This app supports screening and observation. It does not diagnose ASD.',
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: colors.tertiaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: colors.onTertiaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: colors.onTertiaryContainer, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
