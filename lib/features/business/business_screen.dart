import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/game_controller.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../domain/economy/economy_config.dart';
import '../../domain/economy/game_engine.dart';
import '../../domain/economy/game_state.dart';
import '../../widgets/wallet_chip.dart';
import '../common/run_command.dart';
import '../common/widgets.dart';
import '../onboarding/tutorial.dart';

const _buyQty = 10;

/// One business (stall, takeaway, restaurant): shared customer queue and
/// one card per item line.
class BusinessScreen extends ConsumerWidget {
  const BusinessScreen({super.key, required this.stageId});

  final String stageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider).requireValue;
    final engine = ref.read(gameControllerProvider.notifier).engine;
    final now = ref.read(clockProvider).nowUtc();
    final view = engine.observe(session.state, now);
    final def = engine.config.stage(stageId);
    final stage = view.stages[stageId];
    if (def == null || stage == null) {
      return const SafeArea(
        child: Center(child: Text('Ye karobar abhi band hai')),
      );
    }
    final blocked = session.saveFailed;
    final unlocked = engine.config.stages
        .where((s) => view.stages.containsKey(s.id))
        .toList();

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
                    const Text(
                      'Aap ka karobar',
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                    ),
                    Text(
                      def.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              WalletChip(paisa: view.cashPaisa),
            ],
          ),
          if (unlocked.length > 1) ...[
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final s in unlocked)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(s.name),
                        selected: s.id == stageId,
                        onSelected: (_) => context.go('/business/${s.id}'),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          TutorialCoach(starterId: engine.config.stages.first.id),
          if (session.restoredFromBackup) ...[
            const SizedBox(height: 12),
            const NoticeBanner(
              text: 'Pichli save kharab thi, backup se wapas laayi gayi.',
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(
                label: 'Saman (kul)',
                value: '${stage.totalStock} / ${engine.storage(view, def)}',
              ),
              const SizedBox(width: 8),
              _Stat(label: 'Customers', value: '${stage.queue}'),
              const SizedBox(width: 8),
              _Stat(label: 'Bika', value: '${stage.sold}'),
            ],
          ),
          const SizedBox(height: 12),
          for (final line in def.lines) ...[
            _LineCard(
              def: def,
              line: line,
              state: view,
              engine: engine,
              now: now,
              blocked: blocked,
              onBuy: () => runCommand(
                context,
                ref,
                (s, t) => engine.buyStock(s, stageId, line.id, _buyQty, t),
              ),
              onFry: () => runCommand(
                context,
                ref,
                (s, t) => engine.startBatch(s, stageId, line.id, t),
              ),
              onServe: () => runCommand(
                context,
                ref,
                (s, t) => engine.serve(s, stageId, line.id, t),
              ),
            ),
            const SizedBox(height: 10),
          ],
          TextButton(
            onPressed: blocked
                ? null
                : () => runCommand(context, ref, (s, t) => engine.doWork(s, t)),
            child: Text(
              'Paise kam hain? Mazdoori karo: + ${formatRs(engine.config.recoveryPayPaisa)}',
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _LinkButton(
                  icon: Icons.trending_up,
                  label: 'Upgrades',
                  onTap: () => context.go('/business/$stageId/upgrades'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _LinkButton(
                  icon: Icons.groups_outlined,
                  label: 'Staff',
                  onTap: () => context.go('/business/$stageId/staff'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Kiraya ${formatRs(def.rentPaisaPerMin * 60)} / ghanta (sirf jab dukan chal rahi ho)',
            style: const TextStyle(fontSize: 12, color: AppColors.muted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _LineCard extends StatelessWidget {
  const _LineCard({
    required this.def,
    required this.line,
    required this.state,
    required this.engine,
    required this.now,
    required this.blocked,
    required this.onBuy,
    required this.onFry,
    required this.onServe,
  });

  final StageDef def;
  final LineDef line;
  final GameState state;
  final GameEngine engine;
  final DateTime now;
  final bool blocked;
  final VoidCallback onBuy;
  final VoidCallback onFry;
  final VoidCallback onServe;

  @override
  Widget build(BuildContext context) {
    final ls = state.stages[def.id]!.lines[line.id]!;
    final stats = engine.lineStats(state, def, line);
    double progress = 0;
    var cooking = 'Khaali';
    final ends = ls.batchEndsAt;
    if (ends != null) {
      final leftMs = ends
          .difference(now)
          .inMilliseconds
          .clamp(0, stats.batchSeconds * 1000)
          .toInt();
      progress = 1 - leftMs / (stats.batchSeconds * 1000);
      cooking = '${ls.batchSize} ban rahe hain · ${(leftMs / 1000).ceil()} sec';
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    line.name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 17,
                    ),
                  ),
                ),
                Text(
                  formatRs(stats.pricePaisa),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              'Saman ${ls.stock} · Tayyar ${ls.ready} · laagat ${formatRs(line.costPaisa)}',
              style: const TextStyle(fontSize: 13, color: AppColors.muted),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 8,
                      color: AppColors.amber,
                      backgroundColor: AppColors.track,
                      semanticsLabel: '${line.name} tayyari',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  cooking,
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: blocked ? null : onBuy,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: Text(
                      'Saman +$_buyQty\n${formatRs(line.costPaisa * _buyQty)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: blocked ? null : onFry,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: Text(
                      'Banao\n${stats.batch} · ${stats.batchSeconds}s',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton(
                    onPressed: blocked ? null : onServe,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                    ),
                    child: const Text('Becho', style: TextStyle(fontSize: 15)),
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

class _LinkButton extends StatelessWidget {
  const _LinkButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

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
            Text(
              label,
              style: const TextStyle(
                color: AppColors.tealDark,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
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
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
