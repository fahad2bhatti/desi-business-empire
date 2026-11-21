import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/game_controller.dart';
import '../../app/theme.dart';
import '../../core/money.dart';
import '../../widgets/wallet_chip.dart';
import '../common/run_command.dart';
import 'upgrade_preview.dart';

class UpgradesScreen extends ConsumerWidget {
  const UpgradesScreen({super.key, required this.stageId});

  final String stageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider).requireValue;
    final engine = ref.read(gameControllerProvider.notifier).engine;
    final s = session.state;
    final def = engine.config.stage(stageId);
    final upgrades = engine.config.upgrades.where((u) => u.stageId == stageId).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('Upgrades · ${def?.name ?? stageId}'),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 12), child: WalletChip(paisa: s.cashPaisa)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          const Text(
            'Khareedne se pehle dekh lein kya badlega. Sab qeematein virtual PKR mein.',
            style: TextStyle(color: AppColors.muted, fontSize: 14),
          ),
          const SizedBox(height: 12),
          for (final u in upgrades) ...[
            _UpgradeCard(
              name: u.name,
              preview: previewUpgrade(engine, s, u),
              cash: s.cashPaisa,
              blocked: session.saveFailed,
              onBuy: () => runCommand(
                context,
                ref,
                (state, now) => engine.buyUpgrade(state, u.id, now),
                successText: '${u.name} le liya',
              ),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({
    required this.name,
    required this.preview,
    required this.cash,
    required this.blocked,
    required this.onBuy,
  });

  final String name;
  final UpgradePreview preview;
  final int cash;
  final bool blocked;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final p = preview;
    final cost = p.nextCostPaisa;
    final short = cost != null && cost > cash;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(TextSpan(children: [
                    TextSpan(text: name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                    TextSpan(
                      text: '  L${p.level}/${p.maxLevel}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 13),
                    ),
                  ])),
                  const SizedBox(height: 4),
                  Text(p.label, style: const TextStyle(fontSize: 13, color: AppColors.muted)),
                  const SizedBox(height: 2),
                  Semantics(
                    label: p.isMaxed ? '${p.label}: ${p.before}' : '${p.label}: ${p.before} se ${p.after}',
                    excludeSemantics: true,
                    child: Row(
                      children: [
                        Text(p.before, style: const TextStyle(fontSize: 15)),
                        if (!p.isMaxed) ...[
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(Icons.arrow_forward, size: 16, color: AppColors.muted),
                          ),
                          Text(p.after!,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.green)),
                        ],
                      ],
                    ),
                  ),
                  if (short) ...[
                    const SizedBox(height: 4),
                    Text('${formatRs(cost - cash)} kam hain',
                        style: const TextStyle(fontSize: 13, color: AppColors.terra)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            if (p.isMaxed)
              const Chip(label: Text('Poora'))
            else
              FilledButton(
                onPressed: blocked || short ? null : onBuy,
                child: Text(formatRs(cost!)),
              ),
          ],
        ),
      ),
    );
  }
}
