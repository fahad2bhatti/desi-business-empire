import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/game_controller.dart';
import '../../app/theme.dart';
import '../../core/labels.dart';
import '../../core/money.dart';
import '../../domain/economy/economy_config.dart';
import '../../widgets/wallet_chip.dart';
import '../common/run_command.dart';
import '../common/widgets.dart';

/// Preview of the next business: what changes, what is still needed, and
/// an unlock that asks for confirmation first.
class ExpansionScreen extends ConsumerWidget {
  const ExpansionScreen({super.key, required this.stageId});

  final String stageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider).requireValue;
    final engine = ref.read(gameControllerProvider.notifier).engine;
    final s = session.state;
    final def = engine.config.stage(stageId);
    if (def == null) {
      return const Scaffold(body: Center(child: Text('Ye karobar nahi mila')));
    }
    final open = s.stages.containsKey(stageId);
    final unmet = engine.missingRequirements(s, stageId);
    final r = def.requirements;
    final ready = def.lines.isNotEmpty; // the hall is still being designed
    final short = def.unlockCostPaisa > s.cashPaisa;

    // Every requirement with have/need, met ones included.
    final rows = <({String text, int have, int need})>[
      for (final e in r.sold.entries)
        (
          text:
              '${engine.config.stage(e.key)?.name ?? e.key} par ${e.value} items becho',
          have: s.stages[e.key]?.sold ?? 0,
          need: e.value,
        ),
      for (final e in r.upgrades.entries)
        (
          text: '${engine.config.upgrade(e.key)?.name ?? e.key} L${e.value}',
          have: s.upgradeLevel(e.key),
          need: e.value,
        ),
      for (final st in r.staff.entries)
        for (final role in st.value.entries)
          (
            text:
                '${engine.config.stage(st.key)?.name ?? st.key} ka ${roleName(role.key)}',
            have: s.stages[st.key]?.staffCount(role.key) ?? 0,
            need: role.value,
          ),
    ];

    String buttonText() {
      if (open) return 'Pehle se khula hai';
      if (!ready) return 'Jald aa raha hai';
      if (unmet.isNotEmpty) return '${unmet.length} shart baqi';
      if (short) {
        return '${formatRs(def.unlockCostPaisa - s.cashPaisa)} kam hain';
      }
      return 'Kholo · ${formatRs(def.unlockCostPaisa)}';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(def.name),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: WalletChip(paisa: s.cashPaisa),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.tealLight,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Center(
              child: Icon(
                Icons.storefront,
                size: 48,
                color: AppColors.tealDark,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel('Kya milega'),
                  const SizedBox(height: 8),
                  if (!ready)
                    const Text(
                      'Is karobar ka design abhi ban raha hai (Phase 2).',
                    )
                  else ...[
                    for (final l in def.lines)
                      _Bullet(
                        '${l.name}: rate ${formatRs(l.pricePaisa)}, laagat ${formatRs(l.costPaisa)}',
                      ),
                    _Bullet(
                      'Customers: ${formatNumber(def.customersPerMin)} har minute',
                    ),
                    _Bullet('Saman ki jagah: ${def.storage}'),
                    _Bullet(
                      'Kiraya: ${formatRs(def.rentPaisaPerMin * 60)} / ghanta',
                    ),
                    const _Bullet(
                      'Purane karobar band nahi honge, sab saath chalenge.',
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (rows.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionLabel('Shartein'),
                    const SizedBox(height: 4),
                    for (final row in rows)
                      _RequirementRow(
                        text: row.text,
                        have: row.have,
                        need: row.need,
                      ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed:
                open ||
                    !ready ||
                    unmet.isNotEmpty ||
                    short ||
                    session.saveFailed
                ? null
                : () => _confirmAndUnlock(context, ref, def),
            child: Text(buttonText()),
          ),
          const SizedBox(height: 6),
          const Text(
            'Kholne se pehle tasdeeq poochi jayegi.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmAndUnlock(
    BuildContext context,
    WidgetRef ref,
    StageDef def,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${def.name} kholein?'),
        content: Text('${formatRs(def.unlockCostPaisa)} wallet se katenge.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Abhi nahi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Haan, kholo'),
          ),
        ],
      ),
    );
    if (!(ok ?? false) || !context.mounted) return;
    final engine = ref.read(gameControllerProvider.notifier).engine;
    final done = await runCommand(
      context,
      ref,
      (s, t) => engine.unlockStage(s, def.id, t),
      successText: '${def.name} khul gaya! Pehle saman lein.',
    );
    if (done && context.mounted) context.go('/business/${def.id}');
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('•  '),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    ),
  );
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({
    required this.text,
    required this.have,
    required this.need,
  });

  final String text;
  final int have;
  final int need;

  @override
  Widget build(BuildContext context) {
    final ok = have >= need;
    return Semantics(
      label: '$text: ${ok ? 'poori' : 'baqi'}, $have / $need',
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: ok ? AppColors.tealLight : AppColors.terraLight,
              child: Icon(
                ok ? Icons.check : Icons.close,
                size: 16,
                color: ok ? AppColors.green : AppColors.terra,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${have > need ? need : have} / $need',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
