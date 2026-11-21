import 'package:flutter/material.dart';

import '../../app/theme.dart';

/// Warning strip with an optional action (save errors, restored backup).
class NoticeBanner extends StatelessWidget {
  const NoticeBanner({
    super.key,
    required this.text,
    this.action,
    this.onPressed,
  });

  final String text;
  final String? action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.s12,
      vertical: AppSpacing.s8,
    ),
    decoration: BoxDecoration(
      color: context.palette.danger.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(AppRadius.control),
    ),
    child: Row(
      children: [
        Icon(
          Icons.warning_amber_rounded,
          color: context.palette.danger,
          size: 20,
        ),
        const SizedBox(width: AppSpacing.s8),
        Expanded(child: Text(text, style: context.text.bodyMedium)),
        if (action != null)
          TextButton(onPressed: onPressed, child: Text(action!)),
      ],
    ),
  );
}

/// Section heading inside a screen.
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.trailing});

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.s12),
    child: Row(
      children: [
        Expanded(child: Text(text, style: context.text.titleMedium)),
        ?trailing,
      ],
    ),
  );
}

/// Rounded progress bar.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.color,
    this.label,
    this.height = 6,
  });

  final double value;
  final Color? color;
  final String? label;
  final double height;

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(height / 2),
    child: LinearProgressIndicator(
      value: value.clamp(0.0, 1.0).toDouble(),
      minHeight: height,
      color: color,
      semanticsLabel: label,
    ),
  );
}

/// Small stat: label above a bold value.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: p.surface,
        borderRadius: BorderRadius.circular(AppRadius.tile),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: color ?? p.inkMuted),
                const SizedBox(width: AppSpacing.s4),
              ],
              Expanded(
                child: Text(
                  label,
                  style: context.text.bodySmall?.copyWith(color: p.inkMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: context.text.titleMedium.numbers),
          ),
        ],
      ),
    );
  }
}
