import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/strings.dart';

/// Always-visible cash counter: gold cash that counts up as income arrives,
/// green income per second, and net worth.
class MoneyHeader extends StatelessWidget {
  const MoneyHeader({
    super.key,
    required this.empireName,
    required this.cashPaisa,
    required this.incomePaisaPerSec,
    required this.netWorthPaisa,
  });

  final String empireName;
  final int cashPaisa;
  final int incomePaisaPerSec;
  final int netWorthPaisa;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final income = formatShort(incomePaisaPerSec);
    return Semantics(
      label: S.walletLabel(formatRs(cashPaisa), formatRs(incomePaisaPerSec)),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s20,
          AppSpacing.s12,
          AppSpacing.s20,
          AppSpacing.s16,
        ),
        decoration: BoxDecoration(
          color: p.surface,
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(AppRadius.card),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    empireName,
                    style: context.text.titleSmall?.copyWith(color: p.inkMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${S.netWorth} ${formatShort(netWorthPaisa)}',
                  style: context.text.bodySmall
                      ?.copyWith(color: p.inkMuted)
                      .numbers,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.payments, color: p.gold, size: 28),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(end: cashPaisa.toDouble()),
                    duration: reduceMotion ? Duration.zero : AppMotion.counter,
                    curve: AppMotion.curve,
                    builder: (context, value, _) => FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        formatShort(value.round()),
                        style: context.text.displaySmall
                            ?.copyWith(color: p.gold)
                            .numbers,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s8,
                    vertical: AppSpacing.s4,
                  ),
                  decoration: BoxDecoration(
                    color: p.income.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(AppRadius.control),
                  ),
                  child: Text(
                    S.perSecond(income),
                    style: context.text.titleSmall
                        ?.copyWith(color: p.income)
                        .numbers,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
