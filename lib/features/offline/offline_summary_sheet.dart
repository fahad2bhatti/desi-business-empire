import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/game_controller.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../domain/economy/settlement.dart';

String _duration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes % 60;
  if (h == 0) return '$m min';
  return m == 0 ? '$h ghante' : '$h ghante $m min';
}

/// Shows what happened while the app was closed. The money is already in
/// the wallet: "Theek hai" only closes the sheet.
Future<void> showOfflineSummary(BuildContext context, Settlement s) =>
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _OfflineSummary(settlement: s),
    );

class _OfflineSummary extends ConsumerWidget {
  const _OfflineSummary({required this.settlement});

  final Settlement settlement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.read(gameControllerProvider.notifier).engine.config;
    final s = settlement;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Wapsi mubarak!',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              'Aap ${_duration(s.away)} door rahe.'
              '${s.capped ? ' Hisaab ki had ${_duration(s.credited)} hai.' : ''}',
              style: const TextStyle(color: AppColors.muted),
            ),
            for (final st in s.stages.values) ...[
              const SizedBox(height: 14),
              Text(
                config.stage(st.stageId)?.name ?? st.stageId,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              if (st.ranDryAfter != null)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.terraLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Saman ${_duration(st.ranDryAfter!)} mein khatam ho gaya, us ke baad dukan band rahi.',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              _Row('Bikri (${st.sold})', formatRs(st.revenuePaisa)),
              _Row('Tankhwah', formatRs(-st.wagesPaisa)),
              _Row('Kiraya', formatRs(-st.rentPaisa)),
              _Row('Saman istemal hua', '${st.stockUsed} (pehle khareeda tha)'),
            ],
            const Divider(height: 24),
            _Row('Wallet mein aaya', formatRs(s.netPaisa), strong: true),
            const SizedBox(height: 8),
            const Text(
              'Ye raqam pehle hi wallet mein jama ho chuki hai.',
              style: TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(gameControllerProvider.notifier).acknowledgeOffline();
              },
              child: const Text('Theek hai'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value, {this.strong = false});

  final String label;
  final String value;
  final bool strong;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: strong ? 20 : 15,
            fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
            color: strong ? AppColors.green : AppColors.text,
          ),
        ),
      ],
    ),
  );
}
