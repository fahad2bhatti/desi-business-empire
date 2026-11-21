import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/game_controller.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../domain/economy/game_state.dart';
import '../../widgets/wallet_chip.dart';
import '../common/run_command.dart';
import '../common/widgets.dart';

const _stageId = 'stall';
const _lineId = 'samosa';
const _buyQty = 10;

class StallScreen extends ConsumerWidget {
  const StallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider).requireValue;
    final engine = ref.read(gameControllerProvider.notifier).engine;
    final now = ref.read(clockProvider).nowUtc();
    final view = engine.observe(session.state, now);
    final def = engine.config.stage(_stageId)!;
    final line = def.line(_lineId)!;
    final stage = view.stages[_stageId]!;
    final ls = stage.lines[_lineId]!;
    final stats = engine.lineStats(view, def, line);
    final blocked = session.saveFailed;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Aap ka karobar', style: TextStyle(fontSize: 12, color: AppColors.muted)),
                    Text(def.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
              WalletChip(paisa: view.cashPaisa),
            ],
          ),
          if (session.restoredFromBackup) ...[
            const SizedBox(height: 12),
            const NoticeBanner(text: 'Pichli save kharab thi, backup se wapas laayi gayi.'),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(label: 'Saman', value: '${ls.stock} / ${engine.storage(view, def)}'),
              const SizedBox(width: 8),
              _Stat(label: 'Tayyar', value: '${ls.ready}'),
              const SizedBox(width: 8),
              _Stat(label: 'Customers', value: '${stage.queue}'),
            ],
          ),
          const SizedBox(height: 12),
          _KadhaiCard(line: ls, batchSeconds: stats.batchSeconds, now: now),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: blocked
                      ? null
                      : () => runCommand(
                          context, ref, (s, t) => engine.buyStock(s, _stageId, _lineId, _buyQty, t)),
                  child: Text('Saman lo\n$_buyQty · ${formatRs(line.costPaisa * _buyQty)}',
                      textAlign: TextAlign.center),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: blocked
                      ? null
                      : () => runCommand(context, ref, (s, t) => engine.startBatch(s, _stageId, _lineId, t)),
                  child: Text('Tal do\n${stats.batch} · ${stats.batchSeconds} sec', textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            onPressed:
                blocked ? null : () => runCommand(context, ref, (s, t) => engine.serve(s, _stageId, _lineId, t)),
            icon: const Icon(Icons.back_hand_outlined),
            label: Text('Becho · + ${formatRs(stats.pricePaisa)}'),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: blocked ? null : () => runCommand(context, ref, (s, t) => engine.doWork(s, t)),
            child: Text('Paise kam hain? Mazdoori karo: + ${formatRs(engine.config.recoveryPayPaisa)}'),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _LinkButton(
                  icon: Icons.trending_up,
                  label: 'Upgrades',
                  onTap: () => context.go('/business/$_stageId/upgrades'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LinkButton(
                  icon: Icons.groups_outlined,
                  label: 'Staff',
                  onTap: () => context.go('/business/$_stageId/staff'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Bika: ${stage.sold} · Kiraya ${formatRs(def.rentPaisaPerMin * 60)} / ghanta (sirf jab dukan chal rahi ho)',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: AppColors.tealLight,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: SizedBox(
            height: 48,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: AppColors.tealDark),
                const SizedBox(width: 6),
                Text(label,
                    style: const TextStyle(color: AppColors.tealDark, fontWeight: FontWeight.w700, fontSize: 14)),
              ],
            ),
          ),
        ),
      );
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: AppColors.muted)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
        ),
      );
}

class _KadhaiCard extends StatelessWidget {
  const _KadhaiCard({required this.line, required this.batchSeconds, required this.now});

  final LineState line;
  final int batchSeconds;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    double progress = 0;
    var label = 'Khaali';
    final ends = line.batchEndsAt;
    if (ends != null) {
      final leftMs = ends.difference(now).inMilliseconds.clamp(0, batchSeconds * 1000).toInt();
      progress = 1 - leftMs / (batchSeconds * 1000);
      label = '${line.batchSize} tal rahe hain · ${(leftMs / 1000).ceil()} sec';
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_fire_department_outlined, color: AppColors.terra, size: 20),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text('Kadhai', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                ),
                Text(label, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                color: AppColors.amber,
                backgroundColor: AppColors.track,
                semanticsLabel: 'Kadhai',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
