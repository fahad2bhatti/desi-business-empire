import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/money.dart';

/// Virtual PKR balance. Deliberately not styled like a bank balance.
class WalletChip extends StatelessWidget {
  const WalletChip({super.key, required this.paisa});

  final int paisa;

  @override
  Widget build(BuildContext context) {
    final amount = formatRs(paisa);
    return Semantics(
      label: 'Wallet: $amount virtual PKR',
      excludeSemantics: true,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44),
        padding: const EdgeInsets.fromLTRB(10, 4, 14, 4),
        decoration: BoxDecoration(
          color: AppColors.amberLight,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.payments_outlined, size: 18, color: AppColors.amberInk),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  amount,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.text,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                const Text(
                  'VIRTUAL PKR',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.amberInk),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
