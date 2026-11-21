import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/game_controller.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/strings.dart';
import '../../domain/economy/settlement.dart';

/// Shows what the empire earned while the app was closed. The money is
/// already in the cash: the button only closes the sheet.
Future<void> showOfflineSummary(BuildContext context, Settlement s) =>
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      builder: (_) => _OfflineSummary(settlement: s),
    );

class _OfflineSummary extends ConsumerWidget {
  const _OfflineSummary({required this.settlement});

  final Settlement settlement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = settlement;
    final p = context.palette;
    final muted = context.text.bodyMedium?.copyWith(color: p.inkMuted);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s24,
          AppSpacing.s24,
          AppSpacing.s24,
          AppSpacing.s16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(S.whileAway, style: context.text.titleLarge),
            const SizedBox(height: AppSpacing.s4),
            Text(
              '${S.awayFor(S.duration(s.away))}${s.capped ? ' ${S.creditedUpTo(S.duration(s.credited))}' : ''}',
              style: muted,
            ),
            const SizedBox(height: AppSpacing.s24),
            Text(S.earned, style: muted),
            Row(
              children: [
                Icon(Icons.payments, color: p.gold, size: 32),
                const SizedBox(width: AppSpacing.s8),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '+${formatShort(s.earnedPaisa)}',
                      style: context.text.displaySmall
                          ?.copyWith(color: p.gold)
                          .numbers,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(formatRs(s.earnedPaisa), style: muted.numbers),
            const SizedBox(height: AppSpacing.s12),
            Text(S.alreadyAdded, style: muted),
            const SizedBox(height: AppSpacing.s24),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: p.gold,
                foregroundColor: p.onGold,
              ),
              onPressed: () {
                Navigator.pop(context);
                ref.read(gameControllerProvider.notifier).acknowledgeOffline();
              },
              child: const Text(S.collect),
            ),
          ],
        ),
      ),
    );
  }
}
