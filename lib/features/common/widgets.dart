import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Warning strip with an optional action (save errors, restored backup).
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({super.key, required this.text, this.action, this.onPressed});

  final String text;
  final String? action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.terraLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
            if (action != null) TextButton(onPressed: onPressed, child: Text(action!)),
          ],
        ),
      );
}

/// Small grey caps label above a card's content.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.muted,
          letterSpacing: 0.5,
        ),
      );
}

/// Rounded progress bar with a "have / need" caption.
class ProgressLine extends StatelessWidget {
  const ProgressLine({super.key, required this.have, required this.need, this.label});

  final int have;
  final int need;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final value = need <= 0 ? 1.0 : (have / need).clamp(0.0, 1.0).toDouble();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: value,
            minHeight: 8,
            color: AppColors.teal,
            backgroundColor: AppColors.track,
            semanticsLabel: label,
            semanticsValue: '$have / $need',
          ),
        ),
        const SizedBox(height: 4),
        Text('${have > need ? need : have} / $need',
            style: const TextStyle(fontSize: 12, color: AppColors.muted)),
      ],
    );
  }
}
