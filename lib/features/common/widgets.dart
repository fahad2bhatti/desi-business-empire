import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/strings.dart';
import 'photos.dart';

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

/// The one accent-filled block on a screen: the next thing to do. Shows an
/// action button when it can be done now, otherwise progress towards it.
class FocusCard extends StatelessWidget {
  const FocusCard({
    super.key,
    required this.icon,
    required this.title,
    this.photoId,
    this.detail,
    this.progress,
    this.progressText,
    this.actionLabel,
    this.onAction,
    this.onTap,
  });

  final IconData icon;
  final String title;

  /// Photo shown instead of [icon] when this id has one.
  final String? photoId;
  final String? detail;

  /// 0..1 when the move cannot be afforded yet.
  final double? progress;
  final String? progressText;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final on = p.onAccent;
    return Material(
      color: p.accent,
      borderRadius: BorderRadius.circular(AppRadius.card),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  PhotoThumb(
                    id: photoId ?? '',
                    fallback: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: on.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(AppRadius.tile),
                      ),
                      child: Icon(icon, color: on, size: 24),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: context.text.titleLarge?.copyWith(color: on),
                        ),
                        if (detail != null)
                          Text(
                            detail!,
                            style: context.text.bodyMedium
                                ?.copyWith(color: on)
                                .numbers,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (actionLabel != null) ...[
                const SizedBox(height: AppSpacing.s16),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: on,
                    foregroundColor: p.accent,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  onPressed: onAction,
                  child: Text(actionLabel!, style: const TextStyle().numbers),
                ),
              ] else if (progress != null) ...[
                const SizedBox(height: AppSpacing.s16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress!.clamp(0.0, 1.0).toDouble(),
                    minHeight: 6,
                    color: on,
                    backgroundColor: on.withValues(alpha: 0.24),
                    semanticsLabel: title,
                  ),
                ),
                if (progressText != null) ...[
                  const SizedBox(height: AppSpacing.s8),
                  Text(
                    progressText!,
                    style: context.text.bodySmall?.copyWith(color: on).numbers,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
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

/// Asks before selling. True only when the player confirmed.
Future<bool> confirmSell(
  BuildContext context,
  String title,
  String body,
) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(S.keep),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.palette.danger,
              foregroundColor: context.palette.onDanger,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text(S.sell),
          ),
        ],
      ),
    ) ??
    false;
