import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/game_controller.dart';
import '../../app/theme.dart';
import '../../core/labels.dart';
import '../../core/money.dart';
import '../../domain/economy/economy_config.dart';
import '../../widgets/wallet_chip.dart';
import '../common/run_command.dart';
import '../common/widgets.dart';

class StaffScreen extends ConsumerWidget {
  const StaffScreen({super.key, required this.stageId});

  final String stageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(gameControllerProvider).requireValue;
    final engine = ref.read(gameControllerProvider.notifier).engine;
    final s = session.state;
    final def = engine.config.stage(stageId);
    final st = s.stages[stageId];

    return Scaffold(
      appBar: AppBar(
        title: Text('Staff · ${def?.name ?? stageId}'),
        actions: [
          Padding(padding: const EdgeInsets.only(right: 12), child: WalletChip(paisa: s.cashPaisa)),
        ],
      ),
      body: def == null || st == null
          ? const Center(child: Text('Ye karobar abhi band hai'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.amberLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 18, color: AppColors.amberInk),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Hire ki qeemat ek dafa. Tankhwah sirf tab katti hai jab dukan chal rahi ho.',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                for (final role in StaffRole.all)
                  if (def.staff[role] != null) ...[
                    _StaffCard(
                      role: role,
                      def: def.staff[role]!,
                      config: engine.config,
                      count: st.staffCount(role),
                      sold: st.sold,
                      cash: s.cashPaisa,
                      blocked: session.saveFailed,
                      onHire: () => runCommand(
                        context,
                        ref,
                        (state, now) => engine.hire(state, stageId, role, now),
                        successText: '${roleName(role)} rakh liya',
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({
    required this.role,
    required this.def,
    required this.config,
    required this.count,
    required this.sold,
    required this.cash,
    required this.blocked,
    required this.onHire,
  });

  final String role;
  final StaffDef def;
  final EconomyConfig config;
  final int count;
  final int sold;
  final int cash;
  final bool blocked;
  final VoidCallback onHire;

  @override
  Widget build(BuildContext context) {
    final full = count >= def.max;
    final needsSales = sold < def.requiresSold;
    final short = def.hirePaisa > cash;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(roleName(role),
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 17)),
                ),
                Text('$count / ${def.max} rakhe hain',
                    style: const TextStyle(fontSize: 12, color: AppColors.muted, fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            Text(roleDescription(role, def, config), style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 10),
            _row('Hire karne ki qeemat', formatRs(def.hirePaisa)),
            _row('Tankhwah', '${formatRs(def.wagePaisaPerMin * 60)} / ghanta'),
            if (def.requiresSold > 0 && count == 0) ...[
              const SizedBox(height: 10),
              Text('Shart: ${def.requiresSold} items becho',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ProgressLine(have: sold, need: def.requiresSold, label: 'Bikri'),
            ],
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: blocked || full || needsSales || short ? null : onHire,
                child: Text(
                  full
                      ? 'Poore rakh liye'
                      : needsSales
                          ? 'Shart baqi hai'
                          : short
                              ? '${formatRs(def.hirePaisa - cash)} kam hain'
                              : 'Rakho · ${formatRs(def.hirePaisa)}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(child: Text(k, style: const TextStyle(color: AppColors.muted, fontSize: 14))),
            Text(v, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      );
}
