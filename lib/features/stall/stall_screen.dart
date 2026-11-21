import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/game_controller.dart';
import '../../app/theme.dart';
import '../../core/failure_text.dart';
import '../../core/money.dart';
import '../../data/local/save_repository.dart';
import '../../domain/economy/command_result.dart';
import '../../domain/economy/game_state.dart';
import '../../widgets/wallet_chip.dart';
import '../offline/offline_summary_sheet.dart';

const _stageId = 'stall';
const _lineId = 'samosa';
const _buyQty = 10;

class StallScreen extends ConsumerWidget {
  const StallScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(gameControllerProvider.select((a) => a.value?.offline), (prev, next) {
      if (next == null || identical(prev, next)) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) showOfflineSummary(context, next);
      });
    });

    return ref.watch(gameControllerProvider).when(
          data: (session) => _StallBody(session: session),
          loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) => _LoadError(error: error),
        );
  }
}

class _StallBody extends ConsumerWidget {
  const _StallBody({required this.session});

  final GameSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(gameControllerProvider.notifier);
    final engine = controller.engine;
    final now = ref.read(clockProvider).nowUtc();
    final view = engine.observe(session.state, now);
    final def = engine.config.stage(_stageId)!;
    final line = def.line(_lineId)!;
    final stage = view.stages[_stageId]!;
    final ls = stage.lines[_lineId]!;
    final stats = engine.lineStats(view, def, line);
    final blocked = session.saveFailed;

    Future<void> act(CommandResult Function(GameState s, DateTime now) command) async {
      final messenger = ScaffoldMessenger.of(context);
      try {
        final failure = await controller.run(command);
        if (failure != null) {
          messenger
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(failureText(failure, now))));
        }
      } catch (_) {
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Save nahi ho saka. Upar "Dobara koshish" dabayein.')));
      }
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Aap ka karobar',
                          style: TextStyle(fontSize: 12, color: AppColors.muted)),
                      Text(def.name,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                WalletChip(paisa: view.cashPaisa),
              ],
            ),
            if (blocked) ...[
              const SizedBox(height: 12),
              _Banner(
                text: 'Save mein masla aaya. Jab tak theek na ho, khareed o farokht band hai.',
                action: 'Dobara koshish',
                onPressed: controller.retrySave,
              ),
            ],
            if (session.restoredFromBackup) ...[
              const SizedBox(height: 12),
              const _Banner(text: 'Pichli save kharab thi, backup se wapas laayi gayi.'),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                _Stat(label: 'Saman', value: '${ls.stock}'),
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
                        : () => act((s, t) => engine.buyStock(s, _stageId, _lineId, _buyQty, t)),
                    child: Text('Saman lo\n$_buyQty · ${formatRs(line.costPaisa * _buyQty)}',
                        textAlign: TextAlign.center),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    onPressed:
                        blocked ? null : () => act((s, t) => engine.startBatch(s, _stageId, _lineId, t)),
                    child: Text('Tal do\n${stats.batch} · ${stats.batchSeconds} sec',
                        textAlign: TextAlign.center),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
              onPressed: blocked ? null : () => act((s, t) => engine.serve(s, _stageId, _lineId, t)),
              icon: const Icon(Icons.back_hand_outlined),
              label: Text('Becho · + ${formatRs(stats.pricePaisa)}'),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: blocked ? null : () => act((s, t) => engine.doWork(s, t)),
              child: Text('Paise kam hain? Mazdoori karo: + ${formatRs(engine.config.recoveryPayPaisa)}'),
            ),
            const SizedBox(height: 8),
            Text(
              'Bika: ${stage.sold} · Kiraya ${formatRs(def.rentPaisaPerMin * 60)} / ghanta (sirf jab dukan chal rahi ho)',
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
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
                Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
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

class _Banner extends StatelessWidget {
  const _Banner({required this.text, this.action, this.onPressed});

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

class _LoadError extends ConsumerWidget {
  const _LoadError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final corrupt = error is SaveCorruptException;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                corrupt ? 'Save parhi nahi ja saki' : 'Game load nahi hua',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                corrupt
                    ? 'Aap ki save aur dono backups kharab hain. Naya game shuru karne se purani progress khatam ho jayegi.'
                    : '$error',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 24),
              if (corrupt)
                FilledButton(
                  onPressed: () => _confirmReset(context, ref),
                  child: const Text('Naya game shuru karein'),
                )
              else
                FilledButton(
                  onPressed: () => ref.invalidate(gameControllerProvider),
                  child: const Text('Dobara koshish'),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReset(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pakka?'),
        content: const Text('Saari progress mit jayegi. Ye wapas nahi hoga.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Nahi')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Haan, naya game')),
        ],
      ),
    );
    if (ok ?? false) await ref.read(gameControllerProvider.notifier).resetGame();
  }
}
