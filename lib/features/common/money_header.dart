import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/money.dart';
import '../../core/strings.dart';

/// Always-visible cash counter: cash in plain ink that counts up as income
/// arrives, green income per second, and net worth. No accent here: the
/// header is context, the focus lives on the screen below.
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
          border: Border(bottom: BorderSide(color: p.hairline)),
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
                        style: context.text.displaySmall.numbers,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                Text(
                  S.perSecond(income),
                  style: context.text.titleMedium
                      ?.copyWith(color: p.income)
                      .numbers,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
